import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static String? currentToken;
  static void Function(String url)? _onDeepLink;

  static void setDeepLinkHandler(void Function(String url) handler) {
    _onDeepLink = handler;
  }

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

    // App opened by tapping a notification while in background.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // App launched from a terminated state by tapping a notification.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) _handleMessage(initialMessage);
  }

  static void _handleMessage(RemoteMessage message) {
    final url = message.data['url'] as String?;
    debugPrint('[FCM] notification tapped, url: $url');
    if (url != null) _onDeepLink?.call(url);
  }
}
