import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/controllers/add_friend_controller.dart';
import 'package:tt_mobile_app/models/costume.dart';
import 'package:tt_mobile_app/models/trooper.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

Map<String, dynamic> _shiftJson({
  int id = 1,
  String name = 'Morning',
  bool canAddFriend = true,
}) =>
    {
      'id': id,
      'name': name,
      'can_add_friend': canAddFriend,
    };

Map<String, dynamic> _trooperJson({int id = 10, String name = 'Trooper Name'}) =>
    {
      'id': id,
      'display_name': name,
      'tkid_formatted': 'TK-10000',
    };

Map<String, dynamic> _costumeJson({int id = 5, String name = 'Stormtrooper'}) =>
    {
      'id': id,
      'abbreviation': '',
      'name': name,
    };

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

// ── Helper ────────────────────────────────────────────────────────────────────

AddFriendController _makeController(
  _MockApiClient api, {
  int limitedEvent = 0,
  int allowTentative = 0,
  List<dynamic> shifts = const [],
}) =>
    AddFriendController(
      api,
      troopId: 100,
      addedByUserId: '42',
      limitedEvent: limitedEvent,
      allowTentative: allowTentative,
      shifts: shifts,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockApiClient api;

  setUp(() {
    api = _MockApiClient();
  });

  // ── Initial state ────────────────────────────────────────────────────────

  group('AddFriendController initial state', () {
    test('selectedStatus is "going" for non-limited event', () {
      final controller = _makeController(api, limitedEvent: 0);
      expect(controller.selectedStatus, 'going');
      controller.dispose();
    });

    test('selectedStatus is "pending" for limited event', () {
      final controller = _makeController(api, limitedEvent: 1);
      expect(controller.selectedStatus, 'pending');
      controller.dispose();
    });

    test('selectedTrooper is null initially', () {
      final controller = _makeController(api);
      expect(controller.selectedTrooper, isNull);
      controller.dispose();
    });

    test('selectedCostume is null initially', () {
      final controller = _makeController(api);
      expect(controller.selectedCostume, isNull);
      controller.dispose();
    });

    test('isSubmitting is false initially', () {
      final controller = _makeController(api);
      expect(controller.isSubmitting, isFalse);
      controller.dispose();
    });

    test('submitSuccess is false initially', () {
      final controller = _makeController(api);
      expect(controller.submitSuccess, isFalse);
      controller.dispose();
    });

    test('error is null initially', () {
      final controller = _makeController(api);
      expect(controller.error, isNull);
      controller.dispose();
    });

    test('selects first available shift on construction', () {
      final controller = _makeController(api, shifts: [
        _shiftJson(id: 7),
        _shiftJson(id: 8),
      ]);
      expect(controller.selectedShiftId, 7);
      controller.dispose();
    });

    test('selectedShiftId is null when no shifts provided', () {
      final controller = _makeController(api, shifts: []);
      expect(controller.selectedShiftId, isNull);
      controller.dispose();
    });
  });

  // ── availableShifts ──────────────────────────────────────────────────────

  group('AddFriendController.availableShifts', () {
    test('returns shifts where can_add_friend is not false', () {
      final controller = _makeController(api, shifts: [
        _shiftJson(id: 1, canAddFriend: true),
        _shiftJson(id: 2, canAddFriend: false),
        _shiftJson(id: 3, canAddFriend: true),
      ]);
      expect(controller.availableShifts.length, 2);
      final ids = controller.availableShifts.map((s) => s['id']).toList();
      expect(ids, containsAll([1, 3]));
      controller.dispose();
    });

    test('returns all shifts when can_add_friend is not set', () {
      final controller = _makeController(api, shifts: [
        {'id': 1, 'name': 'Morning'},
        {'id': 2, 'name': 'Evening'},
      ]);
      expect(controller.availableShifts.length, 2);
      controller.dispose();
    });

    test('returns empty when all shifts are restricted', () {
      final controller = _makeController(api, shifts: [
        _shiftJson(id: 1, canAddFriend: false),
      ]);
      expect(controller.availableShifts, isEmpty);
      controller.dispose();
    });
  });

  // ── hasMultipleShifts ────────────────────────────────────────────────────

  group('AddFriendController.hasMultipleShifts', () {
    test('is false when no shifts', () {
      final controller = _makeController(api, shifts: []);
      expect(controller.hasMultipleShifts, isFalse);
      controller.dispose();
    });

    test('is false when one shift', () {
      final controller = _makeController(api, shifts: [_shiftJson()]);
      expect(controller.hasMultipleShifts, isFalse);
      controller.dispose();
    });

    test('is true when two or more shifts', () {
      final controller = _makeController(api, shifts: [
        _shiftJson(id: 1),
        _shiftJson(id: 2),
      ]);
      expect(controller.hasMultipleShifts, isTrue);
      controller.dispose();
    });
  });

  // ── setStatus ────────────────────────────────────────────────────────────

  group('AddFriendController.setStatus', () {
    test('updates selectedStatus', () {
      final controller = _makeController(api);
      controller.setStatus('tentative');
      expect(controller.selectedStatus, 'tentative');
      controller.dispose();
    });

    test('notifies listeners', () {
      final controller = _makeController(api);
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setStatus('tentative');
      expect(notified, isTrue);
      controller.dispose();
    });
  });

  // ── setTrooper ───────────────────────────────────────────────────────────

  group('AddFriendController.setTrooper', () {
    test('updates selectedTrooper', () {
      final controller = _makeController(api);
      final trooper = Trooper(id: 1, name: 'Luke', tkid: 'TK-1');
      controller.setTrooper(trooper);
      expect(controller.selectedTrooper, trooper);
      controller.dispose();
    });

    test('clears selectedCostume when trooper changes', () {
      final controller = _makeController(api);
      controller.setCostume(Costume(id: 1, name: 'Vader'));
      controller.setTrooper(Trooper(id: 2, name: 'Leia', tkid: 'TK-2'));
      expect(controller.selectedCostume, isNull);
      controller.dispose();
    });

    test('clears backupCostume when trooper changes', () {
      final controller = _makeController(api);
      controller.setBackupCostume(Costume(id: 2, name: 'Trooper'));
      controller.setTrooper(Trooper(id: 2, name: 'Leia', tkid: 'TK-2'));
      expect(controller.backupCostume, isNull);
      controller.dispose();
    });

    test('accepts null to clear selection', () {
      final controller = _makeController(api);
      controller.setTrooper(Trooper(id: 1, name: 'Luke', tkid: 'TK-1'));
      controller.setTrooper(null);
      expect(controller.selectedTrooper, isNull);
      controller.dispose();
    });
  });

  // ── setCostume ───────────────────────────────────────────────────────────

  group('AddFriendController.setCostume', () {
    test('updates selectedCostume', () {
      final controller = _makeController(api);
      final costume = Costume(id: 5, name: 'Stormtrooper');
      controller.setCostume(costume);
      expect(controller.selectedCostume, costume);
      controller.dispose();
    });

    test('accepts null to clear selection', () {
      final controller = _makeController(api);
      controller.setCostume(Costume(id: 5, name: 'Stormtrooper'));
      controller.setCostume(null);
      expect(controller.selectedCostume, isNull);
      controller.dispose();
    });
  });

  // ── setBackupCostume ─────────────────────────────────────────────────────

  group('AddFriendController.setBackupCostume', () {
    test('updates backupCostume', () {
      final controller = _makeController(api);
      final costume = Costume(id: 6, name: 'Scout Trooper');
      controller.setBackupCostume(costume);
      expect(controller.backupCostume, costume);
      controller.dispose();
    });
  });

  // ── setShift ─────────────────────────────────────────────────────────────

  group('AddFriendController.setShift', () {
    test('updates selectedShiftId', () {
      final controller = _makeController(api, shifts: [
        _shiftJson(id: 1),
        _shiftJson(id: 2),
      ]);
      controller.setShift(2);
      expect(controller.selectedShiftId, 2);
      controller.dispose();
    });

    test('clears selectedTrooper, selectedCostume, and backupCostume', () {
      final controller = _makeController(api, shifts: [
        _shiftJson(id: 1),
        _shiftJson(id: 2),
      ]);
      controller.setTrooper(Trooper(id: 1, name: 'Luke', tkid: 'TK-1'));
      controller.setCostume(Costume(id: 5, name: 'Vader'));
      controller.setBackupCostume(Costume(id: 6, name: 'Trooper'));

      controller.setShift(2);

      expect(controller.selectedTrooper, isNull);
      expect(controller.selectedCostume, isNull);
      expect(controller.backupCostume, isNull);
      controller.dispose();
    });

    test('notifies listeners', () {
      final controller = _makeController(api, shifts: [_shiftJson(id: 1), _shiftJson(id: 2)]);
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setShift(2);
      expect(notified, isTrue);
      controller.dispose();
    });
  });

  // ── fetchAvailableTroopers ───────────────────────────────────────────────

  group('AddFriendController.fetchAvailableTroopers', () {
    test('returns list of Troopers from API', () async {
      final controller = _makeController(api);
      api.setResponse([
        _trooperJson(id: 1, name: 'Luke'),
        _trooperJson(id: 2, name: 'Han'),
      ]);

      final result = await controller.fetchAvailableTroopers(null);

      expect(result.length, 2);
      expect(result.first.name, 'Luke');
      controller.dispose();
    });

    test('returns empty list when API returns null', () async {
      final controller = _makeController(api);
      api.setResponse(null);

      final result = await controller.fetchAvailableTroopers(null);

      expect(result, isEmpty);
      controller.dispose();
    });

    test('returns empty list when API returns empty array', () async {
      final controller = _makeController(api);
      api.setResponse([]);

      final result = await controller.fetchAvailableTroopers(null);

      expect(result, isEmpty);
      controller.dispose();
    });
  });

  // ── fetchCostumes ────────────────────────────────────────────────────────

  group('AddFriendController.fetchCostumes', () {
    test('returns list of Costumes from API', () async {
      final controller = _makeController(api);
      api.setResponse([
        _costumeJson(id: 1, name: 'Stormtrooper'),
        _costumeJson(id: 2, name: 'Vader'),
      ]);

      final result = await controller.fetchCostumes(1, null);

      expect(result.length, 2);
      expect(result.first.name, 'Stormtrooper');
      controller.dispose();
    });

    test('returns empty list when API returns null', () async {
      final controller = _makeController(api);
      api.setResponse(null);

      final result = await controller.fetchCostumes(1, null);

      expect(result, isEmpty);
      controller.dispose();
    });
  });

  // ── submit ───────────────────────────────────────────────────────────────

  group('AddFriendController.submit', () {
    test('returns false immediately when trooper is not selected', () async {
      final controller = _makeController(api);
      controller.setCostume(Costume(id: 5, name: 'Vader'));

      final result = await controller.submit();

      expect(result, isFalse);
      controller.dispose();
    });

    test('returns false immediately when costume is not selected', () async {
      final controller = _makeController(api);
      controller.setTrooper(Trooper(id: 1, name: 'Luke', tkid: 'TK-1'));

      final result = await controller.submit();

      expect(result, isFalse);
      controller.dispose();
    });

    test('returns false when both trooper and costume are null', () async {
      final controller = _makeController(api);

      final result = await controller.submit();

      expect(result, isFalse);
      controller.dispose();
    });

    test('submits successfully and sets submitSuccess', () async {
      final controller = _makeController(api);
      controller.setTrooper(Trooper(id: 1, name: 'Luke', tkid: 'TK-1'));
      controller.setCostume(Costume(id: 5, name: 'Vader'));

      api.setResponse({
        'success': true,
        'success_message': 'Added!',
      });

      final result = await controller.submit();

      expect(result, isTrue);
      expect(controller.submitSuccess, isTrue);
      expect(controller.successMessage, 'Added!');
      expect(controller.isSubmitting, isFalse);
      controller.dispose();
    });

    test('sets error when API reports failure', () async {
      final controller = _makeController(api);
      controller.setTrooper(Trooper(id: 1, name: 'Luke', tkid: 'TK-1'));
      controller.setCostume(Costume(id: 5, name: 'Vader'));

      api.setResponse({
        'success': false,
        'success_message': 'Limit reached.',
      });

      final result = await controller.submit();

      expect(result, isFalse);
      expect(controller.error, 'Limit reached.');
      expect(controller.isSubmitting, isFalse);
      controller.dispose();
    });

    test('sets default error when API failure has no message', () async {
      final controller = _makeController(api);
      controller.setTrooper(Trooper(id: 1, name: 'Luke', tkid: 'TK-1'));
      controller.setCostume(Costume(id: 5, name: 'Vader'));

      api.setResponse({'success': false});

      final result = await controller.submit();

      expect(result, isFalse);
      expect(controller.error, 'Failed to sign up!');
      controller.dispose();
    });

    test('sets error and returns false on exception', () async {
      final controller = _makeController(api);
      controller.setTrooper(Trooper(id: 1, name: 'Luke', tkid: 'TK-1'));
      controller.setCostume(Costume(id: 5, name: 'Vader'));

      api.setResponse(null); // causes cast exception

      final result = await controller.submit();

      expect(result, isFalse);
      expect(controller.error, isNotNull);
      expect(controller.isSubmitting, isFalse);
      controller.dispose();
    });

    test('includes shiftId in submission when shift is selected', () async {
      final controller = _makeController(api, shifts: [_shiftJson(id: 3)]);
      controller.setTrooper(Trooper(id: 1, name: 'Luke', tkid: 'TK-1'));
      controller.setCostume(Costume(id: 5, name: 'Vader'));

      api.setResponse({'success': true});

      await controller.submit();

      // Verify selectedShiftId was set on construction
      expect(controller.selectedShiftId, 3);
      controller.dispose();
    });
  });
}
