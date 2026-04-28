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

### 1. Install the XenForo add-ons

In your XenForo installation, install the following Troop Tracker add-ons:

- [TroopTrackerViewAttachment](https://github.com/MattDrennan/TroopTrackerViewAttachment)
- [TroopTrackerIgnoreUsers](https://github.com/MattDrennan/TroopTrackerIgnoreUsers)
- [TroopTrackerUserGroups](https://github.com/MattDrennan/TroopTrackerUserGroups)
- [Troop Tracker - Upgrade Stats](https://github.com/MattDrennan/Troop-Tracker---Upgrade-Stats)

### 2. Troop Tracker database

All required SQL is included with the Troop Tracker web app install — no additional SQL needed.

### 3. Environment file

Create `.env` in the project root:

```
FORUM_URL=https://www.yourforum.com/boards/
API_USER=1
API_KEY=YOUR_XENFORO_API_KEY
```

### 4. Android signing (release builds only)

Create `android/key.properties`:

```
storeFile=release-key.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

### 5. XenForo webhook (push notifications)

Add a webhook in XenForo admin:

| Field | Value |
|-------|-------|
| Title | Post Insert |
| Target URL | `https://your-domain.com/troop-tracker/script/php/webhook/post_insert.php` |
| Events | `post.insert` only |
| Content type | `application/json` |
| SSL verification | Yes |
| Active | Yes |

### 6. Firebase

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

## Taking screenshots

Automated screenshots use an integration test that runs the app with fixture data (no real credentials or network needed). Screenshots are saved to `screenshots/` in the project root.

**1. Start a simulator**

```bash
# List available emulators
flutter emulators

# Launch one (iOS example)
flutter emulators --launch apple_ios_simulator

# Or list already-running devices
flutter devices
```

**2. Run the screenshot script**

```bash
# Auto-detects the running simulator
scripts/take_screenshots.sh

# Or target a specific device
scripts/take_screenshots.sh "iPhone 16 Pro"
scripts/take_screenshots.sh emulator-5554
```

The script captures 7 screens:

| File | Screen |
|------|--------|
| `00_login.png` | Login |
| `01_home.png` | Home |
| `02_troop_list.png` | Troop list with org filter buttons |
| `03_event.png` | Event detail (roster, shifts, amenities) |
| `04_chat_screen.png` | Chat with messages |
| `05_my_troops.png` | My signed-up troops |
| `06_chat_list.png` | Chat room list |

**Capturing with real data**

The default run uses fake fixture data. To screenshot with live data instead:
1. Run the app normally (`flutter run`) and log in once — the session is persisted locally.
2. In `integration_test/screenshots_test.dart`, comment out the `await _seedSession();` line.
3. Re-run `scripts/take_screenshots.sh`.

> **Note:** On the first iOS run you may see a notification-permission dialog. Grant it and re-run to get clean screenshots.

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

