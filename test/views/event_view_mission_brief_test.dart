import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/controllers/auth_controller.dart';
import 'package:tt_mobile_app/models/app_user.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/auth_service.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/event_view.dart';

class _FakeStorage extends StorageService {
  @override
  String? getUserData() => null;

  @override
  String? getApiKey() => null;

  @override
  Future<void> saveLoginData({
    required String userData,
    required String apiKey,
  }) async {}

  @override
  Future<void> saveFcmToken(String token) async {}

  @override
  Future<void> clearAll() async {}

  @override
  String? getFcmToken() => null;
}

/// ApiClient that fakes the mobile API for a single event with
/// mission brief required.
class _MissionBriefApiClient extends ApiClient {
  _MissionBriefApiClient() : super(_FakeStorage());

  bool _hasAck = false;

  @override
  Uri mobileApiUri([Map<String, dynamic>? queryParameters]) {
    return Uri.parse('http://test.local/mobile-api').replace(
      queryParameters:
          queryParameters?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async {
    final action = uri.queryParameters['action'];

    switch (action) {
      case 'event':
        return {
          'name': 'Test Event',
          'venue': 'Test Venue',
          'location': 'Test Location',
          'website': '',
          'dateStart': '2026-04-10 09:00:00',
          'dateEnd': '2026-04-10 12:00:00',
          'comments': 'Mission brief content',
          'referred': null,
          'amenities': 'Restrooms',
          'isLimited': false,
          'guests_allowed': 1,
          'friends_allowed': 1,
          'limitedEvent': 0,
          'allowTentative': 0,
          'closed': 0,
          'missionBriefRequired': true,
          'hasMissionBriefAck': _hasAck,
          'shifts': [
            {
              'id': 1,
              'display': 'Shift 1',
            },
          ],
        };
      case 'get_roster_for_event':
        return [];
      case 'trooper_in_event':
        return {
          'inEvent': false,
          'my_shifts': <Map<String, dynamic>>[],
        };
      case 'get_friends_for_event':
        return [];
      case 'get_guests_for_event':
        return [];
      case 'get_photos_by_event':
        return {'photos': <Map<String, dynamic>>[]};
      case 'ack_mission_brief':
        _hasAck = true;
        return {
          'success': true,
          'missionBriefRequired': true,
          'hasMissionBriefAck': true,
        };
      default:
        return {};
    }
  }
}

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(_FakeStorage(), _MissionBriefApiClient());

  @override
  Map<String, dynamic>? restoreSession() => null;

  @override
  Future<Map<String, dynamic>> performOAuthLogin() async =>
      {'user_id': '1', 'username': 'Test'};
}

class _MockAuthController extends AuthController {
  _MockAuthController(ApiClient api)
      : super(_FakeAuthService(), api, _FakeStorage());

  @override
  AppUser? get currentUser => AppUser(id: '1', username: 'TestUser');
}

Widget _buildSubject(_MissionBriefApiClient api) {
  final auth = _MockAuthController(api);
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: api),
      ChangeNotifierProvider<AuthController>.value(value: auth),
    ],
    child: const MaterialApp(home: EventView(troopId: 1)),
  );
}

void main() {
  group('EventView mission brief', () {
    testWidgets(
        'shows mission brief warning and hides sign-up when ack is missing',
        (tester) async {
      final api = _MissionBriefApiClient();

      await tester.pumpWidget(_buildSubject(api));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'You must review and acknowledge the mission brief before you can sign up for this deployment, add friends, or add guests.',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'I have read and understand the mission brief',
        ),
        findsOneWidget,
      );

      // Single-shift controls should show a warning instead of the sign-up CTA.
      expect(
        find.text(
          'Review and acknowledge the mission brief above to enable sign-ups.',
        ),
        findsOneWidget,
      );
      expect(find.text('Go To Sign Up'), findsNothing);
    });

    testWidgets(
        'enables sign-up and updates banner after acknowledging mission brief',
        (tester) async {
      final api = _MissionBriefApiClient();

      await tester.pumpWidget(_buildSubject(api));
      await tester.pumpAndSettle();

      // Scroll to and tap the acknowledge button.
      final ackButtonFinder =
          find.text('I have read and understand the mission brief');
      await tester.scrollUntilVisible(
        ackButtonFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(ackButtonFinder);
      await tester.pumpAndSettle();

      // Success banner is shown and warning is gone.
      expect(
        find.textContaining('You have acknowledged this mission brief'),
        findsOneWidget,
      );
      expect(
        find.text(
          'You must review and acknowledge the mission brief before you can sign up for this deployment, add friends, or add guests.',
        ),
        findsNothing,
      );

      // Acknowledge button is no longer visible.
      expect(
        find.text('I have read and understand the mission brief'),
        findsNothing,
      );

      // Single-shift sign-up CTA is now available.
      expect(find.text('Go To Sign Up'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Go To Sign Up'),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
