import { initializeApp, getApps } from 'firebase/app';
import { getAuth, GoogleAuthProvider, signInWithCredential, signOut as fbSignOut, onAuthStateChanged as fbAuthState } from 'firebase/auth';
import { getFirestore, doc, getDoc, setDoc, updateDoc, collection, addDoc, query, where, orderBy, limit, getDocs, onSnapshot, serverTimestamp } from 'firebase/firestore';
import { getStorage, ref as storageRef, uploadBytes, getDownloadURL } from 'firebase/storage';

// ── REPLACE THESE with your real Firebase project values ──────────────────────
// Get them from: console.firebase.google.com → Project Settings → Your apps
const firebaseConfig = {
  apiKey: 'YOUR_API_KEY',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  messagingSenderId: 'YOUR_SENDER_ID',
  appId: 'YOUR_APP_ID',
};
// ─────────────────────────────────────────────────────────────────────────────

// Safe init — never crashes even with placeholder values
let app: any, auth: any, db: any, storage: any;
let firebaseReady = false;

try {
  if (!getApps().length) {
    app = initializeApp(firebaseConfig);
  } else {
    app = getApps()[0];
  }
  auth = getAuth(app);
  db = getFirestore(app);
  storage = getStorage(app);
  firebaseReady = firebaseConfig.apiKey !== 'YOUR_API_KEY';
} catch (e) {
  console.warn('Firebase init failed — running in demo mode');
}

export { firebaseReady };

// ── Auth ─────────────────────────────────────────────────────────────────────
export function onAuthStateChanged(callback: (user: any) => void) {
  if (!firebaseReady || !auth) {
    // Demo mode — return null user immediately
    callback(null);
    return () => {};
  }
  return fbAuthState(auth, async (firebaseUser) => {
    if (!firebaseUser) { callback(null); return; }
    try {
      const snap = await getDoc(doc(db, 'users', firebaseUser.uid));
      callback(snap.exists() ? snap.data() : null);
    } catch { callback(null); }
  });
}

export async function signInWithGoogle(): Promise<any> {
  if (!firebaseReady) throw new Error('Firebase not configured yet. Please add your Firebase keys to src/services/firebase.ts');
  // Google Sign-In requires @react-native-google-signin/google-signin
  // For now returns demo user — replace with real Google Sign-In
  throw new Error('Configure Firebase first. See SETUP_GUIDE.md');
}

export async function signOut(): Promise<void> {
  if (!firebaseReady || !auth) return;
  await fbSignOut(auth);
}

// Demo sign-in for testing without Firebase
export function signInDemo(role: 'customer' | 'captain' = 'customer'): any {
  return {
    uid: 'demo_user_001',
    email: 'demo@captain.eg',
    displayName: role === 'captain' ? 'Demo Captain' : 'Ahmed Mohamed',
    photoURL: null,
    role,
    createdAt: new Date(),
  };
}

// ── Settings ─────────────────────────────────────────────────────────────────
export function onSettingsChanged(callback: (s: any) => void) {
  if (!firebaseReady) { callback({ fuelPricePerLiter: 22.25, driverProfitPercent: 80, platformFeePercent: 10 }); return () => {}; }
  return onSnapshot(doc(db, 'settings', 'global'), (snap) => {
    callback(snap.exists() ? snap.data() : { fuelPricePerLiter: 22.25, driverProfitPercent: 80, platformFeePercent: 10 });
  });
}

// ── Orders ────────────────────────────────────────────────────────────────────
export async function createOrder(order: any): Promise<string> {
  if (!firebaseReady) return 'demo_order_' + Date.now();
  const ref = await addDoc(collection(db, 'orders'), { ...order, status: 'pending', createdAt: serverTimestamp() });
  await updateDoc(ref, { id: ref.id });
  return ref.id;
}

export async function acceptOrder(orderId: string, captainId: string, captainName: string) {
  if (!firebaseReady) return;
  await updateDoc(doc(db, 'orders', orderId), { captainId, captainName, status: 'accepted', acceptedAt: serverTimestamp() });
}

export async function updateOrderStatus(orderId: string, status: string) {
  if (!firebaseReady) return;
  const upd: any = { status };
  if (status === 'completed') upd.completedAt = serverTimestamp();
  await updateDoc(doc(db, 'orders', orderId), upd);
}

export async function cancelOrder(orderId: string) {
  if (!firebaseReady) return;
  await updateDoc(doc(db, 'orders', orderId), { status: 'cancelled' });
}

export function onOrderChanged(orderId: string, callback: (o: any) => void) {
  if (!firebaseReady) return () => {};
  return onSnapshot(doc(db, 'orders', orderId), (snap) => { if (snap.exists()) callback(snap.data()); });
}

export function onPendingOrders(vehicleType: string, callback: (orders: any[]) => void) {
  if (!firebaseReady) { callback([]); return () => {}; }
  const q = query(collection(db, 'orders'), where('status', '==', 'pending'), where('vehicleType', '==', vehicleType), orderBy('createdAt', 'desc'));
  return onSnapshot(q, (snap) => callback(snap.docs.map(d => d.data())));
}

export async function getOrderHistory(userId: string, role: string): Promise<any[]> {
  if (!firebaseReady) return [];
  const field = role === 'captain' ? 'captainId' : 'customerId';
  const q = query(collection(db, 'orders'), where(field, '==', userId), orderBy('createdAt', 'desc'), limit(50));
  const snap = await getDocs(q);
  return snap.docs.map(d => d.data());
}

// ── Captain ───────────────────────────────────────────────────────────────────
export async function setCaptainOnline(captainId: string, isOnline: boolean) {
  if (!firebaseReady) return;
  await updateDoc(doc(db, 'captains', captainId), { isOnline });
}

export async function updateCaptainLocation(captainId: string, location: any) {
  if (!firebaseReady) return;
  await updateDoc(doc(db, 'captains', captainId), { currentLocation: location, lastSeen: serverTimestamp() });
}

export function onCaptainLocation(captainId: string, callback: (loc: any) => void) {
  if (!firebaseReady) return () => {};
  return onSnapshot(doc(db, 'captains', captainId), (snap) => {
    if (snap.exists()) callback(snap.data()?.currentLocation || null);
  });
}

export async function submitCaptainApplication(uid: string, data: any) {
  if (!firebaseReady) return;
  await setDoc(doc(db, 'captain_applications', uid), { ...data, id: uid, status: 'pending', createdAt: serverTimestamp() });
}

export async function uploadDocument(uri: string, path: string): Promise<string> {
  if (!firebaseReady) return uri;
  const response = await fetch(uri);
  const blob = await response.blob();
  const ref = storageRef(storage, path);
  await uploadBytes(ref, blob);
  return getDownloadURL(ref);
}

// ── Chat ──────────────────────────────────────────────────────────────────────
export async function sendMessage(threadId: string, message: any) {
  if (!firebaseReady) return;
  const msgRef = await addDoc(collection(db, 'chats', threadId, 'messages'), { ...message, createdAt: serverTimestamp() });
  await updateDoc(msgRef, { id: msgRef.id });
  await setDoc(doc(db, 'chats', threadId), { lastMessage: message.text, lastMessageAt: serverTimestamp() }, { merge: true });
}

export function onMessages(threadId: string, callback: (msgs: any[]) => void) {
  if (!firebaseReady) { callback([]); return () => {}; }
  const q = query(collection(db, 'chats', threadId, 'messages'), orderBy('createdAt', 'asc'));
  return onSnapshot(q, (snap) => callback(snap.docs.map(d => d.data())));
}
