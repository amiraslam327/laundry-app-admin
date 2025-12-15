# Laundry App Admin

Admin panel for managing laundries, services, orders, and drivers with Firebase backend.

## Prerequisites
- Flutter 3.x SDK installed (`flutter doctor` passes)
- Dart SDK (bundled with Flutter)
- Firebase project (console: https://console.firebase.google.com)
- Android Studio / Xcode for device simulators or a real device

## 1) Clone & install
```bash
git clone <repo-url>
cd laundry_app_admin
flutter pub get
```

## 2) Firebase setup
Create a Firebase project, then add each platform you need:

### Android
1. Add Android app in Firebase console with package name from `android/app/src/main/AndroidManifest.xml`.
2. Download `google-services.json` and place it at `android/app/google-services.json`.
3. In `android/build.gradle` and `android/app/build.gradle`, ensure the Google services plugin is applied (Flutter defaults usually already do).

### iOS
1. Add iOS app in Firebase console with the bundle ID from `ios/Runner/Info.plist`.
2. Download `GoogleService-Info.plist` and place it at `ios/Runner/GoogleService-Info.plist`.
3. From `ios` directory, run `pod install` if needed (`cd ios && pod install && cd ..`).

### Web (optional)
1. Add a Web app in Firebase console and copy the generated config.
2. Update `web/index.html` Firebase config snippet if you plan to run on web.

## 3) Enable Firebase products
In Firebase console:
- Authentication: enable Email/Password (and any other sign-in methods you use).
- Firestore: create a database in Production mode. Collections used by the app include:
  - `users`, `admins`, `laundries`, `services`, `fragrances`, `orders`, `drivers`, plus nested subcollections like `orders/pending/pending` and `orders/complete/complete`.

## 4) Firestore security rules
Use appropriate rules for your environment (locked-down for production). Example starting point (adjust to your auth model and roles before production):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() { return request.auth != null; }
    match /{document=**} {
      allow read, write: if isSignedIn();
    }
  }
}
```
Replace with stricter, role-based rules before releasing.

## 5) Run the app
```bash
flutter pub get          # already done once, run again if needed
flutter run              # choose a device/emulator
```

## 6) Common troubleshooting
- If builds fail on iOS: run `cd ios && pod install`, then `cd ..`.
- If Firebase is not initialized: verify the platform config files are in place and package/bundle IDs match the Firebase apps.
- If authentication fails: confirm the sign-in method is enabled and the user exists in Firebase Auth.

## Notes
- Admin dashboard shows live Firestore stats and order management. Pending orders live under `orders/pending/pending/{orderId}`; completed orders under `orders/complete/complete/{orderId}`.
- Update environment-specific keys (e.g., Maps) where applicable in platform config files.

