import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/models.dart';
import '../constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthService
// ─────────────────────────────────────────────────────────────────────────────
class AuthService {
  final FirebaseAuth    _auth    = FirebaseAuth.instance;
  final FirebaseFirestore _db    = FirebaseFirestore.instance;
  final GoogleSignIn    _google  = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser              => _auth.currentUser;

  /// Sign in with Google and create/update the user document in Firestore.
  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);
    final user     = userCred.user!;

    final docRef = _db.collection(AppConstants.colUsers).doc(user.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      // First time — create user document
      final newUser = UserModel(
        uid:         user.uid,
        email:       user.email       ?? '',
        displayName: user.displayName ?? '',
        photoUrl:    user.photoURL    ?? '',
        role:        AppConstants.roleCustomer,
        phone:       user.phoneNumber ?? '',
        createdAt:   DateTime.now(),
      );
      await docRef.set(newUser.toMap());
      return newUser;
    }

    return UserModel.fromFirestore(docSnap);
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _google.signOut()]);
  }

  Future<UserModel?> fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection(AppConstants.colUsers).doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updatePhone(String uid, String phone) =>
    _db.collection(AppConstants.colUsers).doc(uid).update({'phone': phone});
}

// ─────────────────────────────────────────────────────────────────────────────
// OrderService
// ─────────────────────────────────────────────────────────────────────────────
class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _orders => _db.collection(AppConstants.colOrders);

  /// Create a new order and return its ID.
  Future<String> createOrder(OrderModel order) async {
    final ref = await _orders.add(order.toMap());
    return ref.id;
  }

  /// Stream of open orders for a specific vehicle type — used by captains.
  Stream<List<OrderModel>> openOrdersStream(String vehicleType) =>
    _orders
      .where('status',       isEqualTo: AppConstants.statusPending)
      .where('vehicle_type', isEqualTo: vehicleType)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromFirestore).toList());

  /// Stream of a customer's own orders.
  Stream<List<OrderModel>> customerOrdersStream(String customerId) =>
    _orders
      .where('customer_id', isEqualTo: customerId)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromFirestore).toList());

  /// Stream of a captain's assigned orders.
  Stream<List<OrderModel>> captainOrdersStream(String captainId) =>
    _orders
      .where('captain_id', isEqualTo: captainId)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromFirestore).toList());

  /// Stream of a single order (for live tracking).
  Stream<OrderModel> orderStream(String orderId) =>
    _orders.doc(orderId).snapshots().map(OrderModel.fromFirestore);

  Future<void> acceptOrder(String orderId, String captainId) =>
    _orders.doc(orderId).update({
      'status':      AppConstants.statusAccepted,
      'captain_id':  captainId,
      'accepted_at': Timestamp.now(),
    });

  Future<void> updateStatus(String orderId, String status) =>
    _orders.doc(orderId).update({'status': status});

  Future<void> completeOrder(String orderId) =>
    _orders.doc(orderId).update({
      'status':       AppConstants.statusCompleted,
      'completed_at': Timestamp.now(),
    });

  Future<void> cancelOrder(String orderId) =>
    _orders.doc(orderId).update({'status': AppConstants.statusCancelled});

  // ── Admin queries ────────────────────────────────────────────────────────
  Stream<List<OrderModel>> allOrdersStream() =>
    _orders.orderBy('created_at', descending: true).snapshots()
      .map((s) => s.docs.map(OrderModel.fromFirestore).toList());

  Stream<List<OrderModel>> liveOrdersStream() =>
    _orders.where('status', whereIn: [
      AppConstants.statusAccepted,
      AppConstants.statusOnRoute,
      AppConstants.statusArrived,
    ]).snapshots().map((s) => s.docs.map(OrderModel.fromFirestore).toList());

  Future<Map<String, dynamic>> getDashboardStats() async {
    final all       = await _orders.get();
    final live      = await _orders.where('status', whereIn: [AppConstants.statusAccepted, AppConstants.statusOnRoute]).get();
    final completed = await _orders.where('status', isEqualTo: AppConstants.statusCompleted).get();

    double totalRevenue = 0;
    double todayRevenue = 0;
    final today = DateTime.now();
    for (final doc in completed.docs) {
      final o = OrderModel.fromFirestore(doc);
      totalRevenue += o.platformFee;
      if (o.completedAt != null &&
          o.completedAt!.year  == today.year &&
          o.completedAt!.month == today.month &&
          o.completedAt!.day   == today.day) {
        todayRevenue += o.platformFee;
      }
    }
    return {
      'total_orders':     all.docs.length,
      'live_orders':      live.docs.length,
      'completed_orders': completed.docs.length,
      'total_revenue':    totalRevenue,
      'today_revenue':    todayRevenue,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatService
// ─────────────────────────────────────────────────────────────────────────────
class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _chats => _db.collection(AppConstants.colChats);

  /// Get or create a chat thread for an order.
  Future<String> getOrCreateThread({
    required String orderId,
    required String customerId,
    required String captainId,
    bool isSupport = false,
  }) async {
    final existing = await _chats
      .where('order_id',    isEqualTo: orderId)
      .where('is_support',  isEqualTo: isSupport)
      .limit(1).get();

    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final ref = await _chats.add(ChatThread(
      id:         '',
      orderId:    orderId,
      customerId: customerId,
      captainId:  captainId,
      isSupport:  isSupport,
    ).toMap());
    return ref.id;
  }

  Stream<List<ChatMessage>> messagesStream(String threadId) =>
    _chats.doc(threadId)
      .collection(AppConstants.colMessages)
      .orderBy('sent_at')
      .snapshots()
      .map((s) => s.docs.map(ChatMessage.fromFirestore).toList());

  Future<void> sendMessage({
    required String threadId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
  }) async {
    final msgRef = _chats.doc(threadId).collection(AppConstants.colMessages);
    final msgId  = const Uuid().v4();
    await msgRef.doc(msgId).set(ChatMessage(
      id:         msgId,
      senderId:   senderId,
      senderName: senderName,
      senderRole: senderRole,
      text:       text,
      sentAt:     DateTime.now(),
    ).toMap());

    await _chats.doc(threadId).update({
      'last_message':    text,
      'last_message_at': Timestamp.now(),
    });
  }

  Stream<List<ChatThread>> userThreadsStream(String userId) =>
    _chats.where(Filter.or(
      Filter('customer_id', isEqualTo: userId),
      Filter('captain_id',  isEqualTo: userId),
    )).orderBy('last_message_at', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ChatThread.fromFirestore).toList());

  /// All support threads for admin dashboard.
  Stream<List<ChatThread>> supportThreadsStream() =>
    _chats.where('is_support', isEqualTo: true)
      .orderBy('last_message_at', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ChatThread.fromFirestore).toList());
}

