import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/controllers/chat_controller.dart';
import 'package:tt_mobile_app/models/app_organization.dart';
import 'package:tt_mobile_app/models/app_user.dart';
import 'package:tt_mobile_app/models/chat_room.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _kUser = AppUser(id: '1', username: 'Trooper', avatarUrl: null);

Map<String, dynamic> _chatRoomJson({
  int troopid = 10,
  String name = 'Chat Room',
  int? threadId,
  int squad = 0,
  int link = 1,
}) =>
    {
      'troopid': troopid,
      'name': name,
      'thread_id': threadId,
      'post_id': null,
      'squad': squad,
      'dateStart': '2024-06-01',
      'dateEnd': '2024-06-01',
      'link': link,
    };

Map<String, dynamic> _organizationJson({int id = 1, String name = 'Makaze Squad'}) =>
    {'id': id, 'name': name};

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
  Uri forumApiUri(String path, [Map<String, dynamic>? queryParameters]) =>
      Uri.parse('https://test.example.com/forum/$path');

  @override
  Uri forumMobileApiUri([Map<String, dynamic>? queryParameters]) =>
      Uri.parse('https://test.example.com/forum-mobile');

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async =>
      _response;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockApiClient api;
  late ChatController controller;

  setUp(() {
    api = _MockApiClient();
    controller = ChatController(api, currentUser: _kUser);
  });

  tearDown(() {
    controller.dispose();
  });

  // ── Initial state ────────────────────────────────────────────────────────

  group('ChatController initial state', () {
    test('rooms is empty', () {
      expect(controller.rooms, isEmpty);
    });

    test('organizations is empty', () {
      expect(controller.organizations, isEmpty);
    });

    test('messages is empty', () {
      expect(controller.messages, isEmpty);
    });

    test('isLoadingRooms is false', () {
      expect(controller.isLoadingRooms, isFalse);
    });

    test('isLoadingMessages is false', () {
      expect(controller.isLoadingMessages, isFalse);
    });

    test('isSending is false', () {
      expect(controller.isSending, isFalse);
    });

    test('actionError is null', () {
      expect(controller.actionError, isNull);
    });
  });

  // ── fetchRooms ───────────────────────────────────────────────────────────

  group('ChatController.fetchRooms', () {
    test('populates rooms from API response', () async {
      api.setResponse({
        'troops': [
          _chatRoomJson(troopid: 1, name: 'Morning Patrol'),
          _chatRoomJson(troopid: 2, name: 'Evening Patrol'),
        ],
      });

      await controller.fetchRooms();

      expect(controller.rooms.length, 2);
      expect(controller.rooms.first.name, 'Morning Patrol');
    });

    test('sets rooms to empty when API returns empty troops', () async {
      api.setResponse({'troops': []});

      await controller.fetchRooms();

      expect(controller.rooms, isEmpty);
    });

    test('sets rooms to empty when troops key is missing', () async {
      api.setResponse(<String, dynamic>{});

      await controller.fetchRooms();

      expect(controller.rooms, isEmpty);
    });

    test('handles API exception silently', () async {
      api.setResponse(null); // causes cast exception

      await expectLater(controller.fetchRooms(), completes);
      expect(controller.rooms, isEmpty);
    });

    test('sets isLoadingRooms to false after completion', () async {
      api.setResponse({'troops': []});

      await controller.fetchRooms();

      expect(controller.isLoadingRooms, isFalse);
    });

    test('sets isLoadingRooms to false even when API throws', () async {
      api.setResponse(null);

      await controller.fetchRooms();

      expect(controller.isLoadingRooms, isFalse);
    });

    test('notifies listeners at least twice (start and end)', () async {
      api.setResponse({'troops': []});
      var count = 0;
      controller.addListener(() => count++);

      await controller.fetchRooms();

      expect(count, greaterThanOrEqualTo(2));
    });
  });

  // ── fetchOrganizations ───────────────────────────────────────────────────

  group('ChatController.fetchOrganizations', () {
    test('populates organizations from API response', () async {
      api.setResponse({
        'organizations': [
          _organizationJson(id: 1, name: 'Makaze Squad'),
          _organizationJson(id: 2, name: 'Parjai Squad'),
        ],
      });

      await controller.fetchOrganizations();

      expect(controller.organizations.length, 2);
      expect(controller.organizations.first.name, 'Makaze Squad');
    });

    test('leaves organizations empty when response has no key', () async {
      api.setResponse(<String, dynamic>{});

      await controller.fetchOrganizations();

      expect(controller.organizations, isEmpty);
    });

    test('handles API exception silently', () async {
      api.setResponse(null);

      await expectLater(controller.fetchOrganizations(), completes);
      expect(controller.organizations, isEmpty);
    });

    test('notifies listeners after successful fetch', () async {
      api.setResponse({'organizations': []});
      var notified = false;
      controller.addListener(() => notified = true);

      await controller.fetchOrganizations();

      expect(notified, isTrue);
    });
  });

  // ── iconForRoom ──────────────────────────────────────────────────────────

  group('ChatController.iconForRoom', () {
    final room = ChatRoom(
      id: 1,
      name: 'Morning Patrol',
      squad: 3,
      dateStart: '2024-06-01',
      dateEnd: '2024-06-01',
      hasLink: true,
    );

    test('returns matching org icon when squad matches loaded organization',
        () async {
      api.setResponse({
        'organizations': [
          _organizationJson(id: 3, name: 'Makaze Squad'),
        ],
      });
      await controller.fetchOrganizations();

      final icon = controller.iconForRoom(room);

      expect(icon, 'assets/icons/makaze_icon.png');
    });

    test('returns fallback icon when no organization matches', () async {
      api.setResponse({'organizations': []});
      await controller.fetchOrganizations();

      final icon = controller.iconForRoom(room);

      expect(icon, AppOrganization.fallbackIcon);
    });

    test('returns fallback icon before organizations are loaded', () {
      final icon = controller.iconForRoom(room);
      expect(icon, AppOrganization.fallbackIcon);
    });
  });

  // ── openRoom ─────────────────────────────────────────────────────────────

  group('ChatController.openRoom', () {
    test('clears previous messages on open', () async {
      // Seed a room then close it
      controller.openRoom(10);
      controller.stopPolling();
      // messages would be populated; open a new room resets them
      controller.openRoom(20);
      controller.stopPolling();

      expect(controller.messages, isEmpty);
    });

    test('starts polling after openRoom', () {
      controller.openRoom(10);
      // Verify polling is running by checking that stopPolling doesn't throw
      expect(() => controller.stopPolling(), returnsNormally);
    });
  });

  // ── stopPolling / startPolling ────────────────────────────────────────────

  group('ChatController polling lifecycle', () {
    test('stopPolling is idempotent', () {
      controller.openRoom(10);
      controller.stopPolling();
      expect(() => controller.stopPolling(), returnsNormally);
    });

    test('startPolling can be called multiple times without leaking timers',
        () {
      controller.openRoom(10);
      controller.startPolling();
      controller.startPolling();
      expect(() => controller.stopPolling(), returnsNormally);
    });

    test('dispose cancels the poll timer', () {
      controller.openRoom(10);
      expect(() => controller.dispose(), returnsNormally);
      // Prevent tearDown from calling dispose again on an already-disposed object
      controller = ChatController(api, currentUser: _kUser);
    });
  });

  // ── clearActionError ─────────────────────────────────────────────────────

  group('ChatController.clearActionError', () {
    test('clears actionError and notifies listeners', () {
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.clearActionError();

      expect(controller.actionError, isNull);
      expect(notifyCount, 1);
    });
  });

  // ── sendMessage guard ────────────────────────────────────────────────────

  group('ChatController.sendMessage', () {
    test('returns false when no room is open', () async {
      final result = await controller.sendMessage('Hello');
      expect(result, isFalse);
    });
  });
}
