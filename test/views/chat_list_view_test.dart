import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/controllers/auth_controller.dart';
import 'package:tt_mobile_app/models/app_user.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/auth_service.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/chat_list_view.dart';

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
  _MockAuthController() : super(_FakeAuthService(), _FakeApiClient(), _FakeStorage());
  @override
  AppUser? get currentUser => AppUser(id: '1', username: 'TestUser');
}

Widget _buildSubject(_MockAuthController auth) {
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: _FakeApiClient()),
      ChangeNotifierProvider<AuthController>.value(value: auth),
    ],
    child: const MaterialApp(home: ChatListView()),
  );
}

void main() {
  late _MockAuthController auth;

  setUp(() => auth = _MockAuthController());

  group('ChatListView', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_buildSubject(auth));
      await tester.pump();
      expect(find.byType(ChatListView), findsOneWidget);
    });

    testWidgets('displays scaffold', (tester) async {
      await tester.pumpWidget(_buildSubject(auth));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('provides AuthController via Provider', (tester) async {
      await tester.pumpWidget(_buildSubject(auth));
      final ctx = tester.element(find.byType(ChatListView));
      expect(ctx.read<AuthController>(), isNotNull);
    });

    testWidgets('provides app bar', (tester) async {
      await tester.pumpWidget(_buildSubject(auth));
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('is part of the messaging flow', (tester) async {
      await tester.pumpWidget(_buildSubject(auth));
      await tester.pump();
      expect(find.byType(Material), findsWidgets);
    });
  });
}
