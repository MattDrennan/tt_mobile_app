import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/controllers/auth_controller.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/auth_service.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/add_friend_view.dart';

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
  bool _isLoading = false;
  String? _error;

  _MockAuthController(_FakeAuthService authService)
      : super(authService, ApiClient(_FakeStorage()), _FakeStorage());

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _error;

  void setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void setError(String? msg) {
    _error = msg;
    notifyListeners();
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildSubject(_MockAuthController controller) {
  return ChangeNotifierProvider<AuthController>.value(
    value: controller,
    child: const MaterialApp(home: AddFriendView()),
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

  group('AddFriendView', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(AddFriendView), findsOneWidget);
    });

    testWidgets('displays content when not loading', (tester) async {
      controller.setLoading(false);
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      controller.setLoading(true);
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when set', (tester) async {
      controller.setError('Failed to add friend');
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed'), findsWidgets);
    });

    testWidgets('is part of the app navigation flow', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
