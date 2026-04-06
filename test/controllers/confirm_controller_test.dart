import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/controllers/confirm_controller.dart';
import 'package:tt_mobile_app/models/costume.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

Map<String, dynamic> _troopJson({int troopid = 1, String name = 'Troop One'}) =>
    {'troopid': troopid, 'name': name};

Map<String, dynamic> _costumeJson({
  int id = 5,
  String name = 'Stormtrooper',
}) =>
    {'id': id, 'abbreviation': '', 'name': name};

// ── Manual mocks ──────────────────────────────────────────────────────────────

class _FakeStorage extends StorageService {
  @override
  String? getApiKey() => 'test-key';
}

/// Queue-based mock: responses are consumed FIFO; falls back to [_default].
/// Enqueue an [Exception] instance to simulate a thrown exception.
class _MockApiClient extends ApiClient {
  final _queue = <dynamic>[];
  dynamic _default;

  _MockApiClient() : super(_FakeStorage());

  void enqueue(dynamic r) => _queue.add(r);
  void setDefault(dynamic r) => _default = r;
  void enqueueThrow(Exception e) => _queue.add(_Throws(e));

  @override
  Uri mobileApiUri([Map<String, dynamic>? queryParameters]) =>
      Uri.parse('https://test.example.com/api');

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async {
    final item = _queue.isNotEmpty ? _queue.removeAt(0) : _default;
    if (item is _Throws) throw item.exception;
    return item;
  }
}

class _Throws {
  final Exception exception;
  _Throws(this.exception);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockApiClient api;
  late ConfirmController controller;

  setUp(() {
    api = _MockApiClient();
    controller = ConfirmController(api, trooperId: 42);
  });

  tearDown(() => controller.dispose());

  // ── Initial state ────────────────────────────────────────────────────────

  group('ConfirmController initial state', () {
    test('isLoading is true (loads on creation)', () {
      expect(controller.isLoading, isTrue);
    });

    test('troops is empty', () {
      expect(controller.troops, isEmpty);
    });

    test('selectedTroopIds is empty', () {
      expect(controller.selectedTroopIds, isEmpty);
    });

    test('selectedCostume is null', () {
      expect(controller.selectedCostume, isNull);
    });

    test('isSubmitting is false', () {
      expect(controller.isSubmitting, isFalse);
    });

    test('error is null', () {
      expect(controller.error, isNull);
    });
  });

  // ── fetchTroops ──────────────────────────────────────────────────────────

  group('ConfirmController.fetchTroops', () {
    test('populates troops from API response', () async {
      api.setDefault({
        'troops': [
          _troopJson(troopid: 1, name: 'Holiday Parade'),
          _troopJson(troopid: 2, name: 'Comic Con'),
        ],
      });

      await controller.fetchTroops();

      expect(controller.troops.length, 2);
      expect(controller.troops.first['name'], 'Holiday Parade');
    });

    test('sets troops to empty list when API returns empty troops', () async {
      api.setDefault({'troops': []});

      await controller.fetchTroops();

      expect(controller.troops, isEmpty);
    });

    test('sets troops to empty when troops key is missing', () async {
      api.setDefault(<String, dynamic>{});

      await controller.fetchTroops();

      expect(controller.troops, isEmpty);
    });

    test('sets error on exception', () async {
      api.setDefault(null); // causes cast exception

      await controller.fetchTroops();

      expect(controller.error, isNotNull);
    });

    test('sets isLoading to false after completion', () async {
      api.setDefault({'troops': []});

      await controller.fetchTroops();

      expect(controller.isLoading, isFalse);
    });

    test('sets isLoading to false even when API throws', () async {
      api.setDefault(null);

      await controller.fetchTroops();

      expect(controller.isLoading, isFalse);
    });

    test('notifies listeners at least twice (start and end)', () async {
      api.setDefault({'troops': []});
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.fetchTroops();

      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });

  // ── fetchCostumes ────────────────────────────────────────────────────────

  group('ConfirmController.fetchCostumes', () {
    test('returns list of Costumes from API', () async {
      api.setDefault([
        _costumeJson(id: 1, name: 'Stormtrooper'),
        _costumeJson(id: 2, name: 'Vader'),
      ]);

      final result = await controller.fetchCostumes(null);

      expect(result.length, 2);
      expect(result.first.name, 'Stormtrooper');
    });

    test('returns empty list when API returns null', () async {
      api.setDefault(null);

      final result = await controller.fetchCostumes(null);

      expect(result, isEmpty);
    });

    test('returns empty list when API returns empty array', () async {
      api.setDefault([]);

      final result = await controller.fetchCostumes(null);

      expect(result, isEmpty);
    });
  });

  // ── selectCostume ────────────────────────────────────────────────────────

  group('ConfirmController.selectCostume', () {
    test('updates selectedCostume', () {
      final costume = Costume(id: 5, name: 'Stormtrooper');
      controller.selectCostume(costume);
      expect(controller.selectedCostume, costume);
    });

    test('accepts null to clear selection', () {
      controller.selectCostume(Costume(id: 5, name: 'Stormtrooper'));
      controller.selectCostume(null);
      expect(controller.selectedCostume, isNull);
    });

    test('notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.selectCostume(Costume(id: 5, name: 'Stormtrooper'));
      expect(notified, isTrue);
    });
  });

  // ── toggleTroop ──────────────────────────────────────────────────────────

  group('ConfirmController.toggleTroop', () {
    test('adds troopId when selected is true', () {
      controller.toggleTroop(10, true);
      expect(controller.selectedTroopIds, contains(10));
    });

    test('removes troopId when selected is false', () {
      controller.toggleTroop(10, true);
      controller.toggleTroop(10, false);
      expect(controller.selectedTroopIds, isNot(contains(10)));
    });

    test('can select multiple troops', () {
      controller.toggleTroop(1, true);
      controller.toggleTroop(2, true);
      controller.toggleTroop(3, true);
      expect(controller.selectedTroopIds.length, 3);
    });

    test('deselecting non-selected troop is a no-op', () {
      controller.toggleTroop(99, false);
      expect(controller.selectedTroopIds, isEmpty);
    });

    test('notifies listeners on selection change', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.toggleTroop(1, true);
      expect(notified, isTrue);
    });
  });

