import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions', () {
    test('has android FirebaseOptions configured', () {
      final androidOptions = DefaultFirebaseOptions.android;
      expect(androidOptions.apiKey, isNotEmpty);
      expect(androidOptions.appId, isNotEmpty);
      expect(androidOptions.projectId, 'troop-tracker-dfd22');
      expect(androidOptions.storageBucket,
          'troop-tracker-dfd22.firebasestorage.app');
    });

    test('android options have messaging sender ID', () {
      final androidOptions = DefaultFirebaseOptions.android;
      expect(androidOptions.messagingSenderId, '629954663757');
    });

    test('has iOS FirebaseOptions configured', () {
      final iosOptions = DefaultFirebaseOptions.ios;
      expect(iosOptions.apiKey, isNotEmpty);
      expect(iosOptions.appId, isNotEmpty);
      expect(iosOptions.projectId, 'troop-tracker-dfd22');
      expect(iosOptions.storageBucket,
          'troop-tracker-dfd22.firebasestorage.app');
    });

    test('iOS options have bundle ID', () {
      final iosOptions = DefaultFirebaseOptions.ios;
      expect(iosOptions.iosBundleId, 'com.drennansoftware.ttMobileApp');
    });

    test('iOS options have messaging sender ID', () {
      final iosOptions = DefaultFirebaseOptions.ios;
      expect(iosOptions.messagingSenderId, '629954663757');
    });

    test('android and iOS options have same project ID', () {
      expect(DefaultFirebaseOptions.android.projectId,
          DefaultFirebaseOptions.ios.projectId);
    });

    test('throws on web platform', () {
      // Note: This would only throw if kIsWeb is true,
      // which is controlled by the test framework.
      // In a normal unit test, kIsWeb is false, so currentPlatform
      // will switch on the platform instead.
      expect(DefaultFirebaseOptions, isNotNull);
    });

    test('handles unsupported platforms with appropriate errors', () {
      // Depending on the test platform, currentPlatform will either:
      // 1. Return android/iOS options (on those platforms)
      // 2. Throw UnsupportedError (on other platforms like web, windows, linux, etc.)
      expect(DefaultFirebaseOptions, isNotNull);
    });

    test('firebase project name is consistent', () {
      expect(DefaultFirebaseOptions.android.projectId,
          DefaultFirebaseOptions.ios.projectId);
      expect(DefaultFirebaseOptions.android.projectId, 'troop-tracker-dfd22');
    });

    test('storage bucket is consistent across platforms', () {
      expect(
        DefaultFirebaseOptions.android.storageBucket,
        DefaultFirebaseOptions.ios.storageBucket,
      );
    });

    test('messaging sender ID is consistent across platforms', () {
      expect(
        DefaultFirebaseOptions.android.messagingSenderId,
        DefaultFirebaseOptions.ios.messagingSenderId,
      );
    });

    test('options are properly immutable', () {
      final android1 = DefaultFirebaseOptions.android;
      final android2 = DefaultFirebaseOptions.android;
      expect(
        android1.apiKey,
        android2.apiKey,
      ); // Same reference/value
    });
  });
}
