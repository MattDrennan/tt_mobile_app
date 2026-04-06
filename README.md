# 501st Legion Troop Tracker Mobile App

A Flutter mobile app for tracking **Star Wars costuming events (troops)** for the 501st Legion,
built for the Florida Garrison. Requires a running instance of
[Troop Tracker](https://github.com/obsidianslicers/trooper-tracker) and
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

### 1. XenForo API files

Upload all files in `xenforo_api_files/` to the root of your XenForo installation.

### 2. Install the XenForo add-on

Install the [TroopTrackerViewAttachment](https://github.com/MattDrennan/TroopTrackerViewAttachment)
add-on into XenForo.

### 3. Troop Tracker database

All required SQL is included with the Troop Tracker web app install — no additional SQL needed.

### 4. Environment file

Create `.env` in the project root:

```
FORUM_URL=https://www.yourforum.com/boards/
API_USER=1
API_KEY=YOUR_XENFORO_API_KEY
```

### 5. Android signing (release builds only)

Create `android/key.properties`:

```
storeFile=release-key.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

### 6. XenForo webhook (push notifications)

Add a webhook in XenForo admin:

| Field | Value |
|-------|-------|
| Title | Post Insert |
| Target URL | `https://your-domain.com/troop-tracker/script/php/webhook/post_insert.php` |
| Events | `post.insert` only |
| Content type | `application/json` |
| SSL verification | Yes |
| Active | Yes |

### 7. Firebase

Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the
appropriate platform directories. The app uses Firebase for push notification delivery.

---

## Running the app

```bash
flutter pub get
flutter run
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

