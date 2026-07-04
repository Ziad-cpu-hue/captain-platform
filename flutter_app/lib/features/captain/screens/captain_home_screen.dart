import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/models.dart';

class CaptainHomeScreen extends ConsumerStatefulWidget {
  const CaptainHomeScreen({super.key});

  @override
  ConsumerState<CaptainHomeScreen> createState() => _CaptainHomeScreenState();
}

class _CaptainHomeScreenState extends ConsumerState<CaptainHomeScreen> {
  bool _isOnline = false;
  String _selectedVehicle = AppConstants.vehicleCar;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || !user.isCaptain) return;

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 30,
      ),
    ).listen((pos) {
      if (_isOnline) {
        ref.read(captainLocationProvider).updateLocation(
          user.uid, pos.latitude, pos.longitude);
      }
    });
  }

  Future<void> _toggleOnline(String captainId) async {
    final newState = !_isOnline;
    setState(() => _isOnline = newState);
    await ref.read(captainLocationProvider).setOnlineStatus(captainId, newState);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    if (user == null) return const SizedBox();

    final openOrdersAsync = ref.watch(openOrdersProvider(_selectedVehicle));
    final myOrdersAsync   = ref.watch(captainOrdersStreamProvider(user.uid));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: AppTheme.dark,
            title: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('CapTain', style: TextStyle(
                  fontFamily: AppTheme.fontFamily, fontSize: 20,
                  fontWeight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                Text('Captain Mode', style: TextStyle(
                  fontFamily: AppTheme.fontFamily, fontSize: 12,
                  color: Colors.white.withOpacity(0.6))),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _toggleOnline(user.uid),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isOnline ? AppTheme.primary : AppTheme.grey600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 7, height: 7,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(_isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(fontFamily: AppTheme.fontFamily,
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Earnings Summary ──────────────────────────────────────
                Container(
                  color: AppTheme.dark,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: myOrdersAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (orders) {
                      final completed = orders.where((o) => o.isCompleted).toList();
                      final todayEarnings = completed
                        .where((o) => o.completedAt != null &&
                          o.completedAt!.day == DateTime.now().day)
                        .fold(0.0, (sum, o) => sum + o.driverEarnings);
                      return Row(
                        children: [
                          _EarningsCard(label: "Today's Earnings",
                            value: '${todayEarnings.toStringAsFixed(0)} EGP',
                            icon: Icons.wallet),
                          const SizedBox(width: 12),
                          _EarningsCard(label: 'Total Trips',
                            value: '${completed.length}',
                            icon: Icons.route),
                        ],
                      );
                    },
                  ),
                ),

                // ── Vehicle Filter ────────────────────────────────────────
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Available Requests',
                        style: TextStyle(fontFamily: AppTheme.fontFamily,
                          fontSize: 15, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      _VehicleChip(
                        label: '🚗',
                        selected: _selectedVehicle == AppConstants.vehicleCar,
                        onTap: () => setState(() => _selectedVehicle = AppConstants.vehicleCar),
                      ),
                      const SizedBox(width: 6),
                      _VehicleChip(
                        label: '🏍️',
                        selected: _selectedVehicle == AppConstants.vehicleMoto,
                        onTap: () => setState(() => _selectedVehicle = AppConstants.vehicleMoto),
                      ),
                      const SizedBox(width: 6),
                      _VehicleChip(
                        label: '🚚',
                        selected: _selectedVehicle == AppConstants.vehicleTruck,
                        onTap: () => setState(() => _selectedVehicle = AppConstants.vehicleTruck),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Order Cards ───────────────────────────────────────────
                if (!_isOnline)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.power_off_rounded,
                            size: 56, color: AppTheme.grey100),
                          const SizedBox(height: 12),
                          const Text('You are offline',
                            style: TextStyle(fontFamily: AppTheme.fontFamily,
                              fontSize: 16, fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary)),
                          const SizedBox(height: 6),
                          const Text('Toggle online to receive order requests',
                            style: TextStyle(fontFamily: AppTheme.fontFamily,
                              fontSize: 13, color: AppTheme.textHint),
                            textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                else
                  openOrdersAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppTheme.primary))),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (orders) {
                      if (orders.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Column(children: [
                            Icon(Icons.inbox_rounded, size: 48, color: AppTheme.grey100),
                            SizedBox(height: 10),
                            Text('No requests right now',
                              style: TextStyle(fontFamily: AppTheme.fontFamily,
                                fontSize: 14, color: AppTheme.textSecondary)),
                            SizedBox(height: 4),
                            Text('New orders will appear here automatically',
                              style: TextStyle(fontFamily: AppTheme.fontFamily,
                                fontSize: 12, color: AppTheme.textHint)),
                          ])),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _OrderRequestCard(
                          order: orders[i],
                          captainId: user.uid,
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Requests'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _EarningsCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(label, style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11, color: Colors.white.withOpacity(0.5))),
        ],
      ),
    ),
  );
}

class _VehicleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _VehicleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: selected ? AppTheme.primaryLight : AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppTheme.primary : AppTheme.border, width: 1),
      ),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 18))),
    ),
  );
}

class _OrderRequestCard extends ConsumerWidget {
  final OrderModel order;
  final String captainId;
  const _OrderRequestCard({required this.order, required this.captainId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final fare = settings.engine.calculate(
      distanceKm: order.distanceKm, vehicleType: order.vehicleType);

    final vehicleEmoji = switch (order.vehicleType) {
      AppConstants.vehicleCar   => '🚗',
      AppConstants.vehicleMoto  => '🏍️',
      AppConstants.vehicleTruck => '🚚',
      _                         => '🚗',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(vehicleEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.pickupAddress, style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('→ ${order.dropoffAddress}',
                      style: const TextStyle(fontFamily: AppTheme.fontFamily,
                        fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetaChip(icon: Icons.straighten, label: order.distanceKm.toStringAsFixed(1) + ' km'),
              const SizedBox(width: 8),
              _MetaChip(icon: Icons.timer_outlined,
                label: '~${order.durationMinutes} min'),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('You earn', style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10, color: AppTheme.textSecondary)),
                  Text(fare.driverEarningsFormatted, style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(orderServiceProvider).cancelOrder(order.id);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(orderServiceProvider).acceptOrder(order.id, captainId);
                    if (context.mounted) {
                      context.push('${AppRoutes.captainTrip}/${order.id}');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text('Accept Trip'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon; final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.border, width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(
          fontFamily: AppTheme.fontFamily, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}
