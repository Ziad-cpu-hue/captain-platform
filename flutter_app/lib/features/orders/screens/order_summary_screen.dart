import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/models.dart';
import 'order_map_screen.dart' show orderDraftProvider;

class OrderSummaryScreen extends ConsumerStatefulWidget {
  final String vehicleType;
  const OrderSummaryScreen({super.key, required this.vehicleType});

  @override
  ConsumerState<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends ConsumerState<OrderSummaryScreen> {
  bool _booking = false;

  String get _vehicleLabel => switch (widget.vehicleType) {
    AppConstants.vehicleCar   => 'Private Car',
    AppConstants.vehicleMoto  => 'Motorcycle',
    AppConstants.vehicleTruck => 'Cargo Truck',
    _                         => 'Vehicle',
  };

  IconData get _vehicleIcon => switch (widget.vehicleType) {
    AppConstants.vehicleCar   => Icons.directions_car_rounded,
    AppConstants.vehicleMoto  => Icons.two_wheeler_rounded,
    AppConstants.vehicleTruck => Icons.local_shipping_rounded,
    _                         => Icons.directions_car,
  };

  Future<void> _placeOrder(FareBreakdown fare, OrderDraft draft) async {
    setState(() => _booking = true);
    try {
      final user     = ref.read(currentUserProvider).value!;
      final settings = await ref.read(settingsServiceProvider).getSettings();

      final order = OrderModel(
        id:              '',
        customerId:      user.uid,
        customerName:    user.displayName,
        vehicleType:     widget.vehicleType,
        status:          AppConstants.statusPending,
        pickupLocation:  GeoPoint(draft.pickup!.latitude,  draft.pickup!.longitude),
        dropoffLocation: GeoPoint(draft.dropoff!.latitude, draft.dropoff!.longitude),
        pickupAddress:   draft.pickupAddress,
        dropoffAddress:  draft.dropoffAddress,
        distanceKm:      draft.directions!.distanceKm,
        durationMinutes: draft.directions!.durationMinutes,
        totalFare:       fare.totalFare,
        driverEarnings:  fare.driverEarnings,
        platformFee:     fare.platformFee,
        fuelCost:        fare.fuelCost,
        createdAt:       DateTime.now(),
      );

      final orderId = await ref.read(orderServiceProvider).createOrder(order);

      // Reset draft
      ref.read(orderDraftProvider.notifier).state = const OrderDraft();

      if (mounted) {
        context.go('${AppRoutes.tracking}/$orderId');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')));
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft    = ref.watch(orderDraftProvider);
    final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final fare     = settings.engine.calculate(
      distanceKm:  draft.directions?.distanceKm ?? 0,
      vehicleType: widget.vehicleType,
    );

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Order Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Vehicle & Route ─────────────────────────────────────────────
            _Card(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(12)),
                        child: Icon(_vehicleIcon, color: AppTheme.primary, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_vehicleLabel, style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 16, fontWeight: FontWeight.w600)),
                            Text('${fare.distanceFormatted} · ${draft.directions?.durationText ?? ''}',
                              style: const TextStyle(fontFamily: AppTheme.fontFamily,
                                fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _RouteRow(
                    dot: AppTheme.primary,
                    label: 'From', address: draft.pickupAddress),
                  const SizedBox(height: 12),
                  _RouteRow(
                    dot: AppTheme.accent,
                    label: 'To',   address: draft.dropoffAddress),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Fare Breakdown ──────────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Price Breakdown',
                    style: TextStyle(fontFamily: AppTheme.fontFamily,
                      fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _FareRow(
                    label: 'Distance',
                    value: fare.distanceFormatted,
                    sub: '${AppConstants.fuelConsumption[widget.vehicleType]}L/100km',
                  ),
                  _FareRow(
                    label: 'Fuel cost',
                    value: fare.fuelCostFormatted,
                    sub: '${fare.litersUsed.toStringAsFixed(2)}L × ${settings.fuelPricePerLiter.toStringAsFixed(2)} EGP',
                  ),
                  _FareRow(
                    label: 'Driver earnings',
                    value: fare.driverEarningsFormatted,
                    sub: 'Fuel + 80% profit',
                  ),
                  _FareRow(
                    label: 'Platform fee',
                    value: fare.platformFeeFormatted,
                    sub: '10% of transaction',
                    valueColor: AppTheme.textSecondary,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Fare', style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(fare.totalFareFormatted, style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Info note ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Final fare is calculated based on exact GPS distance. '
                      'Fuel price: ${settings.fuelPricePerLiter.toStringAsFixed(2)} EGP/L (92 Octane)',
                      style: const TextStyle(fontFamily: AppTheme.fontFamily,
                        fontSize: 12, color: AppTheme.primaryDark, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Book Button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _booking ? null : () => _placeOrder(fare, draft),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(18)),
                child: _booking
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Confirm Booking · ${fare.totalFareFormatted}',
                      style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border, width: 0.5),
    ),
    child: child,
  );
}

class _RouteRow extends StatelessWidget {
  final Color dot; final String label, address;
  const _RouteRow({required this.dot, required this.label, required this.address});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Container(width: 12, height: 12, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: AppTheme.fontFamily,
              fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
            Text(address, style: const TextStyle(fontFamily: AppTheme.fontFamily,
              fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ],
  );
}

class _FareRow extends StatelessWidget {
  final String label, value, sub;
  final Color? valueColor;
  const _FareRow({required this.label, required this.value, required this.sub, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: AppTheme.fontFamily,
                fontSize: 13, fontWeight: FontWeight.w500)),
              Text(sub, style: const TextStyle(fontFamily: AppTheme.fontFamily,
                fontSize: 11, color: AppTheme.textHint)),
            ],
          ),
        ),
        Text(value, style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 14, fontWeight: FontWeight.w600,
          color: valueColor ?? AppTheme.textPrimary)),
      ],
    ),
  );
}

// Simple OrderDraft alias for import
typedef OrderDraft = dynamic;
