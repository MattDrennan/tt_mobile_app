import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/controllers/event_controller.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

Map<String, dynamic> _eventJson({
  String name = 'Test Event',
  String venue = 'Test Venue',
  dynamic closed = 0,
  List<dynamic> shifts = const [],
  String dateEnd = '2099-12-31 23:59:59',
}) =>
    {
      'name': name,
      'venue': venue,
      'closed': closed,
      'shifts': shifts,
      'dateEnd': dateEnd,
    };

Map<String, dynamic> _rosterEntryJson({
  String trooperName = 'Trooper One',
  int? shiftId,
}) =>
    {
      'status_formatted': 'Going',
      'trooper_name': trooperName,
      'tkid_formatted': 'TK-11111',
      'costume_name': 'Stormtrooper',
      'backup_costume_name': '',
      'signuptime': '2024-01-01',
      'shift_id': shiftId,
    };

// ── Manual mocks ──────────────────────────────────────────────────────────────

class _FakeStorage extends StorageService {
  @override
  String? getApiKey() => 'test-key';
}

/// Queue-based mock: responses are consumed FIFO.
/// Falls back to [_default] once the queue is exhausted.
class _MockApiClient extends ApiClient {
  final _queue = <dynamic>[];
  dynamic _default;

  _MockApiClient() : super(_FakeStorage());

  void enqueue(dynamic r) => _queue.add(r);
  void setDefault(dynamic r) => _default = r;

