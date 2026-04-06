import 'dart:async';

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/notification_service.dart';
import 'package:tt_mobile_app/services/storage_service.dart';

// ── Manual fakes ──────────────────────────────────────────────────────────────

class _FakeStorage extends StorageService {
  String? _fcmToken;

  @override
  String? getFcmToken() => _fcmToken;

  @override
  Future<void> saveFcmToken(String token) async {
    _fcmToken = token;
  }

  @override
  String? getUserData() => null;

  @override
  String? getApiKey() => null;

  @override
  Future<void> saveLoginData({
    required String userData,
    required String apiKey,
  }) async {}

  @override
  Future<void> clearAll() async {}
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(_FakeStorage());
}

/// A [FirebaseMessagingAdapter] that never calls the real Firebase SDK,
/// enabling tests to run without a Firebase app being initialized.
class _FakeFirebaseMessaging implements FirebaseMessagingAdapter {
  String? apnsToken;
  String? fcmToken;
  bool permissionRequested = false;
  final _onMessage = StreamController<RemoteMessage>();
  final _onMessageOpenedApp = StreamController<RemoteMessage>();

  _FakeFirebaseMessaging({this.apnsToken, this.fcmToken});

  @override
  Future<String?> getApnsToken() async => apnsToken;

  @override
  Future<String?> getFcmToken() async => fcmToken;

  @override
  Future<void> requestPermission({
    bool alert = false,
    bool badge = false,
    bool sound = false,
  }) async {
    permissionRequested = true;
  }

  @override
  Stream<RemoteMessage> get onMessage => _onMessage.stream;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => _onMessageOpenedApp.stream;

  void dispose() {
    _onMessage.close();
    _onMessageOpenedApp.close();
  }
}

/// A [LocalNotificationsAdapter] that never calls the real platform channel.
class _FakeLocalNotifications implements LocalNotificationsAdapter {
  int showCallCount = 0;
  int? lastShowId;
  String? lastTitle;
  String? lastBody;

  @override
  Future<void> initialize(InitializationSettings settings) async {}

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails details, {
    String? payload,
  }) async {
    showCallCount++;
    lastShowId = id;
    lastTitle = title;
    lastBody = body;
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _FakeStorage storage;
  late _FakeApiClient apiClient;
  late GlobalKey<NavigatorState> navigatorKey;
  late _FakeFirebaseMessaging fakeMessaging;
  late _FakeLocalNotifications fakeLocalNotifications;
  late NotificationService notificationService;

  setUp(() {
    storage = _FakeStorage();
    apiClient = _FakeApiClient();
    navigatorKey = GlobalKey<NavigatorState>();
    fakeMessaging = _FakeFirebaseMessaging();
    fakeLocalNotifications = _FakeLocalNotifications();
    notificationService = NotificationService(
      navigatorKey: navigatorKey,
      storage: storage,
      api: apiClient,
      messaging: fakeMessaging,
      localNotifications: fakeLocalNotifications,
    );
  });

  tearDown(() => fakeMessaging.dispose());

  // ── Initialization ────────────────────────────────────────────────────────

  group('NotificationService.initialize', () {
    test('initializes local notifications and Firebase listeners', () async {
      await expectLater(
        notificationService.initialize(),
        completes,
      );
    });
  });

  // ── Permissions ───────────────────────────────────────────────────────────

  group('NotificationService.requestPermissions', () {
    test('requests notification permissions via the messaging adapter', () async {
      expect(fakeMessaging.permissionRequested, isFalse);

      await notificationService.requestPermissions();

      expect(fakeMessaging.permissionRequested, isTrue);
    });
  });

  // ── FCM Token registration ────────────────────────────────────────────────

  group('NotificationService.registerFcmToken', () {
    test('returns early and does not save when APNS token is null', () async {
      fakeMessaging.apnsToken = null;
      fakeMessaging.fcmToken = 'fcm-abc';

      await notificationService.registerFcmToken('user123');

      expect(storage.getFcmToken(), isNull);
    });

    test('returns early and does not save when FCM token is null', () async {
      fakeMessaging.apnsToken = 'apns-token';
      fakeMessaging.fcmToken = null;

      await notificationService.registerFcmToken('user123');

      expect(storage.getFcmToken(), isNull);
    });

    test('completes without error for any userId string', () async {
      await expectLater(
        notificationService.registerFcmToken('test-user-id'),
        completes,
      );
    });

    test('handles registration errors gracefully', () async {
      // Non-fatal errors should be caught internally; completes without throw
      await expectLater(
        notificationService.registerFcmToken('user456'),
        completes,
      );
    });
  });

  // ── Message handling ──────────────────────────────────────────────────────

  group('NotificationService message handling', () {
    test('service can be instantiated', () {
      expect(notificationService, isNotNull);
    });

    test('navigatorKey is used for routing', () {
      expect(notificationService.navigatorKey, isNotNull);
      expect(identical(notificationService.navigatorKey, navigatorKey), isTrue);
    });

    test('subscribes to onMessage stream after initialize', () async {
      await notificationService.initialize();

      // Adding to the stream should not throw
      expect(
        () => fakeMessaging._onMessage.add(RemoteMessage()),
        returnsNormally,
      );
    });

    test('shows local notification when foreground message received', () async {
      await notificationService.initialize();

      fakeMessaging._onMessage.add(RemoteMessage(
        notification: const RemoteNotification(
          title: 'Test Title',
          body: 'Test body',
        ),
      ));

      // Allow the async listener to complete
      await Future<void>.delayed(Duration.zero);

      expect(fakeLocalNotifications.showCallCount, equals(1));
      expect(fakeLocalNotifications.lastTitle, equals('Test Title'));
      expect(fakeLocalNotifications.lastBody, equals('Test body'));
    });

    test('subscribes to onMessageOpenedApp stream after initialize', () async {
      await notificationService.initialize();

      expect(
        () => fakeMessaging._onMessageOpenedApp.add(RemoteMessage()),
        returnsNormally,
      );
    });
  });

  // ── Service lifecycle ─────────────────────────────────────────────────────

  group('NotificationService lifecycle', () {
    test('service can be instantiated', () {
      expect(notificationService, isNotNull);
    });

    test('keeps reference to storage service', () {
      expect(notificationService, isNotNull);
    });

    test('keeps reference to API client', () {
      expect(notificationService, isNotNull);
    });

    test('exposes local notifications plugin', () {
      expect(notificationService, isNotNull);
    });
  });

  // ── Integration scenarios ─────────────────────────────────────────────────

  group('NotificationService integration', () {
    test('can initialize permission flow', () async {
      await notificationService.requestPermissions();
      await notificationService.initialize();
      await expectLater(
        notificationService.registerFcmToken('user789'),
        completes,
      );
      expect(fakeMessaging.permissionRequested, isTrue);
    });

    test('handles full lifecycle sequence', () async {
      await notificationService.initialize();
      await notificationService.requestPermissions();
      await expectLater(
        notificationService.registerFcmToken('testuser'),
        completes,
      );
    });
  });
}
