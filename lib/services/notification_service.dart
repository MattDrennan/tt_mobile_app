import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_client.dart';
import 'storage_service.dart';

/// Handles Firebase Messaging initialization, permission requests,
/// FCM token registration, and foreground/tap notification routing.
class NotificationService {
  final StorageService _storage;
  final ApiClient _api;
  final GlobalKey<NavigatorState> navigatorKey;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService({
    required this.navigatorKey,
    required StorageService storage,
    required ApiClient api,
  })  : _storage = storage,
        _api = api;

  // ── Setup ─────────────────────────────────────────────────────────────────

  /// Initializes local notifications and Firebase message listeners.
  /// Call once from the root widget after Firebase is initialized.
  Future<void> initialize() async {
    _initializeLocalNotifications();
    _setupFirebaseListeners();
  }

  void _initializeLocalNotifications() {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    _localNotifications.initialize(settings);
  }

  void _setupFirebaseListeners() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // ── Permission & token ────────────────────────────────────────────────────

  /// Requests notification permissions from the OS.
  Future<void> requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Retrieves the FCM token and registers it with the mobile API.
  /// Should be called after a successful login with the authenticated user ID.
  Future<void> registerFcmToken(String userId) async {
    // On iOS, APNS token must be available before FCM token
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken == null) {
      return; // Push notifications may not work on this device
    }

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    try {
      final response = await _api.postJson(
        _api.mobileApiUri(),
        {
          'action': 'saveFCM',
          'userid': userId,
          'fcm': fcmToken,
        },
      );
      if (response != null) {
        await _storage.saveFcmToken(fcmToken);
      }
    } catch (_) {
      // Non-fatal — the app still works without FCM
    }
  }

  // ── Message handlers ──────────────────────────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      0,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? 'You have a new message.',
      details,
      payload: message.data.toString(),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final threadIdStr = message.data['threadId'];
    final postIdStr = message.data['postId'];
    if (threadIdStr == null || postIdStr == null) return;

    final threadId = int.tryParse(threadIdStr);
    final postId = int.tryParse(postIdStr);
    if (threadId == null || postId == null) return;

    final troopName = message.data['troopName'] as String? ?? 'Unknown';

    Future.delayed(const Duration(milliseconds: 500), () {
      navigatorKey.currentState?.pushNamed(
        '/chat',
        arguments: {
          'troopName': troopName,
          'threadId': threadId,
          'postId': postId,
        },
      );
    });
  }
}