  // ── confirmAttendance ────────────────────────────────────────────────────

  group('ConfirmController.confirmAttendance', () {
    test('returns false when no troops are selected', () async {
      controller.selectCostume(Costume(id: 5, name: 'Stormtrooper'));

      final result = await controller.confirmAttendance();

      expect(result, isFalse);
    });

    test('returns false when no costume is selected', () async {
      api.setDefault({'troops': [_troopJson()]});
      await controller.fetchTroops();
      controller.toggleTroop(1, true);

      final result = await controller.confirmAttendance();

      expect(result, isFalse);
    });

    test('confirms all selected troops successfully', () async {
      api.setDefault({'troops': [_troopJson(troopid: 1), _troopJson(troopid: 2)]});
      await controller.fetchTroops();
      controller.toggleTroop(1, true);
      controller.toggleTroop(2, true);
      controller.selectCostume(Costume(id: 5, name: 'Stormtrooper'));

      // One API call per selected troop
      api.enqueue({'success': true});
      api.enqueue({'success': true});

      final result = await controller.confirmAttendance();

      expect(result, isTrue);
    });

    test('removes confirmed troops from list', () async {
      api.setDefault({
        'troops': [
          _troopJson(troopid: 1),
          _troopJson(troopid: 2),
        ],
      });
      await controller.fetchTroops();
      controller.toggleTroop(1, true);
      controller.selectCostume(Costume(id: 5, name: 'Stormtrooper'));

      api.enqueue({'success': true});

      await controller.confirmAttendance();

      expect(controller.troops.length, 1);
      expect(controller.troops.first['troopid'], 2);
    });

    test('clears selectedTroopIds after success', () async {
      api.setDefault({'troops': [_troopJson(troopid: 1)]});
      await controller.fetchTroops();
      controller.toggleTroop(1, true);
      controller.selectCostume(Costume(id: 5, name: 'Stormtrooper'));

      api.enqueue({'success': true});

      await controller.confirmAttendance();

      expect(controller.selectedTroopIds, isEmpty);
    });

    test('sets error and returns false on exception', () async {
      api.setDefault({'troops': [_troopJson(troopid: 1)]});
      await controller.fetchTroops();
      controller.toggleTroop(1, true);
      controller.selectCostume(Costume(id: 5, name: 'Stormtrooper'));

      api.enqueueThrow(Exception('network error'));

      final result = await controller.confirmAttendance();

      expect(result, isFalse);
      expect(controller.error, isNotNull);
    });

    test('sets isSubmitting to false after completion', () async {
      api.setDefault({'troops': [_troopJson(troopid: 1)]});
      await controller.fetchTroops();
      controller.toggleTroop(1, true);
      controller.selectCostume(Costume(id: 5, name: 'Stormtrooper'));

      api.enqueue({'success': true});

      await controller.confirmAttendance();

      expect(controller.isSubmitting, isFalse);
    });
  });

  // ── adviseNoShow ─────────────────────────────────────────────────────────

  group('ConfirmController.adviseNoShow', () {
    test('returns false when no troops are selected', () async {
      final result = await controller.adviseNoShow();
      expect(result, isFalse);
    });

    test('marks selected troops as no-show successfully', () async {
      api.setDefault({'troops': [_troopJson(troopid: 1), _troopJson(troopid: 2)]});
      await controller.fetchTroops();
      controller.toggleTroop(1, true);
      controller.toggleTroop(2, true);

      api.enqueue({'success': true});
      api.enqueue({'success': true});

      final result = await controller.adviseNoShow();

      expect(result, isTrue);
    });

    test('removes no-show troops from list', () async {
      api.setDefault({
        'troops': [
          _troopJson(troopid: 1),
          _troopJson(troopid: 2),
        ],
      });
      await controller.fetchTroops();
      controller.toggleTroop(1, true);

      api.enqueue({'success': true});

      await controller.adviseNoShow();

      expect(controller.troops.length, 1);
      expect(controller.troops.first['troopid'], 2);
    });

    test('does not require costume selection', () async {
      api.setDefault({'troops': [_troopJson(troopid: 1)]});
      await controller.fetchTroops();
      controller.toggleTroop(1, true);
      // No costume selected

      api.enqueue({'success': true});

      final result = await controller.adviseNoShow();

      expect(result, isTrue);
    });

    test('sets isSubmitting to false after completion', () async {
      api.setDefault({'troops': [_troopJson(troopid: 1)]});
      await controller.fetchTroops();
      controller.toggleTroop(1, true);

      api.enqueue({'success': true});

      await controller.adviseNoShow();

      expect(controller.isSubmitting, isFalse);
    });
  });
}
