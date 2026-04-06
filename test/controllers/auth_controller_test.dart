import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/controllers/auth_controller.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/auth_service.dart';
import 'package:tt_mobile_app/services/storage_service.dart';

// ── Manual mocks ────────────────────────────────────────────────────────────

class _MockStorage extends StorageService {
  String? _userData;
  String? _apiKey;

  @override
  String? getUserData() => _userData;
  @override
  String? getApiKey() => _apiKey;
  @override
  String? getFcmToken() => null;

  @override
  Future<void> saveLoginData(
      {required String userData, required String apiKey}) async {
    _userData = userData;
    _apiKey = apiKey;
  }

  @override
  Future<void> clearAll() async {
    _userData = null;
    _apiKey = null;
  }

  void seedUser(String rawJson) => _userData = rawJson;
}

class _MockAuthService extends AuthService {
  final Map<String, dynamic>? _sessionData;
  bool clearCalled = false;

  _MockAuthService({Map<String, dynamic>? sessionData, StorageService? storage})
      : _sessionData = sessionData,
        super(storage ?? _MockStorage(), ApiClient(storage ?? _MockStorage()));

  @override
  Map<String, dynamic>? restoreSession() => _sessionData;

  @override
  Future<void> clearSession() async {
    clearCalled = true;
  }

  @override
  Future<Map<String, dynamic>> performOAuthLogin() async {
    return {'user_id': '99', 'username': 'TestUser'};
  }
}

class _MockApiClient extends ApiClient {
  dynamic _nextResponse;

  _MockApiClient() : super(_MockStorage());

  void setNextResponse(dynamic response) => _nextResponse = response;

  @override
  Uri mobileApiUri([Map<String, dynamic>? queryParameters]) =>
      Uri.parse('https://test.example.com/api');

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async {
    return _nextResponse;
  }

  @override
  Future<dynamic> postJson(Uri uri, Map<String, dynamic> body,
      {Map<String, String>? headers}) async {
    return _nextResponse;
  }
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('AuthController.restoreSession', () {
    test('sets currentUser when storage has valid user data', () async {
      final authService = _MockAuthService(
        sessionData: {'user_id': '42', 'username': 'Trooper'},
      );
      final storage = _MockStorage();
      final controller =
          AuthController(authService, ApiClient(storage), storage);

      await controller.restoreSession();

      expect(controller.currentUser, isNotNull);
      expect(controller.currentUser!.id, '42');
      expect(controller.currentUser!.username, 'Trooper');
      expect(controller.isLoggedIn, isTrue);
    });

    test('leaves currentUser null when no stored data', () async {
      final authService = _MockAuthService(sessionData: null);
      final storage = _MockStorage();
      final controller =
          AuthController(authService, ApiClient(storage), storage);

      await controller.restoreSession();

      expect(controller.currentUser, isNull);
      expect(controller.isLoggedIn, isFalse);
    });
  });

  group('AuthController.logout', () {
    test('nulls currentUser and sets loggedOut flag', () async {
      final authService = _MockAuthService(
        sessionData: {'user_id': '1', 'username': 'A'},
      );
      final storage = _MockStorage();
      final api = _MockApiClient();
      api.setNextResponse({'success': true});
      final controller = AuthController(authService, api, storage);
      await controller.restoreSession();

      await controller.logout();

      expect(controller.currentUser, isNull);
      expect(controller.isLoggedIn, isFalse);
      expect(controller.loggedOut, isTrue);
      expect(authService.clearCalled, isTrue);
    });
  });

  group('AuthController.fetchSiteStatus', () {
    test('sets siteStatus from API response', () async {
      final storage = _MockStorage();
      final api = _MockApiClient();
      api.setNextResponse({'isWebsiteClosed': 0, 'siteMessage': ''});
      final controller = AuthController(
        _MockAuthService(sessionData: null),
        api,
        storage,
      );

      await controller.fetchSiteStatus();

      expect(controller.siteStatus, isNotNull);
      expect(controller.siteStatus!.isClosed, isFalse);
    });
  });
}
