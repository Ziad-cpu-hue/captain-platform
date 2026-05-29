import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // router redirect handles navigation
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      body: Stack(
        children: [
          // Background decorative circles
          Positioned(top: -80, right: -60,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(bottom: -100, left: -80,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // Logo & tagline
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.directions_car_rounded,
                          color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 24),
                      const Text('CapTain',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 38, fontWeight: FontWeight.w700,
                          color: Colors.white, letterSpacing: -1,
                        )),
                      const SizedBox(height: 10),
                      Text('Your ride, your cargo, your way',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 15, color: Colors.white.withOpacity(0.55),
                          fontWeight: FontWeight.w400,
                        )),

                      const Spacer(flex: 2),

                      // Feature pills
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: const [
                          _Pill(icon: Icons.directions_car,  label: 'Private Cars'),
                          _Pill(icon: Icons.two_wheeler,     label: 'Motorcycles'),
                          _Pill(icon: Icons.local_shipping,  label: 'Cargo Trucks'),
                        ],
                      ),

                      const Spacer(flex: 3),

                      // Google sign-in button
                      SizedBox(
                        width: double.infinity,
                        child: _loading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                          : GestureDetector(
                              onTap: _signIn,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset('assets/icons/google.png', width: 22, height: 22),
                                    const SizedBox(width: 12),
                                    const Text('Continue with Google',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 16, fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      )),
                                  ],
                                ),
                              ),
                            ),
                      ),

                      const SizedBox(height: 20),
                      Text(
                        'By continuing you agree to our Terms of Service\nand Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.35),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.07),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.primary, size: 16),
        const SizedBox(width: 6),
        Text(label,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500,
          )),
      ],
    ),
  );
}
