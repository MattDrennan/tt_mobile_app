import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/controllers/auth_controller.dart';
import 'package:tt_mobile_app/models/app_user.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/auth_service.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/home_view.dart';

// ── Manual mocks ──────────────────────────────────────────────────────────────

class _FakeStorage extends StorageService {
  @override
  String? getApiKey() => null;
  @override
  String? getUserData() => null;
}

class _FakeAuthService extends AuthService {
  _FakeAuthService()
      : super(_FakeStorage(), ApiClient(_FakeStorage()));
  @override
  Map<String, dynamic>? restoreSession() => null;
}

class _MockAuthController extends AuthController {
  final AppUser _user;

  _MockAuthController({String userId = '42'})
      : _user = AppUser(id: userId, username: 'Trooper'),
        super(
          _FakeAuthService(),
          ApiClient(_FakeStorage()),
          _FakeStorage(),
        );

  @override
  AppUser? get currentUser => _user;
  @override
  bool get isLoading => false;
  @override
  bool get isLoggedIn => true;

  @override
  Future<void> fetchSiteStatus() async {}
  @override
  Future<void> logout() async {}
}

/// Returns a mock that enqueues [response] for every getJson call.
class _MockApiClient extends ApiClient {
  final dynamic _response;

  _MockApiClient({dynamic response = const {'troops': []}})
      : _response = response,
        super(_FakeStorage());

  @override
  Uri mobileApiUri([Map<String, dynamic>? queryParameters]) =>
      Uri.parse('https://test.example.com/api');

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async =>
      _response;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildSubject({
  _MockAuthController? auth,
  _MockApiClient? api,
}) {
  final a = auth ?? _MockAuthController();
  final c = api ?? _MockApiClient();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>.value(value: a),
      Provider<ApiClient>.value(value: c),
    ],
    child: const MaterialApp(home: HomeView()),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('shows View Troops button', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump(); // let initState settle
    expect(find.text('View Troops'), findsOneWidget);
  });

  testWidgets('shows My Troops button', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('My Troops'), findsOneWidget);
  });

  testWidgets('shows Chat button', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('Chat'), findsOneWidget);
  });

  testWidgets('shows Log Out button', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('Log Out'), findsOneWidget);
  });

  testWidgets('does not show Confirm Troops when there are no unconfirmed troops',
      (tester) async {
    // Default mock returns empty troops → hasUnconfirmedTroops = false
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('Confirm Troops'), findsNothing);
  });

  testWidgets('shows Confirm Troops button when unconfirmed troops exist',
      (tester) async {
    final api = _MockApiClient(
      response: {
        'troops': [
          {'troopid': 1, 'name': 'Holiday Parade'},
        ],
      },
    );
    await tester.pumpWidget(_buildSubject(api: api));
    // Wait for the async checkUnconfirmedTroops call to complete
    await tester.pump();
    await tester.pump();
    expect(find.text('Confirm Troops'), findsOneWidget);
  });

  testWidgets('shows Terms and Rules link', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('Terms and Rules'), findsOneWidget);
  });

  testWidgets('shows Privacy Policy link', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('Privacy Policy'), findsOneWidget);
  });
}