// ─────────────────────────────────────────────────────────────────────────────
// CaptainApplicationService
// ─────────────────────────────────────────────────────────────────────────────
class CaptainApplicationService {
  final FirebaseFirestore _db      = FirebaseFirestore.instance;
  final FirebaseStorage   _storage = FirebaseStorage.instance;

  Future<String> _uploadDoc(File file, String uid, String docName) async {
    final path = '${AppConstants.storageCaptainDocs}/$uid/$docName.jpg';
    final ref  = _storage.ref().child(path);
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  /// Upload all 5 required documents and submit the application.
  Future<void> submitApplication({
    required String uid,
    required String displayName,
    required String phone,
    required String vehicleType,
    required String vehicleModel,
    required String licensePlate,
    required File   selfieWithFrontId,
    required File   selfieWithBackId,
    required File   driverLicense,
    required File   carRegistration,
    required File   carWithPlate,
  }) async {
    // Upload documents concurrently
    final urls = await Future.wait([
      _uploadDoc(selfieWithFrontId, uid, 'selfie_front_id'),
      _uploadDoc(selfieWithBackId,  uid, 'selfie_back_id'),
      _uploadDoc(driverLicense,     uid, 'driver_license'),
      _uploadDoc(carRegistration,   uid, 'car_registration'),
      _uploadDoc(carWithPlate,      uid, 'car_with_plate'),
    ]);

    final captain = CaptainModel(
      uid:                  uid,
      displayName:          displayName,
      phone:                phone,
      vehicleType:          vehicleType,
      vehicleModel:         vehicleModel,
      licensePlate:         licensePlate,
      docSelfieWithFrontId: urls[0],
      docSelfieWithBackId:  urls[1],
      docDriverLicense:     urls[2],
      docCarRegistration:   urls[3],
      docCarWithPlate:      urls[4],
      applicationStatus:    AppConstants.appPending,
    );

    await _db.collection(AppConstants.colReviews).doc(uid).set(captain.toMap());
  }

  Stream<List<CaptainModel>> pendingApplicationsStream() =>
    _db.collection(AppConstants.colReviews)
      .where('application_status', isEqualTo: AppConstants.appPending)
      .orderBy('display_name')
      .snapshots()
      .map((s) => s.docs.map(CaptainModel.fromFirestore).toList());

  Future<void> approveApplication(String uid) async {
    final batch = _db.batch();
    // Update the application record
    batch.update(_db.collection(AppConstants.colReviews).doc(uid),
      {'application_status': AppConstants.appApproved});
    // Promote user role to captain
    batch.update(_db.collection(AppConstants.colUsers).doc(uid),
      {'role': AppConstants.roleCaptain});
    // Copy to captains collection
    final appDoc = await _db.collection(AppConstants.colReviews).doc(uid).get();
    batch.set(_db.collection(AppConstants.colCaptains).doc(uid), {
      ...appDoc.data()!,
      'application_status': AppConstants.appApproved,
      'is_online': false,
      'rating': 0.0,
      'total_trips': 0,
    });
    await batch.commit();
  }

  Future<void> rejectApplication(String uid) =>
    _db.collection(AppConstants.colReviews).doc(uid).update(
      {'application_status': AppConstants.appRejected});
}

// ─────────────────────────────────────────────────────────────────────────────
// SettingsService
// ─────────────────────────────────────────────────────────────────────────────
class SettingsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference get _doc =>
    _db.collection(AppConstants.colSettings).doc('global');

