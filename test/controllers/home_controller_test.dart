import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/controllers/home_controller.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';

// ── Manual mocks ──────────────────────────────────────────────────────────────

class _FakeStorage extends StorageService {
  @override
  String? getApiKey() => 'test-key';
}

class _MockApiClient extends ApiClient {
  dynamic _response;

  _MockApiClient() : super(_FakeStorage());

  void setResponse(dynamic r) => _response = r;

  @override
  Uri mobileApiUri([Map<String, dynamic>? queryParameters]) =>
      Uri.parse('https://test.example.com/api');

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async =>
      _response;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockApiClient api;
  late HomeController controller;

  setUp(() {
    api = _MockApiClient();
    controller = HomeController(api, trooperId: 42);
  });

  tearDown(() => controller.dispose());

  // ── Initial state ────────────────────────────────────────────────────────

  group('HomeController initial state', () {
    test('is not loading', () {
      expect(controller.isLoading, isFalse);
    });

    test('hasUnconfirmedTroops is false', () {
      expect(controller.hasUnconfirmedTroops, isFalse);
    });
  });

  // ── checkUnconfirmedTroops ───────────────────────────────────────────────

  group('HomeController.checkUnconfirmedTroops', () {
    test('sets hasUnconfirmedTroops to true when troops list is non-empty',
        () async {
      api.setResponse({
        'troops': [
          {'troopid': 1, 'name': 'Holiday Parade'},
        ],
      });

      await controller.checkUnconfirmedTroops();

      expect(controller.hasUnconfirmedTroops, isTrue);
    });

    test('sets hasUnconfirmedTroops to false when troops list is empty',
        () async {
      api.setResponse({'troops': []});

      await controller.checkUnconfirmedTroops();

      expect(controller.hasUnconfirmedTroops, isFalse);
    });

    test('sets hasUnconfirmedTroops to false when troops key is missing',
        () async {
      api.setResponse(<String, dynamic>{});

      await controller.checkUnconfirmedTroops();

      expect(controller.hasUnconfirmedTroops, isFalse);
    });

    test('sets hasUnconfirmedTroops to false when troops is not a List',
        () async {
      api.setResponse({'troops': 'invalid'});

      await controller.checkUnconfirmedTroops();

      expect(controller.hasUnconfirmedTroops, isFalse);
    });

    test('sets hasUnconfirmedTroops to false on API exception', () async {
      api.setResponse(null); // null cast error

      await controller.checkUnconfirmedTroops();

      expect(controller.hasUnconfirmedTroops, isFalse);
    });

    test('sets isLoading to false after completion', () async {
      api.setResponse({'troops': []});

      await controller.checkUnconfirmedTroops();

      expect(controller.isLoading, isFalse);
    });

    test('sets isLoading to false even when API throws', () async {
      api.setResponse(null);

      await controller.checkUnconfirmedTroops();

      expect(controller.isLoading, isFalse);
    });

    test('notifies listeners twice: once on start and once on completion',
        () async {
      api.setResponse({'troops': []});
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.checkUnconfirmedTroops();

      expect(notifyCount, 2);
    });

    test('transitions hasUnconfirmedTroops from true to false on re-check',
        () async {
      api.setResponse({
        'troops': [
          {'troopid': 1, 'name': 'Event One'},
        ],
      });
      await controller.checkUnconfirmedTroops();
      expect(controller.hasUnconfirmedTroops, isTrue);

      api.setResponse({'troops': []});
      await controller.checkUnconfirmedTroops();
      expect(controller.hasUnconfirmedTroops, isFalse);
    });
  });
}
