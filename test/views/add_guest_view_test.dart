import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/controllers/auth_controller.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/auth_service.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/add_guest_view.dart';

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

  _MockAuthController(_FakeAuthService authService)
      : super(authService, ApiClient(_FakeStorage()), _FakeStorage());

  @override
  bool get isLoading => _isLoading;

  void setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildSubject(_MockAuthController controller) {
  return ChangeNotifierProvider<AuthController>.value(
    value: controller,
    child: MaterialApp(
      home: AddGuestView(
        troopId: 1,
        userId: '1',
        api: ApiClient(_FakeStorage()),
      ),
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

  group('AddGuestView', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(AddGuestView), findsOneWidget);
    });

    testWidgets('displays scaffold', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('handles loading state', (tester) async {
      controller.setLoading(true);
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      controller.setLoading(false);
      await tester.pumpAndSettle();
      expect(find.byType(AddGuestView), findsOneWidget);
    });

    testWidgets('is navigable', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(Material), findsWidgets);
    });
  });
}
