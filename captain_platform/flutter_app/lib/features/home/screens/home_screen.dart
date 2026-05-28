import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('CapTain', style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primary,
                )),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: user?.photoUrl.isNotEmpty == true
                    ? NetworkImage(user!.photoUrl) : null,
                  backgroundColor: AppTheme.primaryLight,
                  child: user?.photoUrl.isEmpty == true
                    ? const Icon(Icons.person, color: AppTheme.primary, size: 20) : null,
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting ─────────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.displayName.split(' ').first ?? 'there'} 👋',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text('What would you like to request today?',
                        style: TextStyle(fontFamily: AppTheme.fontFamily,
                          fontSize: 14, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Service Cards ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Our Services',
                    style: TextStyle(fontFamily: AppTheme.fontFamily,
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary,
                      letterSpacing: 0.5)),
                ),
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _ServiceCard(
                        vehicleType: AppConstants.vehicleCar,
                        icon: Icons.directions_car_rounded,
                        title: 'Private Car',
                        subtitle: 'Comfortable rides for daily travel',
                        tag: 'Most Popular',
                        tagColor: AppTheme.primary,
                        consumption: '8L/100km',
                        onTap: () => context.push('${AppRoutes.orderMap}/${AppConstants.vehicleCar}'),
                      ),
                      const SizedBox(height: 10),
                      _ServiceCard(
                        vehicleType: AppConstants.vehicleMoto,
                        icon: Icons.two_wheeler_rounded,
                        title: 'Motorcycle',
                        subtitle: 'Fast delivery for small packages',
                        tag: 'Fastest',
                        tagColor: AppTheme.warning,
                        consumption: '3.5L/100km',
                        onTap: () => context.push('${AppRoutes.orderMap}/${AppConstants.vehicleMoto}'),
                      ),
                      const SizedBox(height: 10),
                      _ServiceCard(
                        vehicleType: AppConstants.vehicleTruck,
                        icon: Icons.local_shipping_rounded,
                        title: 'Refrigerated Truck',
                        subtitle: 'Cold chain transport for goods & cargo',
                        tag: 'Cargo',
                        tagColor: AppTheme.accent,
                        consumption: '18L/100km',
                        onTap: () => context.push('${AppRoutes.orderMap}/${AppConstants.vehicleTruck}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Become a Captain Banner ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.captainApply),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.dark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.star_rounded, color: AppTheme.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Become a Captain',
                                  style: TextStyle(fontFamily: AppTheme.fontFamily,
                                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                SizedBox(height: 3),
                                Text('Join our team and start earning',
                                  style: TextStyle(fontFamily: AppTheme.fontFamily,
                                    fontSize: 12, color: Color(0xFF888780))),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                            color: AppTheme.primary, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String   vehicleType;
  final IconData icon;
  final String   title;
  final String   subtitle;
  final String   tag;
  final Color    tagColor;
  final String   consumption;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.vehicleType, required this.icon,
    required this.title, required this.subtitle,
    required this.tag, required this.tagColor,
    required this.consumption, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(tag, style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10, fontWeight: FontWeight.w600, color: tagColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Text('⛽ $consumption average',
                  style: const TextStyle(fontFamily: AppTheme.fontFamily,
                    fontSize: 11, color: AppTheme.textHint)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textHint, size: 14),
        ],
      ),
    ),
  );
}
