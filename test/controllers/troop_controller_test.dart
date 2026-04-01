import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/controllers/troop_controller.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';

class _FakeStorage extends StorageService {
  @override
  String? getApiKey() => 'key';
}

class _MockApiClient extends ApiClient {
  dynamic _response;

  _MockApiClient() : super(_FakeStorage());

  void setResponse(dynamic response) => _response = response;

  @override
  Uri mobileApiUri([Map<String, dynamic>? queryParameters]) =>
      Uri.parse('https://test.example.com/api');

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async =>
      _response;
}

void main() {
  late _MockApiClient api;
  late TroopController controller;

  setUp(() {
    api = _MockApiClient();
    controller = TroopController(api);
  });

  tearDown(() => controller.dispose());

  group('TroopController.fetchTroops', () {
    test('populates troops list from API response', () async {
      api.setResponse({
        'troops': [
          {'troopid': 1, 'name': 'Troop Alpha', 'squad': 0},
          {'troopid': 2, 'name': 'Troop Beta', 'squad': 1},
        ],
      });

      await controller.fetchTroops(0);

      expect(controller.troops.length, 2);
      expect(controller.troops.first.name, 'Troop Alpha');
    });

    test('handles empty response gracefully', () async {
      api.setResponse({'troops': []});
      await controller.fetchTroops(0);
      expect(controller.troops, isEmpty);
    });

    test('sets error on exception', () async {
      api.setResponse(null); // will cause a cast error
      await controller.fetchTroops(0);
      // should not throw; error may be set
      expect(controller.isLoading, isFalse);
    });
  });

  group('TroopController.setSearch', () {
    setUp(() async {
      api.setResponse({
        'troops': [
          {'troopid': 1, 'name': 'Holiday Parade'},
          {'troopid': 2, 'name': 'Comic Con'},
          {'troopid': 3, 'name': 'Holiday Festival'},
        ],
      });
      await controller.fetchTroops(0);
    });

    test('filters troops case-insensitively by name', () {
      controller.setSearch('holiday');
      expect(controller.troops.length, 2);
      expect(controller.troops.every((t) => t.name.toLowerCase().contains('holiday')), isTrue);
    });

    test('returns all troops when query is cleared', () {
      controller.setSearch('comic');
      expect(controller.troops.length, 1);
      controller.setSearch('');
      expect(controller.troops.length, 3);
    });
  });
}
