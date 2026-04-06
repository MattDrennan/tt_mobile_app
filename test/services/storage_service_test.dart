import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tt_mobile_app/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late StorageService storage;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tt_hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('TTMobileApp');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() {
    storage = StorageService();
  });

  tearDown(() async {
    await Hive.box('TTMobileApp').clear();
  });

  // ── Initial state ─────────────────────────────────────────────────────────

  group('StorageService initial state', () {
    test('getUserData returns null before login', () {
      expect(storage.getUserData(), isNull);
    });

    test('getApiKey returns null before login', () {
      expect(storage.getApiKey(), isNull);
    });

    test('getFcmToken returns null before saveFC mToken', () {
      expect(storage.getFcmToken(), isNull);
    });
  });

  // ── saveLoginData ─────────────────────────────────────────────────────────

  group('StorageService.saveLoginData', () {
    test('persists userData and apiKey', () async {
      await storage.saveLoginData(
        userData: '{"user_id": "42"}',
        apiKey: 'secret-key',
      );

      expect(storage.getUserData(), '{"user_id": "42"}');
      expect(storage.getApiKey(), 'secret-key');
    });

    test('overwrites previously saved data', () async {
      await storage.saveLoginData(userData: 'first', apiKey: 'key1');
      await storage.saveLoginData(userData: 'second', apiKey: 'key2');

      expect(storage.getUserData(), 'second');
      expect(storage.getApiKey(), 'key2');
    });
  });

  // ── saveFcmToken ──────────────────────────────────────────────────────────

  group('StorageService.saveFcmToken', () {
    test('persists FCM token', () async {
      await storage.saveFcmToken('fcm-token-abc');
      expect(storage.getFcmToken(), 'fcm-token-abc');
    });

    test('overwrites previously saved token', () async {
      await storage.saveFcmToken('old-token');
      await storage.saveFcmToken('new-token');
      expect(storage.getFcmToken(), 'new-token');
    });
  });

  // ── clearAll ──────────────────────────────────────────────────────────────

  group('StorageService.clearAll', () {
    test('removes userData after clearAll', () async {
      await storage.saveLoginData(userData: 'data', apiKey: 'key');
      await storage.clearAll();
      expect(storage.getUserData(), isNull);
    });

    test('removes apiKey after clearAll', () async {
      await storage.saveLoginData(userData: 'data', apiKey: 'key');
      await storage.clearAll();
      expect(storage.getApiKey(), isNull);
    });

    test('removes FCM token after clearAll', () async {
      await storage.saveFcmToken('token');
      await storage.clearAll();
      expect(storage.getFcmToken(), isNull);
    });

    test('is safe to call on an already empty store', () async {
      await expectLater(storage.clearAll(), completes);
    });
  });

  // ── Key constants ─────────────────────────────────────────────────────────

  group('StorageService key constants', () {
    test('keyUserData is "userData"', () {
      expect(StorageService.keyUserData, 'userData');
    });

    test('keyApiKey is "apiKey"', () {
      expect(StorageService.keyApiKey, 'apiKey');
    });

    test('keyFcm is "fcm"', () {
      expect(StorageService.keyFcm, 'fcm');
    });
  });
}
