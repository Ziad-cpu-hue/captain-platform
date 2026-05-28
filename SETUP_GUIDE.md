# CapTain Platform — Complete Setup & Deployment Guide

## 📁 Project Structure

```
captain_platform/
├── flutter_app/              ← Mobile app (Android + iOS)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── firebase_options.dart
│   │   ├── core/
│   │   │   ├── constants/app_constants.dart  ← Pricing engine lives here
│   │   │   ├── theme/app_theme.dart          ← Full design system
│   │   │   ├── router.dart
│   │   │   └── services/
│   │   │       ├── firebase_services.dart    ← All Firestore/Auth/Storage
│   │   │       └── maps_service.dart         ← Google Maps Directions API
│   │   ├── features/
│   │   │   ├── auth/      login + splash
│   │   │   ├── home/      customer home + service selection
│   │   │   ├── orders/    map → summary → tracking → history
│   │   │   ├── captain/   home + apply (5 docs) + trip detail
│   │   │   ├── chat/      thread list + real-time chat
│   │   │   └── profile/   user profile + sign out
│   │   └── shared/
│   │       ├── models/    all Firestore data models
│   │       ├── providers/ all Riverpod state providers
│   │       └── widgets/   shared UI components
│   ├── android/AndroidManifest.xml
│   ├── ios/Runner/Info.plist
│   └── pubspec.yaml
├── admin_dashboard/
│   └── captain_admin_dashboard.html  ← Standalone admin web app
├── functions/
│   ├── index.js              ← All Cloud Functions (6 triggers + 2 HTTP)
│   └── package.json
├── firestore.rules           ← Security rules
├── firestore.indexes.json    ← Composite indexes
├── storage.rules
└── firebase.json
```

---

## 🔧 Step 1 — Firebase Project Setup

1. Go to https://console.firebase.google.com
2. Click **Add project** → name it `captain-platform`
3. Enable **Google Analytics** (optional)
4. In the project, enable these services:
   - **Authentication** → Sign-in method → **Google**
   - **Firestore Database** → Create database → **Production mode**
   - **Storage** → Get started → **Production mode**
   - **Cloud Messaging** (for push notifications)
   - **Functions** (requires Blaze plan — pay as you go)
   - **Hosting** (for admin dashboard)

---

## 📱 Step 2 — Flutter App Setup

### 2.1 Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 2.2 Configure Firebase for Flutter
```bash
cd flutter_app
flutterfire configure --project=captain-platform
```
This auto-generates `lib/firebase_options.dart` with the correct values.

### 2.3 Get dependencies
```bash
flutter pub get
```

### 2.4 Add Google Maps API Key

