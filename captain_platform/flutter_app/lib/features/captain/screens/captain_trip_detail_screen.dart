import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/providers.dart';

class CaptainTripDetailScreen extends ConsumerWidget {
  final String orderId;
  const CaptainTripDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(singleOrderProvider(orderId));
    return orderAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primary))),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (order) => Scaffold(
        appBar: AppBar(title: const Text('Active Trip')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border, width: 0.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Trip Status: ${order.status.toUpperCase()}',
                  style: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                const SizedBox(height: 12),
                Text('From: ${order.pickupAddress}', style: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 13)),
                const SizedBox(height: 6),
                Text('To: ${order.dropoffAddress}', style: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 13)),
                const SizedBox(height: 12),
                Text('Your Earnings: ${order.driverEarnings.toStringAsFixed(2)} EGP',
                  style: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ])),
            const SizedBox(height: 16),
            if (order.status == AppConstants.statusAccepted)
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => ref.read(orderServiceProvider).updateStatus(orderId, AppConstants.statusOnRoute),
                child: const Text('Start Trip'))),
            if (order.status == AppConstants.statusOnRoute)
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () async {
                  await ref.read(orderServiceProvider).completeOrder(orderId);
                  if (context.mounted) context.go(AppRoutes.captainHome);
                },
                child: const Text('Complete Trip'))),
          ]),
        ),
      ),
    );
  }
}
