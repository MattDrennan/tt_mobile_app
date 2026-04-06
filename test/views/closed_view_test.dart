import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/controllers/auth_controller.dart';
import 'package:tt_mobile_app/models/site_status.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/auth_service.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/closed_view.dart';

// ── Manual mocks ──────────────────────────────────────────────────────────────

class _FakeStorage extends StorageService {
  @override
  String? getApiKey() => null;
  @override
  String? getUserData() => null;
}

class _MockAuthController extends AuthController {
  SiteStatus? _status;
  bool fetchCalled = false;

  _MockAuthController()
      : super(
          _FakeAuthService(),
          ApiClient(_FakeStorage()),
          _FakeStorage(),
        );

  void seedStatus(SiteStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  SiteStatus? get siteStatus => _status;

  @override
  Future<void> fetchSiteStatus() async {
    fetchCalled = true;
  }
}

class _FakeAuthService extends AuthService {
  _FakeAuthService()
      : super(_FakeStorage(), ApiClient(_FakeStorage()));

  @override
  Map<String, dynamic>? restoreSession() => null;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildSubject(
  _MockAuthController auth, {
  String? message,
}) {
  return ChangeNotifierProvider<AuthController>.value(
    value: auth,
    child: MaterialApp(
      home: ClosedView(message: message),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockAuthController auth;

  setUp(() {
    auth = _MockAuthController();
  });

  tearDown(() => auth.dispose());

  testWidgets('shows lock icon', (tester) async {
    await tester.pumpWidget(_buildSubject(auth));
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('shows "Troop Tracker is Currently Closed" heading',
      (tester) async {
    await tester.pumpWidget(_buildSubject(auth));
    expect(find.text('Troop Tracker is Currently Closed'), findsOneWidget);
  });

  testWidgets('shows Try Again button', (tester) async {
    await tester.pumpWidget(_buildSubject(auth));
    expect(find.text('Try Again'), findsOneWidget);
  });

  testWidgets('does not show message widget when message is null',
      (tester) async {
    await tester.pumpWidget(_buildSubject(auth, message: null));
    // Only the heading should be present; no extra message Text
    expect(find.text('Troop Tracker is Currently Closed'), findsOneWidget);
    // The optional message Row should not render
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets('shows provided message text', (tester) async {
    await tester.pumpWidget(
      _buildSubject(auth, message: 'Back online soon!'),
    );
    expect(find.text('Back online soon!'), findsOneWidget);
  });

  testWidgets('tapping Try Again calls fetchSiteStatus', (tester) async {
    await tester.pumpWidget(_buildSubject(auth));
    await tester.tap(find.text('Try Again'));
    await tester.pump();
    expect(auth.fetchCalled, isTrue);
  });

  testWidgets(
      'shows snack bar with "Still closed" when status remains closed',
      (tester) async {
    auth.seedStatus(const SiteStatus(
      canAccess: false,
      isBanned: false,
      isClosed: true,
      message: 'Site is closed',
    ));
    await tester.pumpWidget(_buildSubject(auth));
    await tester.tap(find.text('Try Again'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
