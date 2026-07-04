import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/firebase_services.dart';
import '../../core/services/maps_service.dart';
import '../models/models.dart';

// ── Services ─────────────────────────────────────────────────────────────────
final authServiceProvider     = Provider<AuthService>((_)     => AuthService());
final orderServiceProvider    = Provider<OrderService>((_)    => OrderService());
final chatServiceProvider     = Provider<ChatService>((_)     => ChatService());
final captainAppServiceProvider = Provider<CaptainApplicationService>((_) => CaptainApplicationService());
final settingsServiceProvider = Provider<SettingsService>((_) => SettingsService());
final mapsServiceProvider     = Provider<MapsService>((_)     => MapsService());
final captainLocationProvider = Provider<CaptainLocationService>((_) => CaptainLocationService());

// ── Current User ─────────────────────────────────────────────────────────────
final currentUserProvider = StreamProvider<UserModel?>((ref) async* {
  final authService = ref.watch(authServiceProvider);
  await for (final _ in authService.authStateChanges) {
    yield await authService.fetchCurrentUser();
  }
});

// ── App Settings (live stream from Firestore) ────────────────────────────────
final appSettingsProvider = StreamProvider<AppSettings>((ref) {
  return ref.watch(settingsServiceProvider).settingsStream();
});

// ── Orders ────────────────────────────────────────────────────────────────────
final customerOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, customerId) {
  return ref.watch(orderServiceProvider).customerOrdersStream(customerId);
});

final openOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, vehicleType) {
  return ref.watch(orderServiceProvider).openOrdersStream(vehicleType);
});

final captainOrdersStreamProvider = StreamProvider.family<List<OrderModel>, String>((ref, captainId) {
  return ref.watch(orderServiceProvider).captainOrdersStream(captainId);
});

final singleOrderProvider = StreamProvider.family<OrderModel, String>((ref, orderId) {
  return ref.watch(orderServiceProvider).orderStream(orderId);
});

// ── Chat ──────────────────────────────────────────────────────────────────────
final userThreadsProvider = StreamProvider.family<List<ChatThread>, String>((ref, userId) {
  return ref.watch(chatServiceProvider).userThreadsStream(userId);
});

final messagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, threadId) {
  return ref.watch(chatServiceProvider).messagesStream(threadId);
});

// ── Captain Applications ──────────────────────────────────────────────────────
final pendingApplicationsProvider = StreamProvider<List<CaptainModel>>((ref) {
  return ref.watch(captainAppServiceProvider).pendingApplicationsStream();
});

// ── Admin Dashboard Stats ─────────────────────────────────────────────────────
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(orderServiceProvider).getDashboardStats();
});

final allOrdersAdminProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderServiceProvider).allOrdersStream();
});

final liveOrdersAdminProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderServiceProvider).liveOrdersStream();
});

// ── Captain Location ──────────────────────────────────────────────────────────
final captainLocationStreamProvider = StreamProvider.family<GeoPoint?, String>((ref, captainId) {
  return ref.watch(captainLocationProvider).captainLocationStream(captainId);
});
