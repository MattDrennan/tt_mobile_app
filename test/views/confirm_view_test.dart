import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/confirm_view.dart';

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

Widget _buildSubject() {
  return Provider<ApiClient>.value(
    value: _FakeApiClient(),
    child: const MaterialApp(home: ConfirmView(trooperId: 1)),
  );
}

void main() {
  group('ConfirmView', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump();
      expect(find.byType(ConfirmView), findsOneWidget);
    });

    testWidgets('displays scaffold', (tester) async {
      await tester.pumpWidget(_buildSubject());
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('may show a progress indicator while loading', (tester) async {
      await tester.pumpWidget(_buildSubject());
      // Immediately after pump, the view may show a spinner while its
      // controller fetches data — we only verify the view is present.
      await tester.pump();
      expect(find.byType(ConfirmView), findsOneWidget);
    });

    testWidgets('provides ApiClient via Provider', (tester) async {
      await tester.pumpWidget(_buildSubject());
      final ctx = tester.element(find.byType(ConfirmView));
      expect(ctx.read<ApiClient>(), isNotNull);
    });
  });
}
