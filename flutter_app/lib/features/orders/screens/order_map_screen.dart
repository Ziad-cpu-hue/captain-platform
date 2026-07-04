import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/maps_service.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/bottom_sheet_handle.dart';

// Simple state class for the ordering flow
class OrderDraft {
  final LatLng?  pickup;
  final LatLng?  dropoff;
  final String   pickupAddress;
  final String   dropoffAddress;
  final DirectionsResult? directions;

  const OrderDraft({
    this.pickup, this.dropoff,
    this.pickupAddress = '', this.dropoffAddress = '',
    this.directions,
  });

  bool get isComplete => pickup != null && dropoff != null;

  OrderDraft copyWith({
    LatLng? pickup, LatLng? dropoff,
    String? pickupAddress, String? dropoffAddress,
    DirectionsResult? directions,
  }) => OrderDraft(
    pickup:         pickup         ?? this.pickup,
    dropoff:        dropoff        ?? this.dropoff,
    pickupAddress:  pickupAddress  ?? this.pickupAddress,
    dropoffAddress: dropoffAddress ?? this.dropoffAddress,
    directions:     directions     ?? this.directions,
  );
}

final orderDraftProvider = StateProvider<OrderDraft>((_) => const OrderDraft());

class OrderMapScreen extends ConsumerStatefulWidget {
  final String vehicleType;
  const OrderMapScreen({super.key, required this.vehicleType});

  @override
  ConsumerState<OrderMapScreen> createState() => _OrderMapScreenState();
}

class _OrderMapScreenState extends ConsumerState<OrderMapScreen> {
  GoogleMapController? _mapController;
  bool _selectingDropoff = false;
  bool _loadingRoute     = false;
  Set<Marker>  _markers  = {};
  Set<Polyline> _polylines = {};

  static const LatLng _cairoCentre = LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToUserLocation());
  }

  Future<void> _goToUserLocation() async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) await Geolocator.requestPermission();
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: AppConstants.locationTimeout,
      );
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(pos.latitude, pos.longitude), 15));
    } catch (_) {}
  }

  void _onMapTap(LatLng point) async {
    final mapsService = ref.read(mapsServiceProvider);
    final address = await mapsService.reverseGeocode(point);
    final draft = ref.read(orderDraftProvider);

    if (!_selectingDropoff) {
      ref.read(orderDraftProvider.notifier).state =
        draft.copyWith(pickup: point, pickupAddress: address);
      setState(() {
        _markers = {
          Marker(markerId: const MarkerId('pickup'), position: point,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: 'Pickup', snippet: address)),
          if (draft.dropoff != null)
            Marker(markerId: const MarkerId('dropoff'), position: draft.dropoff!,
              infoWindow: InfoWindow(title: 'Dropoff', snippet: draft.dropoffAddress)),
        };
        _selectingDropoff = true;
      });
    } else {
      ref.read(orderDraftProvider.notifier).state =
        draft.copyWith(dropoff: point, dropoffAddress: address);
      setState(() {
        _markers = {
          Marker(markerId: const MarkerId('pickup'), position: draft.pickup!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: 'Pickup', snippet: draft.pickupAddress)),
          Marker(markerId: const MarkerId('dropoff'), position: point,
            infoWindow: InfoWindow(title: 'Dropoff', snippet: address)),
        };
      });
      await _fetchRoute(draft.pickup!, point);
    }
  }

  Future<void> _fetchRoute(LatLng origin, LatLng dest) async {
    setState(() => _loadingRoute = true);
    try {
      final result = await ref.read(mapsServiceProvider).getDirections(
        origin: origin, destination: dest);
      ref.read(orderDraftProvider.notifier).state =
        ref.read(orderDraftProvider).copyWith(directions: result);
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: result.polylinePoints,
            color: AppTheme.primary,
            width: 5,
          ),
        };
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
        _boundsFromPoints([origin, dest, ...result.polylinePoints]),
        80,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not calculate route')));
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  LatLngBounds _boundsFromPoints(List<LatLng> points) {
    double minLat = points[0].latitude, maxLat = points[0].latitude;
    double minLng = points[0].longitude, maxLng = points[0].longitude;
    for (final p in points) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  String get _vehicleLabel => switch (widget.vehicleType) {
    AppConstants.vehicleCar   => 'Private Car',
    AppConstants.vehicleMoto  => 'Motorcycle',
    AppConstants.vehicleTruck => 'Cargo Truck',
    _                         => 'Vehicle',
  };

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(orderDraftProvider);

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _cairoCentre, zoom: 12),
            onMapCreated: (c) => _mapController = c,
            onTap: _onMapTap,
            markers:  _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // ── Top Bar ──────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.border, width: 0.5),
                      ),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border, width: 0.5),
                      ),
                      child: Text(
                        _selectingDropoff
                          ? 'Tap map to set drop-off point'
                          : 'Tap map to set pick-up point',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (_loadingRoute)
            const Center(child: CircularProgressIndicator(color: AppTheme.primary)),

          // ── Bottom Sheet ──────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BottomSheetHandle(),
                  const SizedBox(height: 14),
                  Text(_vehicleLabel,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),

                  _LocationRow(
                    dot: AppTheme.primary,
                    label: 'Pick-up',
                    address: draft.pickupAddress.isEmpty ? 'Tap the map' : draft.pickupAddress,
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Container(width: 1.5, height: 18, color: AppTheme.border),
                  ),
                  const SizedBox(height: 2),
                  _LocationRow(
                    dot: AppTheme.accent,
                    label: 'Drop-off',
                    address: draft.dropoffAddress.isEmpty ? 'Tap the map after pick-up' : draft.dropoffAddress,
                  ),

                  if (draft.directions != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border, width: 0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _InfoChip(icon: Icons.straighten, label: draft.directions!.distanceText),
                          Container(width: 0.5, height: 24, color: AppTheme.border),
                          _InfoChip(icon: Icons.timer_outlined, label: draft.directions!.durationText),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: draft.isComplete && draft.directions != null
                        ? () => context.push('${AppRoutes.orderSummary}/${widget.vehicleType}')
                        : null,
                      child: const Text('Continue to Price Estimate'),
                    ),
                  ),

                  if (draft.isComplete && draft.directions == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton(
                        onPressed: () {
                          if (draft.pickup != null && draft.dropoff != null) {
                            _fetchRoute(draft.pickup!, draft.dropoff!);
                          }
                        },
                        child: const Text('Calculate Route'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final Color  dot;
  final String label;
  final String address;
  const _LocationRow({required this.dot, required this.label, required this.address});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 14, height: 14, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: AppTheme.fontFamily,
              fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
            Text(address, style: const TextStyle(fontFamily: AppTheme.fontFamily,
              fontSize: 13, color: AppTheme.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ],
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppTheme.primary),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontFamily: AppTheme.fontFamily,
        fontSize: 13, fontWeight: FontWeight.w500)),
    ],
  );
}
