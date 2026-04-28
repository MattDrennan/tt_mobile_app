// Entry point used exclusively by integration_test/screenshots_test.dart.
// Identical to main.dart but injects FakeApiClient so screens render with
// canned fixture data instead of making real network calls.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'firebase_options.dart';
import 'main.dart' show navigatorKey, TroopTrackerApp;
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/fake_api_client.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  await Hive.openBox('TTMobileApp');

  final storage = StorageService();
  final ApiClient api = FakeApiClient(storage);
  final authService = AuthService(storage, api);
  final authController = AuthController(authService, api, storage);

  final notificationService = NotificationService(
    navigatorKey: navigatorKey,
    storage: storage,
    api: api,
  );
  authController.setNotificationService(notificationService);

  await authController.restoreSession();
  await notificationService.requestPermissions();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        Provider<ApiClient>.value(value: api),
      ],
      child: TroopTrackerApp(navigatorKey: navigatorKey),
    ),
  );
}