**Android** — in `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

**iOS** — in `ios/Runner/AppDelegate.swift`:
```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(_ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_GOOGLE_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

Also add to `ios/Runner/Info.plist`:
```xml
<key>GMSApiKey</key>
<string>YOUR_IOS_GOOGLE_MAPS_API_KEY</string>
```

### 2.5 Enable required Google APIs
In Google Cloud Console for your project:
- Maps SDK for Android
- Maps SDK for iOS
- Directions API
- Geocoding API
- Places API

### 2.6 Run the app
```bash
flutter run                    # on connected device
flutter run --release          # release build
flutter build apk --release    # build Android APK
flutter build ios --release    # build iOS IPA
```

---

## 🌐 Step 3 — Deploy Admin Dashboard

### 3.1 Update Firebase config in the dashboard
Open `admin_dashboard/captain_admin_dashboard.html` and replace the `FIREBASE_CONFIG` object with your real values from Firebase Console → Project Settings.

### 3.2 Set admin credentials
In the dashboard file, update:
```javascript
const ADMIN_EMAIL    = "your-admin@email.com";
const ADMIN_PASSWORD = "YourStrongPassword";
```

### 3.3 Deploy to Firebase Hosting
```bash
cd captain_platform
firebase login
firebase deploy --only hosting
```
Your admin dashboard will be live at: `https://captain-platform.web.app`

---

## ⚡ Step 4 — Deploy Cloud Functions

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

Functions deployed:
| Function | Trigger | Purpose |
|---|---|---|
| `onOrderCreated` | Firestore write | Notify nearby captains |
| `onOrderAccepted` | Firestore update | Notify customer of status changes |
| `onCaptainApply` | Firestore write | Notify admin of new application |
| `onApplicationReviewed` | Firestore update | Notify captain of approval/rejection |
| `onNewMessage` | Firestore write | Push notification for chat messages |
| `autoCancelStalePendingOrders` | Scheduled (5 min) | Auto-cancel orders after 15 min |
| `updateFcmToken` | HTTP callable | Update push token on login |
| `getPlatformStats` | HTTP callable | Admin stats endpoint |

---

## 🔐 Step 5 — Deploy Security Rules

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
firebase deploy --only firestore:indexes
```

---

## 💰 Step 6 — Initial Settings in Firestore

Create this document in Firestore manually:
- **Collection:** `settings`
- **Document ID:** `global`
- **Fields:**
```json
{
  "fuel_price_per_liter": 22.25,
  "driver_profit_percentage": 0.80,
  "platform_fee_percentage": 0.10
}
```

Create your admin user document after signing in:
- **Collection:** `users`
- **Document ID:** `<your-uid>`
- **Field:** `"role": "admin"`

---

## 📊 Pricing Formula Summary

```
fuel_cost       = distance_km × (consumption_L_per_100km / 100) × fuel_price_per_liter
driver_profit   = fuel_cost × 0.80
driver_earnings = fuel_cost + driver_profit
total_fare      = driver_earnings / (1 - 0.10)   ← so platform gets exactly 10%
platform_fee    = total_fare - driver_earnings

Example: 12 km trip, car (8L/100km), fuel = 22.25 EGP/L
  fuel_cost       = 12 × 0.08 × 22.25 = 21.36 EGP
  driver_profit   = 21.36 × 0.80     = 17.09 EGP
  driver_earnings = 21.36 + 17.09    = 38.45 EGP
  total_fare      = 38.45 / 0.90     = 42.72 EGP
  platform_fee    = 42.72 - 38.45    =  4.27 EGP
```

Fuel consumption rates:
| Vehicle | Consumption |
|---|---|
| Private Car | 8.0 L/100km |
| Motorcycle | 3.5 L/100km |
| Refrigerated Truck | 18.0 L/100km |

---

## 🗺️ Firestore Data Model

```
users/{uid}
  email, display_name, photo_url, role, phone, created_at, is_active

captains/{uid}
  display_name, phone, vehicle_type, vehicle_model, license_plate,
  rating, total_trips, is_online, current_location (GeoPoint),
  application_status, doc_selfie_front_id, doc_selfie_back_id,
  doc_driver_license, doc_car_registration, doc_car_with_plate

captain_applications/{uid}  (same as captains, before approval)

orders/{orderId}
  customer_id, customer_name, captain_id, vehicle_type, status,
  pickup_location (GeoPoint), dropoff_location (GeoPoint),
  pickup_address, dropoff_address, distance_km, duration_minutes,
  total_fare, driver_earnings, platform_fee, fuel_cost,
  created_at, accepted_at, completed_at, notes

chats/{threadId}
  order_id, customer_id, captain_id, last_message,
  last_message_at, unread_count, is_support

  messages/{msgId}
    sender_id, sender_name, sender_role, text, sent_at, is_read

settings/global
  fuel_price_per_liter, driver_profit_percentage, platform_fee_percentage
```

---

## 📦 Building for Production

### Android APK/AAB
```bash
flutter build apk  --release  # APK  (direct install)
flutter build appbundle        # AAB  (Google Play Store)
```

### iOS IPA
```bash
flutter build ios --release
# Then open Xcode → Product → Archive → Distribute App
```

### Google Play Store Checklist
- [ ] App signing configured
- [ ] `google-services.json` in `android/app/`
- [ ] Permissions reviewed
- [ ] Target SDK 34+
- [ ] Privacy policy URL

### Apple App Store Checklist
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Signing & capabilities configured
- [ ] Background modes enabled
- [ ] NSLocation descriptions in Info.plist
- [ ] Privacy manifest (required iOS 17+)

---

## 📞 Support

- Admin Dashboard: `https://captain-platform.web.app`
- Firebase Console: `https://console.firebase.google.com/project/captain-platform`
- Google Cloud Console: `https://console.cloud.google.com`