  @override
  Uri mobileApiUri([Map<String, dynamic>? queryParameters]) =>
      Uri.parse('https://test.example.com/api');

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async {
    if (_queue.isNotEmpty) return _queue.removeAt(0);
    return _default;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// fetchAll fires 6 getJson calls in parallel (order matches source):
/// [0] event  [1] roster  [2] checkInRoster  [3] friends  [4] guests  [5] photos
void _seedFetchAll(
  _MockApiClient api, {
  dynamic eventData,
  dynamic rosterData,
  dynamic inRosterData,
  dynamic friendsData,
  dynamic guestsData,
  dynamic photosData,
}) {
  api.enqueue(eventData ?? _eventJson());
  api.enqueue(rosterData ?? []);
  api.enqueue(inRosterData ?? {'inEvent': false, 'my_shifts': []});
  api.enqueue(friendsData ?? []);
  api.enqueue(guestsData ?? []);
  api.enqueue(photosData ?? {'photos': []});
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockApiClient api;
  late EventController controller;

  setUp(() {
    api = _MockApiClient();
    controller = EventController(api, eventId: 1, userId: '42');
  });

  tearDown(() => controller.dispose());

  // ── Initial state ────────────────────────────────────────────────────────

  group('EventController initial state', () {
    test('is not loading', () {
      expect(controller.isLoading, isFalse);
    });

    test('has no event data', () {
      expect(controller.event, isNull);
    });

    test('has empty roster', () {
      expect(controller.roster, isEmpty);
    });

    test('is not in roster', () {
      expect(controller.isInRoster, isFalse);
    });

    test('has no action in progress', () {
      expect(controller.isActionInProgress, isFalse);
    });

    test('has no action error', () {
      expect(controller.actionError, isNull);
    });
  });

  // ── fetchAll ─────────────────────────────────────────────────────────────

  group('EventController.fetchAll', () {
    test('sets isLoading to false after completion', () async {
      _seedFetchAll(api);
      await controller.fetchAll();
      expect(controller.isLoading, isFalse);
    });

    test('populates event from API response', () async {
      _seedFetchAll(api, eventData: _eventJson(name: 'Star Wars Night'));
      await controller.fetchAll();
      expect(controller.event?.name, 'Star Wars Night');
      expect(controller.event?.venue, 'Test Venue');
    });

    test('populates roster from API response', () async {
      _seedFetchAll(api, rosterData: [
        _rosterEntryJson(trooperName: 'Vader'),
        _rosterEntryJson(trooperName: 'Stormtrooper'),
      ]);
      await controller.fetchAll();
      expect(controller.roster.length, 2);
      expect(controller.roster.first.trooperName, 'Vader');
    });

    test('sets isInRoster true when API reports inEvent true', () async {
      _seedFetchAll(api,
          inRosterData: {
            'inEvent': true,
            'my_shifts': [
              {'shift_id': 3, 'status_formatted': 'Going'},
            ],
          });
      await controller.fetchAll();
      expect(controller.isInRoster, isTrue);
      expect(controller.myShiftStatuses[3], 'Going');
    });

    test('sets isInRoster false when API reports inEvent false', () async {
      _seedFetchAll(api,
          inRosterData: {'inEvent': false, 'my_shifts': []});
      await controller.fetchAll();
      expect(controller.isInRoster, isFalse);
      expect(controller.myShiftStatuses, isEmpty);
    });

    test('populates myFriends from API response', () async {
      _seedFetchAll(api, friendsData: [
        {'id': 1, 'name': 'Friend Alpha'},
        {'id': 2, 'name': 'Friend Beta'},
      ]);
      await controller.fetchAll();
      expect(controller.myFriends.length, 2);
    });

    test('populates myGuests from API response', () async {
      _seedFetchAll(api,
          guestsData: [
            {'id': 10, 'name': 'Guest One'},
          ]);
      await controller.fetchAll();
      expect(controller.myGuests.length, 1);
    });

    test('populates photoList from API response', () async {
      _seedFetchAll(api,
          photosData: {
            'photos': [
              {'url': 'https://example.com/a.jpg'},
              {'url': 'https://example.com/b.jpg'},
            ],
          });
      await controller.fetchAll();
      expect(controller.photoList.length, 2);
    });

    test('survives when all API calls return null (cast errors)', () async {
      api.setDefault(null);
      await expectLater(controller.fetchAll(), completes);
      expect(controller.isLoading, isFalse);
    });

    test('sets selectedRosterShiftId from first shift', () async {
      _seedFetchAll(api,
          eventData: _eventJson(shifts: [
            {'id': 7, 'name': 'Morning'},
            {'id': 8, 'name': 'Evening'},
          ]));
      await controller.fetchAll();
      expect(controller.selectedRosterShiftId, 7);
    });

    test('does not overwrite selectedRosterShiftId if already set', () async {
      // First fetchAll sets it to 7
      _seedFetchAll(api,
          eventData: _eventJson(shifts: [
            {'id': 7, 'name': 'Morning'},
          ]));
      await controller.fetchAll();
      expect(controller.selectedRosterShiftId, 7);

      // Second fetchAll with different first shift should not override
      _seedFetchAll(api,
          eventData: _eventJson(shifts: [
            {'id': 9, 'name': 'Afternoon'},
          ]));
      await controller.refreshAll();
      expect(controller.selectedRosterShiftId, 7);
    });
  });

  // ── filteredRoster ───────────────────────────────────────────────────────

  group('EventController.filteredRoster', () {
    test('returns empty list before data is loaded', () {
      expect(controller.filteredRoster, isEmpty);
    });

    test('returns all entries when event has one shift', () async {
      _seedFetchAll(api,
          eventData: _eventJson(shifts: [
            {'id': 1, 'name': 'Only Shift'},
          ]),
          rosterData: [
            _rosterEntryJson(trooperName: 'A', shiftId: 1),
            _rosterEntryJson(trooperName: 'B', shiftId: 1),
          ]);
      await controller.fetchAll();
      // Single shift → no filtering applied
      expect(controller.filteredRoster.length, 2);
    });

    test('filters by selectedRosterShiftId when multiple shifts exist',
        () async {
      _seedFetchAll(api,
          eventData: _eventJson(shifts: [
            {'id': 1, 'name': 'Shift A'},
            {'id': 2, 'name': 'Shift B'},
          ]),
          rosterData: [
            _rosterEntryJson(trooperName: 'In Shift 1', shiftId: 1),
            _rosterEntryJson(trooperName: 'In Shift 2', shiftId: 2),
          ]);
      await controller.fetchAll();
      // Auto-selected shift id = 1
      expect(controller.filteredRoster.length, 1);
      expect(controller.filteredRoster.first.trooperName, 'In Shift 1');
    });

    test('updates filtered results after setRosterShiftFilter', () async {
      _seedFetchAll(api,
          eventData: _eventJson(shifts: [
            {'id': 1, 'name': 'Shift A'},
            {'id': 2, 'name': 'Shift B'},
          ]),
          rosterData: [
            _rosterEntryJson(trooperName: 'In Shift 1', shiftId: 1),
            _rosterEntryJson(trooperName: 'In Shift 2', shiftId: 2),
          ]);
      await controller.fetchAll();

      controller.setRosterShiftFilter(2);

      expect(controller.filteredRoster.length, 1);
      expect(controller.filteredRoster.first.trooperName, 'In Shift 2');
    });
  });

  // ── setRosterShiftFilter ─────────────────────────────────────────────────

  group('EventController.setRosterShiftFilter', () {
    test('updates selectedRosterShiftId', () {
      controller.setRosterShiftFilter(5);
      expect(controller.selectedRosterShiftId, 5);
    });

    test('notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setRosterShiftFilter(5);
      expect(notified, isTrue);
    });
  });

  // ── cancelTroop ──────────────────────────────────────────────────────────

  group('EventController.cancelTroop', () {
    test('returns false and sets error for manual selection events', () async {
      _seedFetchAll(api, eventData: _eventJson(closed: 'manualselection'));
      await controller.fetchAll();

      final result = await controller.cancelTroop();

      expect(result, isFalse);
      expect(controller.actionError, contains('Manual Selection'));
    });

    test('does not start action for manual selection events', () async {
      _seedFetchAll(api, eventData: _eventJson(closed: 'manualselection'));
      await controller.fetchAll();

      await controller.cancelTroop();

      expect(controller.isActionInProgress, isFalse);
    });

    test('cancels successfully, clears roster membership', () async {
      _seedFetchAll(api,
          inRosterData: {'inEvent': true, 'my_shifts': []});
      await controller.fetchAll();

      // cancel_troop response + _fetchEvent + _fetchRoster
      api.enqueue({'success': true});
      api.enqueue(_eventJson());
      api.enqueue([]);

      final result = await controller.cancelTroop();

      expect(result, isTrue);
      expect(controller.isInRoster, isFalse);
      expect(controller.myShiftStatuses, isEmpty);
      expect(controller.isActionInProgress, isFalse);
    });

    test('returns false and sets error when API reports failure', () async {
      _seedFetchAll(api);
      await controller.fetchAll();

      api.enqueue({'success': false});
      final result = await controller.cancelTroop();

      expect(result, isFalse);
      expect(controller.actionError, 'Something went wrong.');
    });

    test('returns false and sets error on exception', () async {
      _seedFetchAll(api);
      await controller.fetchAll();

      // null causes a cast exception inside cancelTroop
      api.setDefault(null);
      final result = await controller.cancelTroop();

      expect(result, isFalse);
      expect(controller.actionError, isNotNull);
      expect(controller.isActionInProgress, isFalse);
    });
  });

  // ── cancelShift ──────────────────────────────────────────────────────────

  group('EventController.cancelShift', () {
    test('returns false for manual selection events', () async {
      _seedFetchAll(api, eventData: _eventJson(closed: 'manualselection'));
      await controller.fetchAll();

      final result = await controller.cancelShift(1);

      expect(result, isFalse);
      expect(controller.actionError, isNotNull);
    });

    test('cancels shift successfully and refreshes data', () async {
      _seedFetchAll(api);
      await controller.fetchAll();

      // cancel_shift + _fetchEvent + _fetchMyFriends + _fetchMyGuests + _checkInRoster
      api.enqueue({'success': true});
      api.enqueue(_eventJson());
      api.enqueue([]);
      api.enqueue([]);
      api.enqueue({'inEvent': false, 'my_shifts': []});

      final result = await controller.cancelShift(1);

      expect(result, isTrue);
      expect(controller.isActionInProgress, isFalse);
    });

    test('sets error when API reports failure', () async {
      _seedFetchAll(api);
      await controller.fetchAll();

      api.enqueue({'success': false});
      final result = await controller.cancelShift(1);

      expect(result, isFalse);
      expect(controller.actionError, 'Something went wrong.');
    });

    test('sets error and returns false on exception', () async {
      _seedFetchAll(api);
      await controller.fetchAll();

      api.setDefault(null);
      final result = await controller.cancelShift(1);

      expect(result, isFalse);
      expect(controller.actionError, isNotNull);
    });
  });

  // ── cancelGuest ──────────────────────────────────────────────────────────

  group('EventController.cancelGuest', () {
    test('returns false for manual selection events', () async {
      _seedFetchAll(api, eventData: _eventJson(closed: 'manualselection'));
      await controller.fetchAll();

      final result = await controller.cancelGuest(99);
      expect(result, isFalse);
    });

    test('cancels guest and refreshes guests and event data', () async {
      _seedFetchAll(api);
      await controller.fetchAll();

      // cancel_guest + _fetchMyGuests + _fetchEvent
      api.enqueue({'success': true});
      api.enqueue([]);
      api.enqueue(_eventJson());

      final result = await controller.cancelGuest(99);

      expect(result, isTrue);
      expect(controller.isActionInProgress, isFalse);
    });

    test('sets error when API reports failure', () async {
      _seedFetchAll(api);
      await controller.fetchAll();

      api.enqueue({'success': false});
      final result = await controller.cancelGuest(99);

      expect(result, isFalse);
      expect(controller.actionError, 'Something went wrong.');
    });
  });

  // ── cancelFriendShift ────────────────────────────────────────────────────

  group('EventController.cancelFriendShift', () {
    test('returns false for manual selection events', () async {
      _seedFetchAll(api, eventData: _eventJson(closed: 'manualselection'));
      await controller.fetchAll();

      final result = await controller.cancelFriendShift(5, 1);
      expect(result, isFalse);
    });

    test('cancels friend shift and refreshes friends and event data', () async {
      _seedFetchAll(api);
      await controller.fetchAll();

      // cancel_shift + _fetchMyFriends + _fetchEvent
      api.enqueue({'success': true});
      api.enqueue([]);
      api.enqueue(_eventJson());

      final result = await controller.cancelFriendShift(5, 1);

      expect(result, isTrue);
      expect(controller.isActionInProgress, isFalse);
    });

    test('sets error when API reports failure', () async {
      _seedFetchAll(api);
      await controller.fetchAll();

      api.enqueue({'success': false});
      final result = await controller.cancelFriendShift(5, 1);

      expect(result, isFalse);
      expect(controller.actionError, 'Something went wrong.');
    });
  });

  // ── clearActionError ─────────────────────────────────────────────────────

  group('EventController.clearActionError', () {
    test('clears actionError', () async {
      _seedFetchAll(api, eventData: _eventJson(closed: 'manualselection'));
      await controller.fetchAll();
      await controller.cancelTroop(); // sets error

      expect(controller.actionError, isNotNull);
      controller.clearActionError();
      expect(controller.actionError, isNull);
    });
  });

  // ── refreshAll ───────────────────────────────────────────────────────────

  group('EventController.refreshAll', () {
    test('re-fetches all data', () async {
      _seedFetchAll(api, eventData: _eventJson(name: 'Original Name'));
      await controller.fetchAll();
      expect(controller.event?.name, 'Original Name');

      _seedFetchAll(api, eventData: _eventJson(name: 'Updated Name'));
      await controller.refreshAll();
      expect(controller.event?.name, 'Updated Name');
    });
  });
}
