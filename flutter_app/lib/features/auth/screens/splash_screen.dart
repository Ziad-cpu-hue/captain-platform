// splash_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppTheme.dark,
    body: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.directions_car_rounded, color: AppTheme.primary, size: 64),
        SizedBox(height: 16),
        Text('CapTain', style: TextStyle(fontFamily: AppTheme.fontFamily,
          fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    )),
  );
}
