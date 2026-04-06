import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/models/costume.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/sign_up_view.dart';

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

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(_FakeStorage());
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildSubject({
  int troopId = 1,
  String userId = '123',
  int limitedEvent = 0,
  int allowTentative = 1,
  List<dynamic> shifts = const [],
}) {
  return MaterialApp(
    home: SignUpView(
      troopId: troopId,
      userId: userId,
      limitedEvent: limitedEvent,
      allowTentative: allowTentative,
      api: _FakeApiClient(),
      shifts: shifts,
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('SignUpView', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(SignUpView), findsOneWidget);
    });

    testWidgets('displays scaffold', (tester) async {
      await tester.pumpWidget(_buildSubject());
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('accepts troopId parameter', (tester) async {
      await tester.pumpWidget(_buildSubject(troopId: 42));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpView), findsOneWidget);
    });

    testWidgets('accepts userId parameter', (tester) async {
      await tester.pumpWidget(_buildSubject(userId: 'user456'));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpView), findsOneWidget);
    });

    testWidgets('accepts limitedEvent parameter', (tester) async {
      await tester.pumpWidget(_buildSubject(limitedEvent: 1));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpView), findsOneWidget);
    });

    testWidgets('accepts allowTentative parameter', (tester) async {
      await tester.pumpWidget(_buildSubject(allowTentative: 0));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpView), findsOneWidget);
    });

    testWidgets('accepts shifts parameter', (tester) async {
      final shifts = [
        {'id': 1, 'name': 'Morning'},
        {'id': 2, 'name': 'Evening'},
      ];
      await tester.pumpWidget(_buildSubject(shifts: shifts));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpView), findsOneWidget);
    });

    testWidgets('accepts api client', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(SignUpView), findsOneWidget);
    });

    testWidgets('provides app bar', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
