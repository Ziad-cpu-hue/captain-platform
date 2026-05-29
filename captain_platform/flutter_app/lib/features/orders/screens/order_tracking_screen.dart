import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/models.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(singleOrderProvider(widget.orderId));

    return orderAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary))),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (order) {
        final captainLocationAsync = order.captainId != null
          ? ref.watch(captainLocationStreamProvider(order.captainId!))
          : null;

        final captainGeo = captainLocationAsync?.value;
        final captainLatLng = captainGeo != null
          ? LatLng(captainGeo.latitude, captainGeo.longitude) : null;

        final pickup  = LatLng(order.pickupLocation.latitude,  order.pickupLocation.longitude);
        final dropoff = LatLng(order.dropoffLocation.latitude, order.dropoffLocation.longitude);

        final markers = <Marker>{
          Marker(markerId: const MarkerId('pickup'),  position: pickup,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: 'Pick-up', snippet: order.pickupAddress)),
          Marker(markerId: const MarkerId('dropoff'), position: dropoff,
            infoWindow: InfoWindow(title: 'Drop-off', snippet: order.dropoffAddress)),
          if (captainLatLng != null)
            Marker(markerId: const MarkerId('captain'), position: captainLatLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              infoWindow: const InfoWindow(title: 'Your Captain')),
        };

        return Scaffold(
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: pickup, zoom: 14),
                onMapCreated: (c) => _mapController = c,
                markers: markers,
                zoomControlsEnabled: false,
                myLocationEnabled: false,
              ),

              // ── Status Banner ───────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.home),
                          child: const Icon(Icons.arrow_back, size: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_statusLabel(order.status),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: _statusColor(order.status))),
                              Text('Order #${widget.orderId.substring(0, 8).toUpperCase()}',
                                style: const TextStyle(fontFamily: AppTheme.fontFamily,
                                  fontSize: 11, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        _StatusDot(color: _statusColor(order.status)),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom Sheet ────────────────────────────────────────────
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 40, height: 4,
                        decoration: BoxDecoration(color: AppTheme.border,
                          borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 16),

                      // ── Order Status Steps ──────────────────────────────
                      _StatusStepper(status: order.status),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // ── Route summary ──────────────────────────────────
                      _RouteRow(
                        dot: AppTheme.primary,
                        address: order.pickupAddress),
                      const SizedBox(height: 8),
                      _RouteRow(
                        dot: AppTheme.accent,
                        address: order.dropoffAddress),
                      const SizedBox(height: 14),

                      // ── Fare ───────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border, width: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Fare',
                              style: TextStyle(fontFamily: AppTheme.fontFamily,
                                fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('${order.totalFare.toStringAsFixed(2)} EGP',
                              style: const TextStyle(fontFamily: AppTheme.fontFamily,
                                fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Chat button ────────────────────────────────────
                      if (order.captainId != null)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final user = ref.read(currentUserProvider).value!;
                              final threadId = await ref.read(chatServiceProvider)
                                .getOrCreateThread(
                                  orderId:    widget.orderId,
                                  customerId: user.uid,
                                  captainId:  order.captainId!,
                                );
                              if (context.mounted) {
                                context.push('${AppRoutes.chatDetail}/$threadId');
                              }
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: const Text('Chat with Captain'),
                          ),
                        ),

                      if (order.status == AppConstants.statusPending)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () async {
                                await ref.read(orderServiceProvider).cancelOrder(widget.orderId);
                                if (context.mounted) context.go(AppRoutes.home);
                              },
                              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                              child: const Text('Cancel Order'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(String status) => switch (status) {
    AppConstants.statusPending   => 'Looking for a captain...',
    AppConstants.statusAccepted  => 'Captain is on the way',
    AppConstants.statusOnRoute   => 'Trip in progress',
    AppConstants.statusArrived   => 'Captain has arrived',
    AppConstants.statusCompleted => 'Trip completed',
    AppConstants.statusCancelled => 'Order cancelled',
    _ => status,
  };

  Color _statusColor(String status) => switch (status) {
    AppConstants.statusPending   => AppTheme.warning,
    AppConstants.statusAccepted  => AppTheme.primary,
    AppConstants.statusOnRoute   => AppTheme.primary,
    AppConstants.statusArrived   => AppTheme.primaryDark,
    AppConstants.statusCompleted => AppTheme.success,
    AppConstants.statusCancelled => AppTheme.danger,
    _ => AppTheme.textSecondary,
  };
}

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 10, height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, spreadRadius: 2)]),
  );
}

class _StatusStepper extends StatelessWidget {
  final String status;
  const _StatusStepper({required this.status});

  static const _steps = [
    AppConstants.statusPending,
    AppConstants.statusAccepted,
    AppConstants.statusOnRoute,
    AppConstants.statusCompleted,
  ];

  static const _labels = ['Requested', 'Accepted', 'On Route', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final currentIdx = _steps.indexOf(status).clamp(0, _steps.length - 1);
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final lineIdx = i ~/ 2;
          final filled = lineIdx < currentIdx;
          return Expanded(child: Container(
            height: 2,
            color: filled ? AppTheme.primary : AppTheme.border,
          ));
        }
        final stepIdx = i ~/ 2;
        final done    = stepIdx <= currentIdx;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: done ? AppTheme.primary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: done ? AppTheme.primary : AppTheme.border, width: 2),
              ),
              child: Icon(Icons.check, size: 14,
                color: done ? Colors.white : AppTheme.border),
            ),
            const SizedBox(height: 4),
            Text(_labels[stepIdx], style: TextStyle(
              fontFamily: AppTheme.fontFamily, fontSize: 9,
              fontWeight: FontWeight.w500,
              color: done ? AppTheme.primary : AppTheme.textHint)),
          ],
        );
      }),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final Color dot; final String address;
  const _RouteRow({required this.dot, required this.address});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text(address, style: const TextStyle(
        fontFamily: AppTheme.fontFamily, fontSize: 13),
        maxLines: 2, overflow: TextOverflow.ellipsis)),
    ],
  );
}
