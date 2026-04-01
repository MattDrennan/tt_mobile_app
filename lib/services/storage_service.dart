import 'package:hive/hive.dart';

/// Typed wrapper around the app's Hive box.
/// All key constants live here — no magic strings elsewhere.
class StorageService {
  static const String _boxName = 'TTMobileApp';

  static const String keyUserData = 'userData';
  static const String keyApiKey = 'apiKey';
  static const String keyFcm = 'fcm';

  Box get _box => Hive.box(_boxName);

  // ── Getters ──────────────────────────────────────────────────────────────

  /// JSON-encoded user data saved at login.
  String? getUserData() => _box.get(keyUserData) as String?;

  /// API key for mobile-api requests.
  String? getApiKey() => _box.get(keyApiKey) as String?;

  /// FCM token for push notifications.
  String? getFcmToken() => _box.get(keyFcm) as String?;

  // ── Setters ──────────────────────────────────────────────────────────────

  /// Persists user data and API key received from a successful login.
  Future<void> saveLoginData({
    required String userData,
    required String apiKey,
  }) async {
    await _box.put(keyUserData, userData);
    await _box.put(keyApiKey, apiKey);
  }

  /// Persists the FCM registration token.
  Future<void> saveFcmToken(String token) async {
    await _box.put(keyFcm, token);
  }

  /// Clears all persisted data (logout).
  Future<void> clearAll() async {
    await _box.clear();
  }
}
