import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserModel
// ─────────────────────────────────────────────────────────────────────────────
class UserModel {
  final String  uid;
  final String  email;
  final String  displayName;
  final String  photoUrl;
  final String  role;          // customer | captain | admin
  final String  phone;
  final DateTime createdAt;
  final bool    isActive;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    required this.phone,
    required this.createdAt,
    this.isActive = true,
  });

  bool get isCustomer => role == AppConstants.roleCustomer;
  bool get isCaptain  => role == AppConstants.roleCaptain;
  bool get isAdmin    => role == AppConstants.roleAdmin;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid:         doc.id,
      email:       d['email']        ?? '',
      displayName: d['display_name'] ?? '',
      photoUrl:    d['photo_url']    ?? '',
      role:        d['role']         ?? AppConstants.roleCustomer,
      phone:       d['phone']        ?? '',
      createdAt:   (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive:    d['is_active']    ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'email':        email,
    'display_name': displayName,
    'photo_url':    photoUrl,
    'role':         role,
    'phone':        phone,
    'created_at':   Timestamp.fromDate(createdAt),
    'is_active':    isActive,
  };

  UserModel copyWith({String? role, String? phone, bool? isActive}) => UserModel(
    uid:         uid,
    email:       email,
    displayName: displayName,
    photoUrl:    photoUrl,
    role:        role        ?? this.role,
    phone:       phone       ?? this.phone,
    createdAt:   createdAt,
    isActive:    isActive    ?? this.isActive,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CaptainModel — extended profile for approved captains
// ─────────────────────────────────────────────────────────────────────────────
class CaptainModel {
  final String  uid;
  final String  displayName;
  final String  phone;
  final String  vehicleType;    // car | moto | truck
  final String  vehicleModel;
  final String  licensePlate;
  final double  rating;
  final int     totalTrips;
  final bool    isOnline;
  final GeoPoint? currentLocation;
  final String  applicationStatus; // pending | approved | rejected

  // Document URLs stored in Firebase Storage
  final String docSelfieWithFrontId;
  final String docSelfieWithBackId;
  final String docDriverLicense;
  final String docCarRegistration;
  final String docCarWithPlate;

  const CaptainModel({
    required this.uid,
    required this.displayName,
    required this.phone,
    required this.vehicleType,
    required this.vehicleModel,
    required this.licensePlate,
    required this.docSelfieWithFrontId,
    required this.docSelfieWithBackId,
    required this.docDriverLicense,
    required this.docCarRegistration,
    required this.docCarWithPlate,
    this.rating            = 0.0,
    this.totalTrips        = 0,
    this.isOnline          = false,
    this.currentLocation,
    this.applicationStatus = AppConstants.appPending,
  });

  factory CaptainModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CaptainModel(
      uid:                   doc.id,
      displayName:           d['display_name']             ?? '',
      phone:                 d['phone']                    ?? '',
      vehicleType:           d['vehicle_type']             ?? AppConstants.vehicleCar,
      vehicleModel:          d['vehicle_model']            ?? '',
      licensePlate:          d['license_plate']            ?? '',
      rating:                (d['rating'] as num?)?.toDouble() ?? 0.0,
      totalTrips:            d['total_trips']              ?? 0,
      isOnline:              d['is_online']                ?? false,
      currentLocation:       d['current_location'] as GeoPoint?,
      applicationStatus:     d['application_status']       ?? AppConstants.appPending,
      docSelfieWithFrontId:  d['doc_selfie_front_id']      ?? '',
      docSelfieWithBackId:   d['doc_selfie_back_id']       ?? '',
      docDriverLicense:      d['doc_driver_license']       ?? '',
      docCarRegistration:    d['doc_car_registration']     ?? '',
      docCarWithPlate:       d['doc_car_with_plate']       ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'display_name':          displayName,
    'phone':                 phone,
    'vehicle_type':          vehicleType,
    'vehicle_model':         vehicleModel,
    'license_plate':         licensePlate,
    'rating':                rating,
    'total_trips':           totalTrips,
    'is_online':             isOnline,
    'current_location':      currentLocation,
    'application_status':    applicationStatus,
    'doc_selfie_front_id':   docSelfieWithFrontId,
    'doc_selfie_back_id':    docSelfieWithBackId,
    'doc_driver_license':    docDriverLicense,
    'doc_car_registration':  docCarRegistration,
    'doc_car_with_plate':    docCarWithPlate,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// OrderModel
// ─────────────────────────────────────────────────────────────────────────────
class OrderModel {
  final String    id;
  final String    customerId;
  final String    customerName;
  final String?   captainId;
  final String    vehicleType;
  final String    status;

  // Route
  final GeoPoint  pickupLocation;
  final GeoPoint  dropoffLocation;
  final String    pickupAddress;
  final String    dropoffAddress;
  final double    distanceKm;
  final int       durationMinutes;

  // Fare
  final double    totalFare;
  final double    driverEarnings;
  final double    platformFee;
  final double    fuelCost;

  // Timestamps
  final DateTime  createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  // Notes
  final String    notes;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.captainId,
    required this.vehicleType,
    required this.status,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.durationMinutes,
    required this.totalFare,
    required this.driverEarnings,
    required this.platformFee,
    required this.fuelCost,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.notes = '',
  });

  bool get isPending   => status == AppConstants.statusPending;
  bool get isAccepted  => status == AppConstants.statusAccepted;
  bool get isCompleted => status == AppConstants.statusCompleted;
  bool get isCancelled => status == AppConstants.statusCancelled;
  bool get isLive      => status == AppConstants.statusAccepted
                       || status == AppConstants.statusOnRoute
                       || status == AppConstants.statusArrived;

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id:              doc.id,
      customerId:      d['customer_id']     ?? '',
      customerName:    d['customer_name']   ?? '',
      captainId:       d['captain_id'],
      vehicleType:     d['vehicle_type']    ?? AppConstants.vehicleCar,
      status:          d['status']          ?? AppConstants.statusPending,
      pickupLocation:  d['pickup_location'] as GeoPoint,
      dropoffLocation: d['dropoff_location'] as GeoPoint,
      pickupAddress:   d['pickup_address']  ?? '',
      dropoffAddress:  d['dropoff_address'] ?? '',
      distanceKm:      (d['distance_km'] as num).toDouble(),
      durationMinutes: d['duration_minutes'] ?? 0,
      totalFare:       (d['total_fare'] as num).toDouble(),
      driverEarnings:  (d['driver_earnings'] as num).toDouble(),
      platformFee:     (d['platform_fee'] as num).toDouble(),
      fuelCost:        (d['fuel_cost'] as num).toDouble(),
      createdAt:       (d['created_at'] as Timestamp).toDate(),
      acceptedAt:      (d['accepted_at'] as Timestamp?)?.toDate(),
      completedAt:     (d['completed_at'] as Timestamp?)?.toDate(),
      notes:           d['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'customer_id':      customerId,
    'customer_name':    customerName,
    'captain_id':       captainId,
    'vehicle_type':     vehicleType,
    'status':           status,
    'pickup_location':  pickupLocation,
    'dropoff_location': dropoffLocation,
    'pickup_address':   pickupAddress,
    'dropoff_address':  dropoffAddress,
    'distance_km':      distanceKm,
    'duration_minutes': durationMinutes,
    'total_fare':       totalFare,
    'driver_earnings':  driverEarnings,
    'platform_fee':     platformFee,
    'fuel_cost':        fuelCost,
    'created_at':       Timestamp.fromDate(createdAt),
    'accepted_at':      acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
    'completed_at':     completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'notes':            notes,
  };

  OrderModel copyWith({String? status, String? captainId, DateTime? acceptedAt, DateTime? completedAt}) =>
    OrderModel(
      id: id, customerId: customerId, customerName: customerName,
      captainId:       captainId       ?? this.captainId,
      vehicleType:     vehicleType,
      status:          status          ?? this.status,
      pickupLocation:  pickupLocation, dropoffLocation: dropoffLocation,
      pickupAddress:   pickupAddress,  dropoffAddress:  dropoffAddress,
      distanceKm:      distanceKm,     durationMinutes: durationMinutes,
      totalFare:       totalFare,      driverEarnings:  driverEarnings,
      platformFee:     platformFee,    fuelCost:        fuelCost,
      createdAt:       createdAt,
      acceptedAt:      acceptedAt      ?? this.acceptedAt,
      completedAt:     completedAt     ?? this.completedAt,
      notes:           notes,
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatMessage
// ─────────────────────────────────────────────────────────────────────────────
class ChatMessage {
  final String   id;
  final String   senderId;
  final String   senderName;
  final String   senderRole;
  final String   text;
  final DateTime sentAt;
  final bool     isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.sentAt,
    this.isRead = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id:         doc.id,
      senderId:   d['sender_id']   ?? '',
      senderName: d['sender_name'] ?? '',
      senderRole: d['sender_role'] ?? '',
      text:       d['text']        ?? '',
      sentAt:     (d['sent_at'] as Timestamp).toDate(),
      isRead:     d['is_read']     ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'sender_id':   senderId,
    'sender_name': senderName,
    'sender_role': senderRole,
    'text':        text,
    'sent_at':     Timestamp.fromDate(sentAt),
    'is_read':     isRead,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatThread — a conversation between two parties
// ─────────────────────────────────────────────────────────────────────────────
class ChatThread {
  final String  id;
  final String  orderId;
  final String  customerId;
  final String  captainId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int     unreadCount;
  final bool    isSupport; // true = customer ↔ admin support thread

  const ChatThread({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.captainId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isSupport   = false,
  });

  factory ChatThread.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatThread(
      id:            doc.id,
      orderId:       d['order_id']       ?? '',
      customerId:    d['customer_id']    ?? '',
      captainId:     d['captain_id']     ?? '',
      lastMessage:   d['last_message'],
      lastMessageAt: (d['last_message_at'] as Timestamp?)?.toDate(),
      unreadCount:   d['unread_count']   ?? 0,
      isSupport:     d['is_support']     ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'order_id':        orderId,
    'customer_id':     customerId,
    'captain_id':      captainId,
    'last_message':    lastMessage,
    'last_message_at': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
    'unread_count':    unreadCount,
    'is_support':      isSupport,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSettings — stored in Firestore, controlled by admin
// ─────────────────────────────────────────────────────────────────────────────
class AppSettings {
  final double fuelPricePerLiter;
  final double driverProfitPct;
  final double platformFeePct;

  const AppSettings({
    this.fuelPricePerLiter = AppConstants.defaultFuelPriceEGP,
    this.driverProfitPct   = AppConstants.defaultDriverProfitPct,
    this.platformFeePct    = AppConstants.defaultPlatformFeePct,
  });

  factory AppSettings.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppSettings(
      fuelPricePerLiter: (d[AppConstants.settingFuelPrice]    as num?)?.toDouble() ?? AppConstants.defaultFuelPriceEGP,
      driverProfitPct:   (d[AppConstants.settingDriverProfit] as num?)?.toDouble() ?? AppConstants.defaultDriverProfitPct,
      platformFeePct:    (d[AppConstants.settingPlatformFee]  as num?)?.toDouble() ?? AppConstants.defaultPlatformFeePct,
    );
  }

  Map<String, dynamic> toMap() => {
    AppConstants.settingFuelPrice:    fuelPricePerLiter,
    AppConstants.settingDriverProfit: driverProfitPct,
    AppConstants.settingPlatformFee:  platformFeePct,
  };

  PricingEngine get engine => PricingEngine(
    fuelPricePerLiter: fuelPricePerLiter,
    driverProfitPct:   driverProfitPct,
    platformFeePct:    platformFeePct,
  );
}
