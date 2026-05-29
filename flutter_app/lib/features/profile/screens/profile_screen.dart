import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router.dart';
import '../../../shared/providers/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox();
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Column(children: [
          CircleAvatar(radius: 40,
            backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
            backgroundColor: AppTheme.primaryLight,
            child: user.photoUrl.isEmpty ? const Icon(Icons.person, size: 40, color: AppTheme.primary) : null),
          const SizedBox(height: 12),
          Text(user.displayName, style: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(user.email, style: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(20)),
            child: Text(user.role.toUpperCase(), style: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary))),
        ])),
        const SizedBox(height: 24),
        _tile(icon: Icons.star_outline, label: 'Become a Captain', onTap: () => context.push(AppRoutes.captainApply)),
        _tile(icon: Icons.history, label: 'Order History', onTap: () => context.go(AppRoutes.history)),
        _tile(icon: Icons.headset_mic_outlined, label: 'Contact Support', onTap: () {}),
        _tile(icon: Icons.logout, label: 'Sign Out', color: AppTheme.danger, onTap: () async {
          await ref.read(authServiceProvider).signOut();
          if (context.mounted) context.go(AppRoutes.login);
        }),
      ]),
    );
  }
  Widget _tile({required IconData icon, required String label, VoidCallback? onTap, Color? color}) =>
    Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border, width: 0.5)),
      child: ListTile(leading: Icon(icon, color: color ?? AppTheme.textSecondary, size: 22),
        title: Text(label, style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: color ?? AppTheme.textPrimary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textHint),
        onTap: onTap));
}
