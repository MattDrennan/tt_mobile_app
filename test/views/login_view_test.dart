import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/controllers/auth_controller.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/auth_service.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/login_view.dart';

// ── Manual mocks ─────────────────────────────────────────────────────────────

class _FakeStorage extends StorageService {
  @override
  String? getApiKey() => null;
  @override
  String? getUserData() => null;
}

class _FakeAuthService extends AuthService {
  bool loginCalled = false;

  _FakeAuthService()
      : super(_FakeStorage(), ApiClient(_FakeStorage()));

  @override
  Map<String, dynamic>? restoreSession() => null;

  @override
  Future<Map<String, dynamic>> performOAuthLogin() async {
    loginCalled = true;
    return {'user_id': '1', 'username': 'Test'};
  }
}

class _MockAuthController extends AuthController {
  bool loginCalled = false;
  bool _loading = false;
  String? _error;

  _MockAuthController(_FakeAuthService authService)
      : super(authService, ApiClient(_FakeStorage()), _FakeStorage());

  @override
  bool get isLoading => _loading;

  @override
  String? get errorMessage => _error;

  void setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  @override
  Future<void> login() async {
    loginCalled = true;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildSubject(_MockAuthController controller) {
  return ChangeNotifierProvider<AuthController>.value(
    value: controller,
    child: const MaterialApp(home: LoginView()),
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

  testWidgets('shows Continue button when not loading', (tester) async {
    await tester.pumpWidget(_buildSubject(controller));
    expect(find.text('Continue with XenForo'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows spinner when isLoading is true', (tester) async {
    controller.setLoading(true);
    await tester.pumpWidget(_buildSubject(controller));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Continue with XenForo'), findsNothing);
  });

  testWidgets('calls auth.login() when button is tapped', (tester) async {
    await tester.pumpWidget(_buildSubject(controller));
    await tester.tap(find.text('Continue with XenForo'));
    await tester.pump();
    expect(controller.loginCalled, isTrue);
  });

  testWidgets('shows error message when errorMessage is set', (tester) async {
    controller.setError('Invalid credentials');
    await tester.pumpWidget(_buildSubject(controller));
    expect(find.text('Invalid credentials'), findsOneWidget);
  });
}
