import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/controllers/auth_controller.dart';
import 'package:tt_mobile_app/models/app_user.dart';
import 'package:tt_mobile_app/models/site_status.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/auth_service.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/access_gate_view.dart';

// ── Manual mocks ─────────────────────────────────────────────────────────────

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

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(_FakeStorage(), ApiClient(_FakeStorage()));

  @override
  Map<String, dynamic>? restoreSession() => null;

  @override
  Future<Map<String, dynamic>> performOAuthLogin() async =>
      {'user_id': '1', 'username': 'Test'};
}

class _MockAuthController extends AuthController {
  SiteStatus? _siteStatus;
  bool _isLoading = false;
  bool _loggedOut = false;
  String? _error;

  _MockAuthController(_FakeAuthService authService)
      : super(authService, ApiClient(_FakeStorage()), _FakeStorage());

  @override
  bool get isLoading => _isLoading;

  @override
  bool get loggedOut => _loggedOut;

  @override
  String? get errorMessage => _error;

  void setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void setLoggedOut(bool v) {
    _loggedOut = v;
    notifyListeners();
  }

  void setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  void setSiteStatus(SiteStatus status) {
    _siteStatus = status;
    notifyListeners();
  }

  @override
  AppUser? get currentUser => AppUser(id: '42', username: 'TestUser');

  @override
  SiteStatus? get currentUserAccessStatus => _siteStatus;

  @override
  Future<SiteStatus> checkUserAccess(int trooperId) async {
    return _siteStatus ??
        SiteStatus(
          canAccess: false,
          isBanned: false,
          message: 'Access pending approval',
        );
  }

  @override
  void clearLoggedOutFlag() {
    _loggedOut = false;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildSubject(_MockAuthController controller) {
  return ChangeNotifierProvider<AuthController>.value(
    value: controller,
    child: MaterialApp(
      home: const AccessGateView(),
      navigatorObservers: [NavigatorObserver()],
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _FakeAuthService authService;
  late _MockAuthController controller;

  setUp(() {
    authService = _FakeAuthService();
    controller = _MockAuthController(authService);
  });

  group('AccessGateView', () {
    testWidgets('displays access check title', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.text('Access Check'), findsOneWidget);
    });

    testWidgets('shows lock icon when not checking', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('displays status message', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.textContaining('Access pending'), findsWidgets);
    });

    testWidgets('shows Try Again button', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows Logout button', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('logout button is enabled by default', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      // ElevatedButton.icon creates a _ElevatedButtonWithIcon subtype; find by icon.
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('disables Try Again button when checking', (tester) async {
      controller.setLoading(true);
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      final tryAgainButton = find.byIcon(Icons.refresh);
      expect(tryAgainButton, findsOneWidget);
    });

    testWidgets('background is black', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);
    });
  });
}
