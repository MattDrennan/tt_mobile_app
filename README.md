# 501st Legion Troop Tracker Mobile App

A Flutter mobile app for tracking **Star Wars costuming events (troops)** for the 501st Legion,
built for the Florida Garrison. Requires a running instance of
[Troop Tracker](https://github.com/obsidianslicers/trooper-tracker) and (OPTIONAL)
[XenForo](https://xenforo.com/) for authentication and forum integration.

**Live apps:**
- [Android (Google Play)](https://play.google.com/store/apps/details?id=com.drennansoftware.troop_tracker)
- [iOS (App Store)](https://apps.apple.com/us/app/troop-tracker/id6739888656)
- [Web](https://www.fl501st.com/troop-tracker/)

---

## Features

- OAuth2 PKCE login via XenForo
- Browse upcoming and past troops (events)
- Confirm attendance, add guests, and add friends to troops
- View event details: location, limits, costumes, and roster
- Real-time chat per troop (powered by XenForo threads)
- Push notifications via Firebase Cloud Messaging
- Session persistence via Hive local storage

---

## Setup

### 1. Install the XenForo add-ons

In your XenForo installation, install the following Troop Tracker add-ons:

- [TroopTrackerViewAttachment](https://github.com/MattDrennan/TroopTrackerViewAttachment)
- [TroopTrackerIgnoreUsers](https://github.com/MattDrennan/TroopTrackerIgnoreUsers)
- [TroopTrackerUserGroups](https://github.com/MattDrennan/TroopTrackerUserGroups)
- [Troop Tracker - Upgrade Stats](https://github.com/MattDrennan/Troop-Tracker---Upgrade-Stats)

### 2. Troop Tracker database

All required SQL is included with the Troop Tracker web app install — no additional SQL needed.

### 3. Firebase project setup

The app uses Firebase Cloud Messaging (FCM) for push notifications. You need to create a Firebase
project and add platform-specific config files before building.

**Create a Firebase project:**

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project
   (or use an existing one).
2. Enable **Cloud Messaging** in the project (Project Settings → Cloud Messaging).
3. Add an **Android app** and an **iOS app** to the project.

**Add the config files:**

| Platform | File | Location in project |
|----------|------|---------------------|
| Android | `google-services.json` | `android/app/google-services.json` |
| iOS | `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` |

Download each file from the Firebase Console (Project Settings → Your apps) and place them at the
paths above.

**Regenerate `firebase_options.dart`:**

After placing the config files, regenerate the Dart options file using the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This updates `lib/firebase_options.dart` with your project's keys. Commit the updated file but
**do not commit** the `google-services.json` or `GoogleService-Info.plist` files — they contain
secret keys.

### 4. Tracker URL (required)

The app loads your Troop Tracker instance in a WebView. Set `TRACKER_URL` at build time using
`--dart-define`:

```bash
# Development
flutter run --dart-define=TRACKER_URL=http://localhost:8000/

# Physical device against a local server (use your Mac's LAN IP)
flutter run --dart-define=TRACKER_URL=http://192.168.1.x:8000/

# Production build
flutter build apk --dart-define=TRACKER_URL=https://your-domain.com/troop-tracker/
flutter build ipa --dart-define=TRACKER_URL=https://your-domain.com/troop-tracker/
```

If `TRACKER_URL` is not provided, the app defaults to `http://localhost:8000/`.

The URL must end with a trailing slash. The app derives the trusted domain from this URL
automatically — no other config needed.

### 5. Android signing (release builds only)

Create `android/key.properties`:

```
storeFile=release-key.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

---

## Running the app

```bash
flutter pub get
flutter run --dart-define=TRACKER_URL=https://your-domain.com/troop-tracker/
```

## Generating launcher icons

```bash
dart run flutter_launcher_icons
```

---

## Architecture

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for a full breakdown of the layer structure, providers,
routing, and testing strategy.

---

## License

Free to use, modify, and distribute for **non-commercial purposes**.

---

## Contact

Questions, comments, or concerns: drennanmattheww@gmail.com
