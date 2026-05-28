/**
 * CapTain Platform — Firebase Cloud Functions
 * Deploy: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin     = require('firebase-admin');

admin.initializeApp();

const db      = admin.firestore();
const messaging = admin.messaging();

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: Send FCM push notification
// ─────────────────────────────────────────────────────────────────────────────
async function sendPush(uid, title, body, data = {}) {
  try {
    const userDoc = await db.collection('users').doc(uid).get();
    const fcmToken = userDoc.data()?.fcm_token;
    if (!fcmToken) return;

    await messaging.send({
      token: fcmToken,
      notification: { title, body },
      data: { ...data, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
      android: {
        priority: 'high',
        notification: { sound: 'default', channelId: 'captain_channel' },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    });
  } catch (e) {
    console.error('Push notification error:', e.message);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRIGGER: New order created  → Notify nearby online captains
// ─────────────────────────────────────────────────────────────────────────────
exports.onOrderCreated = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order     = snap.data();
    const orderId   = context.params.orderId;
    const vehicleType = order.vehicle_type;

    // Get all online captains with the matching vehicle type
    const captainsSnap = await db.collection('captains')
      .where('is_online',      '==', true)
      .where('application_status', '==', 'approved')
      .where('vehicle_type',   '==', vehicleType)
      .get();

    if (captainsSnap.empty) {
      console.log(`No online ${vehicleType} captains available for order ${orderId}`);
      return null;
    }

    const notifications = captainsSnap.docs.map(doc =>
      sendPush(
        doc.id,
        '🚀 New Trip Request!',
        `${order.pickup_address} → ${order.dropoff_address} · ${order.distance_km?.toFixed(1)} km`,
        { order_id: orderId, type: 'new_order', vehicle_type: vehicleType },
      )
    );

    await Promise.all(notifications);
    console.log(`Notified ${captainsSnap.size} captains for order ${orderId}`);
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// TRIGGER: Order accepted → Notify customer
// ─────────────────────────────────────────────────────────────────────────────
exports.onOrderAccepted = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();
    const orderId = context.params.orderId;

    // Captain accepted
    if (before.status === 'pending' && after.status === 'accepted') {
      const captainDoc = await db.collection('captains').doc(after.captain_id).get();
      const captain    = captainDoc.data();

      await sendPush(
        after.customer_id,
        '🎉 Captain Found!',
        `${captain?.display_name || 'Your captain'} is on the way`,
        { order_id: orderId, type: 'order_accepted' },
      );
    }

    // Trip started (on_route)
    if (before.status === 'accepted' && after.status === 'on_route') {
      await sendPush(
        after.customer_id,
        '🚗 Trip Started',
        'Your captain has started the journey',
        { order_id: orderId, type: 'trip_started' },
      );
    }

    // Captain arrived
    if (before.status === 'on_route' && after.status === 'arrived') {
      await sendPush(
        after.customer_id,
        '📍 Captain Arrived',
        'Your captain is waiting at the pick-up location',
        { order_id: orderId, type: 'captain_arrived' },
      );
    }

    // Trip completed
    if (before.status !== 'completed' && after.status === 'completed') {
      // Notify customer
      await sendPush(
        after.customer_id,
        '✅ Trip Completed',
        `Total fare: ${after.total_fare?.toFixed(2)} EGP. Thank you for using CapTain!`,
        { order_id: orderId, type: 'trip_completed' },
      );

      // Notify captain
      if (after.captain_id) {
        await sendPush(
          after.captain_id,
          '💰 Earnings Added',
          `You earned ${after.driver_earnings?.toFixed(2)} EGP for this trip!`,
          { order_id: orderId, type: 'earnings_added' },
        );

        // Increment captain's total_trips counter
        await db.collection('captains').doc(after.captain_id).update({
          total_trips: admin.firestore.FieldValue.increment(1),
        });
      }
    }

    // Order cancelled
    if (before.status !== 'cancelled' && after.status === 'cancelled') {
      if (after.captain_id) {
        await sendPush(
          after.captain_id,
          '❌ Order Cancelled',
          'The customer cancelled their order',
          { order_id: orderId, type: 'order_cancelled' },
        );
      }
    }

    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// TRIGGER: Captain application submitted → Notify admin
// ─────────────────────────────────────────────────────────────────────────────
exports.onCaptainApply = functions.firestore
  .document('captain_applications/{uid}')
  .onCreate(async (snap, context) => {
    const app = snap.data();
    console.log(`New captain application from ${app.display_name}`);

    // Notify all admin users
    const adminsSnap = await db.collection('users')
      .where('role', '==', 'admin').get();

    const notifications = adminsSnap.docs.map(doc =>
      sendPush(
        doc.id,
        '📋 New Captain Application',
        `${app.display_name} applied as a ${app.vehicle_type} captain`,
        { uid: context.params.uid, type: 'new_application' },
      )
    );

    await Promise.all(notifications);
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// TRIGGER: Application approved → Notify captain
// ─────────────────────────────────────────────────────────────────────────────
exports.onApplicationReviewed = functions.firestore
  .document('captain_applications/{uid}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();
    const uid    = context.params.uid;

    if (before.application_status === 'pending' &&
        after.application_status  === 'approved') {
      await sendPush(
        uid,
        '🎉 You\'re approved!',
        'Congratulations! Your captain application has been approved. You can now receive trips.',
        { type: 'application_approved' },
      );
    }

    if (before.application_status === 'pending' &&
        after.application_status  === 'rejected') {
      await sendPush(
        uid,
        '❌ Application Update',
        'Your captain application was not approved. Contact support for details.',
        { type: 'application_rejected' },
      );
    }

    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// TRIGGER: New message → Notify recipient
// ─────────────────────────────────────────────────────────────────────────────
exports.onNewMessage = functions.firestore
  .document('chats/{threadId}/messages/{msgId}')
  .onCreate(async (snap, context) => {
    const msg      = snap.data();
    const threadId = context.params.threadId;

    const threadDoc = await db.collection('chats').doc(threadId).get();
    const thread    = threadDoc.data();
    if (!thread) return null;

    // Update thread last_message
    await db.collection('chats').doc(threadId).update({
      last_message:    msg.text,
      last_message_at: admin.firestore.Timestamp.now(),
      unread_count:    admin.firestore.FieldValue.increment(1),
    });

    // Determine recipient
    const recipientId = msg.sender_id === thread.customer_id
      ? thread.captain_id : thread.customer_id;

    if (!recipientId || recipientId === 'support') return null;

    await sendPush(
      recipientId,
      `💬 ${msg.sender_name}`,
      msg.text.length > 60 ? msg.text.substring(0, 60) + '…' : msg.text,
      { thread_id: threadId, type: 'new_message' },
    );

    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// HTTP: Update FCM token when user logs in (called from app)
// ─────────────────────────────────────────────────────────────────────────────
exports.updateFcmToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
  const { token } = data;
  if (!token) throw new functions.https.HttpsError('invalid-argument', 'Token required');

  await db.collection('users').doc(context.auth.uid).update({ fcm_token: token });
  return { success: true };
});

// ─────────────────────────────────────────────────────────────────────────────
// SCHEDULED: Cancel orders stuck in 'pending' for > 15 minutes
// ─────────────────────────────────────────────────────────────────────────────
exports.autoCancelStalePendingOrders = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    const fifteenMinutesAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 15 * 60 * 1000));

    const staleOrders = await db.collection('orders')
      .where('status',     '==', 'pending')
      .where('created_at', '<',  fifteenMinutesAgo)
      .get();

    const batch = db.batch();
    staleOrders.docs.forEach(doc => {
      batch.update(doc.ref, { status: 'cancelled' });
    });

    await batch.commit();
    console.log(`Auto-cancelled ${staleOrders.size} stale pending orders`);
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// HTTP: Get platform stats (admin only)
// ─────────────────────────────────────────────────────────────────────────────
exports.getPlatformStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');

  const userDoc = await db.collection('users').doc(context.auth.uid).get();
  if (userDoc.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }

  const [ordersSnap, captainsSnap, usersSnap] = await Promise.all([
    db.collection('orders').get(),
    db.collection('captains').where('application_status', '==', 'approved').get(),
    db.collection('users').get(),
  ]);

  const orders     = ordersSnap.docs.map(d => d.data());
  const completed  = orders.filter(o => o.status === 'completed');
  const live       = orders.filter(o => ['accepted','on_route','arrived'].includes(o.status));

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const todayOrders = completed.filter(o => {
    const d = o.completed_at?.toDate?.();
    return d && d >= today;
  });

  return {
    totalOrders:      orders.length,
    completedOrders:  completed.length,
    liveOrders:       live.length,
    totalCaptains:    captainsSnap.size,
    totalUsers:       usersSnap.size,
    totalRevenue:     completed.reduce((s, o) => s + (o.platform_fee || 0), 0),
    todayRevenue:     todayOrders.reduce((s, o) => s + (o.platform_fee || 0), 0),
    todayTrips:       todayOrders.length,
    onlineCaptains:   captainsSnap.docs.filter(d => d.data().is_online).length,
  };
});
