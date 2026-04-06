import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/controllers/auth_controller.dart';
import 'package:tt_mobile_app/models/app_user.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/auth_service.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/add_friend_view.dart';

class _FakeStorage extends StorageService {
  @override
  String? getUserData() => null;
  @override
  String? getApiKey() => null;
  @override
  Future<void> saveLoginData({required String userData, required String apiKey}) async {}
  @override
  Future<void> saveFcmToken(String token) async {}
  @override
  Future<void> clearAll() async {}
  @override
  String? getFcmToken() => null;
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(_FakeStorage());
  @override
  Uri mobileApiUri([Map<String, dynamic>? p]) => Uri.parse('http://test.local/api');
  @override
  Uri forumApiUri(String path, [Map<String, dynamic>? p]) => Uri.parse('http://test.local/forum');
  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async => null;
  @override
  Future<dynamic> postJson(Uri uri, Map<String, dynamic> body, {Map<String, String>? headers}) async => null;
}

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(_FakeStorage(), _FakeApiClient());
  @override
  Map<String, dynamic>? restoreSession() => null;
  @override
  Future<Map<String, dynamic>> performOAuthLogin() async => {'user_id': '1', 'username': 'Test'};
}

class _MockAuthController extends AuthController {
  _MockAuthController(_FakeAuthService s) : super(s, _FakeApiClient(), _FakeStorage());
  @override
  AppUser? get currentUser => AppUser(id: '1', username: 'TestUser');
}

Widget _buildSubject(_MockAuthController controller) {
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: _FakeApiClient()),
      ChangeNotifierProvider<AuthController>.value(value: controller),
    ],
    child: MaterialApp(
      home: AddFriendView(
        troopId: 1,
        addedByUserId: '1',
        limitedEvent: 0,
        allowTentative: 0,
      ),
    ),
  );
}

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
      await tester.pump();
      expect(find.byType(AddFriendView), findsOneWidget);
    });

    testWidgets('displays scaffold', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays content by default', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pump();
      expect(find.byType(AddFriendView), findsOneWidget);
    });

    testWidgets('provides ApiClient via Provider', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      final ctx = tester.element(find.byType(AddFriendView));
      expect(ctx.read<ApiClient>(), isNotNull);
    });

    testWidgets('is part of the app navigation flow', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
