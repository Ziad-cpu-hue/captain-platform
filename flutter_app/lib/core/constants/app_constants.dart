/// ─────────────────────────────────────────────────────────────────────────────
/// App-wide constants for the CapTain platform
/// ─────────────────────────────────────────────────────────────────────────────

class AppConstants {
  // App info
  static const String appName    = 'CapTain';
  static const String appVersion = '1.0.0';

  // Firestore collections
  static const String colUsers      = 'users';
  static const String colCaptains   = 'captains';
  static const String colOrders     = 'orders';
  static const String colChats      = 'chats';
  static const String colMessages   = 'messages';
  static const String colSettings   = 'settings';
  static const String colReviews    = 'captain_applications';
  static const String colComplaints = 'complaints';

  // Storage paths
  static const String storageCaptainDocs = 'captain_documents';
  static const String storageProfilePics = 'profile_pictures';

  // Settings document keys
  static const String settingFuelPrice        = 'fuel_price_per_liter';
  static const String settingDriverProfit     = 'driver_profit_percentage';
  static const String settingPlatformFee      = 'platform_fee_percentage';

  // Default values (can be overridden from admin dashboard)
  static const double defaultFuelPriceEGP     = 22.25;  // EGP per liter, 92-octane
  static const double defaultDriverProfitPct  = 0.80;   // 80% profit on fuel cost
  static const double defaultPlatformFeePct   = 0.10;   // 10% of total transaction

  // Fuel consumption estimates (liters per 100 km)
  static const Map<String, double> fuelConsumption = {
    'car':   8.0,   // average private car
    'moto':  3.5,   // motorcycle
    'truck': 18.0,  // refrigerated truck
  };

  // Vehicle types
  static const String vehicleCar   = 'car';
  static const String vehicleMoto  = 'moto';
  static const String vehicleTruck = 'truck';

  // Order statuses
  static const String statusPending   = 'pending';
  static const String statusAccepted  = 'accepted';
  static const String statusOnRoute   = 'on_route';
  static const String statusArrived   = 'arrived';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Captain application statuses
  static const String appPending  = 'pending';
  static const String appApproved = 'approved';
  static const String appRejected = 'rejected';

  // User roles
  static const String roleCustomer = 'customer';
  static const String roleCaptain  = 'captain';
  static const String roleAdmin    = 'admin';

  // Map config
  static const double defaultMapZoom     = 15.0;
  static const double mapPolylineWidth   = 5.0;
  static const String googleMapsApiKey   = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const String directionsBaseUrl  =
      'https://maps.googleapis.com/maps/api/directions/json';

  // Pagination
  static const int pageSize = 20;

  // Timeouts
  static const Duration httpTimeout      = Duration(seconds: 30);
  static const Duration locationTimeout  = Duration(seconds: 10);
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Pricing Engine — all fare calculations live here
/// ─────────────────────────────────────────────────────────────────────────────
class PricingEngine {
  final double fuelPricePerLiter;
  final double driverProfitPct;
  final double platformFeePct;

  const PricingEngine({
    this.fuelPricePerLiter = AppConstants.defaultFuelPriceEGP,
    this.driverProfitPct   = AppConstants.defaultDriverProfitPct,
    this.platformFeePct    = AppConstants.defaultPlatformFeePct,
  });

  /// Calculate full fare breakdown for a trip.
  ///
  /// [distanceKm]  — actual route distance from Google Maps Directions API
  /// [vehicleType] — 'car' | 'moto' | 'truck'
  ///
  /// Returns a [FareBreakdown] with every component.
  FareBreakdown calculate({
    required double distanceKm,
    required String vehicleType,
  }) {
    final consumption = AppConstants.fuelConsumption[vehicleType] ?? 8.0;

    // Liters consumed for this trip
    final litersUsed = distanceKm * (consumption / 100);

    // Raw fuel cost in EGP
    final fuelCost = litersUsed * fuelPricePerLiter;

    // Driver profit = 80% on top of fuel cost
    final driverProfit = fuelCost * driverProfitPct;

    // Subtotal that driver receives
    final driverEarnings = fuelCost + driverProfit;

    // Platform fee = 10% of the total transaction
    // Total = driverEarnings + platformFee
    // platformFee = total * 0.10  →  total = driverEarnings / 0.90
    final total        = driverEarnings / (1 - platformFeePct);
    final platformFee  = total - driverEarnings;

    return FareBreakdown(
      vehicleType:    vehicleType,
      distanceKm:     distanceKm,
      litersUsed:     litersUsed,
      fuelCost:       fuelCost,
      driverProfit:   driverProfit,
      driverEarnings: driverEarnings,
      platformFee:    platformFee,
      totalFare:      total,
    );
  }

  /// Estimated duration string (rough heuristic; real value comes from Directions API)
  static String estimateDuration(double distanceKm, String vehicleType) {
    final avgSpeed = vehicleType == 'truck' ? 45.0 : vehicleType == 'moto' ? 50.0 : 40.0;
    final minutes  = (distanceKm / avgSpeed * 60).round();
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }
}

/// Value object for a fare calculation result.
class FareBreakdown {
  final String vehicleType;
  final double distanceKm;
  final double litersUsed;
  final double fuelCost;
  final double driverProfit;
  final double driverEarnings;
  final double platformFee;
  final double totalFare;

  const FareBreakdown({
    required this.vehicleType,
    required this.distanceKm,
    required this.litersUsed,
    required this.fuelCost,
    required this.driverProfit,
    required this.driverEarnings,
    required this.platformFee,
    required this.totalFare,
  });

  String get totalFareFormatted      => '${totalFare.toStringAsFixed(2)} EGP';
  String get driverEarningsFormatted => '${driverEarnings.toStringAsFixed(2)} EGP';
  String get platformFeeFormatted    => '${platformFee.toStringAsFixed(2)} EGP';
  String get fuelCostFormatted       => '${fuelCost.toStringAsFixed(2)} EGP';
  String get distanceFormatted       => '${distanceKm.toStringAsFixed(1)} km';

  Map<String, dynamic> toMap() => {
    'vehicle_type':     vehicleType,
    'distance_km':      distanceKm,
    'liters_used':      litersUsed,
    'fuel_cost':        fuelCost,
    'driver_profit':    driverProfit,
    'driver_earnings':  driverEarnings,
    'platform_fee':     platformFee,
    'total_fare':       totalFare,
  };
}
