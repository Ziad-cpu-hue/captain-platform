import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router.dart';

class CaptainApplyPendingScreen extends StatelessWidget {
  const CaptainApplyPendingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 96, height: 96,
          decoration: BoxDecoration(color: AppTheme.warningLight, borderRadius: BorderRadius.circular(28)),
          child: const Icon(Icons.hourglass_top_rounded, size: 52, color: AppTheme.warning)),
        const SizedBox(height: 24),
        const Text('Application Submitted!', textAlign: TextAlign.center,
          style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        const Text('Your application is under review. Our team will verify your documents within 24-48 hours. You will be notified once approved.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14, color: AppTheme.textSecondary, height: 1.6)),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () => context.go(AppRoutes.home),
          child: const Text('Back to Home'))),
      ]),
    ))),
  );
}
