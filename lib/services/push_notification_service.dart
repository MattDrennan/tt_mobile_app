import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static String? currentToken;

  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    currentToken = await messaging.getToken();
    debugPrint('[FCM] Token: $currentToken');

    messaging.onTokenRefresh.listen((token) {
      debugPrint('[FCM] Token refreshed: $token');
      currentToken = token;
    });
  }
}