  Stream<AppSettings> settingsStream() =>
    _doc.snapshots().map((s) =>
      s.exists ? AppSettings.fromFirestore(s) : const AppSettings());

  Future<AppSettings> getSettings() async {
    final doc = await _doc.get();
    return doc.exists ? AppSettings.fromFirestore(doc) : const AppSettings();
  }

  Future<void> updateFuelPrice(double price) =>
    _doc.set({AppConstants.settingFuelPrice: price}, SetOptions(merge: true));

  Future<void> updateSettings(AppSettings settings) =>
    _doc.set(settings.toMap(), SetOptions(merge: true));
}

// ─────────────────────────────────────────────────────────────────────────────
// CaptainLocationService — real-time captain location updates
// ─────────────────────────────────────────────────────────────────────────────
class CaptainLocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> updateLocation(String captainId, double lat, double lng) =>
    _db.collection(AppConstants.colCaptains).doc(captainId).update({
      'current_location': GeoPoint(lat, lng),
      'last_seen':        Timestamp.now(),
    });

  Future<void> setOnlineStatus(String captainId, bool isOnline) =>
    _db.collection(AppConstants.colCaptains).doc(captainId).update(
      {'is_online': isOnline});

  Stream<GeoPoint?> captainLocationStream(String captainId) =>
    _db.collection(AppConstants.colCaptains).doc(captainId).snapshots()
      .map((d) => d.data()?['current_location'] as GeoPoint?);
}
