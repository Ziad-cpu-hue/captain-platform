import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/models.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox();
    final ordersAsync = ref.watch(customerOrdersProvider(user.uid));
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (orders) {
          if (orders.isEmpty) return const Center(child: Text('No orders yet',
            style: TextStyle(fontFamily: AppTheme.fontFamily, color: AppTheme.textSecondary)));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final o = orders[i];
              final color = o.isCompleted ? AppTheme.success
                : o.isCancelled ? AppTheme.danger
                : o.isLive ? AppTheme.primary : AppTheme.warning;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border, width: 0.5)),
                child: Row(children: [
                  Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(_vehicleIcon(o.vehicleType), color: color, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.dropoffAddress, style: const TextStyle(fontFamily: AppTheme.fontFamily,
                      fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(DateFormat('d MMM, hh:mm a').format(o.createdAt),
                      style: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 11, color: AppTheme.textHint)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${o.totalFare.toStringAsFixed(2)} EGP',
                      style: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w700)),
                    Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(o.status, style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 10, fontWeight: FontWeight.w600, color: color))),
                  ]),
                ]),
              );
            });
        }),
    );
  }
  IconData _vehicleIcon(String t) => t == AppConstants.vehicleCar ? Icons.directions_car_rounded
    : t == AppConstants.vehicleMoto ? Icons.two_wheeler_rounded : Icons.local_shipping_rounded;
}
