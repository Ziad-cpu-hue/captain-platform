import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/service_selection_screen.dart';
import '../features/orders/screens/order_map_screen.dart';
import '../features/orders/screens/order_summary_screen.dart';
import '../features/orders/screens/order_tracking_screen.dart';
import '../features/orders/screens/order_history_screen.dart';
import '../features/captain/screens/captain_home_screen.dart';
import '../features/captain/screens/captain_apply_screen.dart';
import '../features/captain/screens/captain_apply_pending_screen.dart';
import '../features/captain/screens/captain_trip_detail_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_detail_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../shared/providers/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = userAsync.value != null;
      final isOnAuth   = state.matchedLocation == AppRoutes.login
                      || state.matchedLocation == AppRoutes.splash;

      if (!isLoggedIn && !isOnAuth) return AppRoutes.login;
      if (isLoggedIn  &&  isOnAuth) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash,  builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login,   builder: (_, __) => const LoginScreen()),

      // ── Shell with bottom nav ──────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home,         builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.history,       builder: (_, __) => const OrderHistoryScreen()),
          GoRoute(path: AppRoutes.chat,          builder: (_, __) => const ChatListScreen()),
          GoRoute(path: AppRoutes.profile,       builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Ordering flow ──────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.selectService, builder: (_, __) => const ServiceSelectionScreen()),
      GoRoute(
        path: '${AppRoutes.orderMap}/:vehicleType',
        builder: (_, state) => OrderMapScreen(vehicleType: state.pathParameters['vehicleType']!),
      ),
      GoRoute(
        path: '${AppRoutes.orderSummary}/:vehicleType',
        builder: (_, state) => OrderSummaryScreen(vehicleType: state.pathParameters['vehicleType']!),
      ),
      GoRoute(
        path: '${AppRoutes.tracking}/:orderId',
        builder: (_, state) => OrderTrackingScreen(orderId: state.pathParameters['orderId']!),
      ),

      // ── Captain ────────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.captainHome,     builder: (_, __) => const CaptainHomeScreen()),
      GoRoute(path: AppRoutes.captainApply,    builder: (_, __) => const CaptainApplyScreen()),
      GoRoute(path: AppRoutes.captainPending,  builder: (_, __) => const CaptainApplyPendingScreen()),
      GoRoute(
        path: '${AppRoutes.captainTrip}/:orderId',
        builder: (_, state) => CaptainTripDetailScreen(orderId: state.pathParameters['orderId']!),
      ),

      // ── Chat ───────────────────────────────────────────────────────────────
      GoRoute(
        path: '${AppRoutes.chatDetail}/:threadId',
        builder: (_, state) => ChatDetailScreen(threadId: state.pathParameters['threadId']!),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

class AppRoutes {
  static const splash         = '/';
  static const login          = '/login';
  static const home           = '/home';
  static const history        = '/history';
  static const chat           = '/chat';
  static const chatDetail     = '/chat/detail';
  static const profile        = '/profile';
  static const selectService  = '/select-service';
  static const orderMap       = '/order/map';
  static const orderSummary   = '/order/summary';
  static const tracking       = '/order/tracking';
  static const captainHome    = '/captain/home';
  static const captainApply   = '/captain/apply';
  static const captainPending = '/captain/pending';
  static const captainTrip    = '/captain/trip';
}

// ── Bottom Nav Shell ──────────────────────────────────────────────────────────
class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final isCaptain = user?.isCaptain ?? false;

    // Captain mode uses a different nav
    if (isCaptain) {
      return Scaffold(body: child);
    }

    final tabs = [
      AppRoutes.home,
      AppRoutes.history,
      AppRoutes.chat,
      AppRoutes.profile,
    ];

    int currentIndex = tabs.indexWhere((t) => location.startsWith(t));
    if (currentIndex < 0) currentIndex = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFD3D1C7), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) => context.go(tabs[i]),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined),    activeIcon: Icon(Icons.home),           label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined),  activeIcon: Icon(Icons.history),         label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline),activeIcon: Icon(Icons.chat_bubble),   label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline),    activeIcon: Icon(Icons.person),         label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
