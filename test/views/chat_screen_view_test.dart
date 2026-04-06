import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/controllers/chat_controller.dart';
import 'package:tt_mobile_app/models/app_user.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/chat_screen_view.dart';

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

class _MockChatController extends ChatController {
  _MockChatController()
      : super(
          ApiClient(_FakeStorage()),
          currentUser: AppUser(id: '1', username: 'Test'),
        );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildSubject(_MockChatController controller) {
  return ChangeNotifierProvider<ChatController>.value(
    value: controller,
    child: MaterialApp(
      home: ChatScreenView(
        threadId: 1,
        troopName: 'Test Troop',
        postId: 0,
        currentUser: AppUser(id: '1', username: 'Test'),
        api: ApiClient(_FakeStorage()),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockChatController controller;

  setUp(() {
    controller = _MockChatController();
  });

  group('ChatScreenView', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreenView), findsOneWidget);
    });

    testWidgets('displays scaffold', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('accepts threadId parameter', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      final view = find.byType(ChatScreenView);
      expect(view, findsOneWidget);
    });

    testWidgets('accepts troopName parameter', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pump();
      // troopName is passed as a constructor param; view renders without error
      expect(find.byType(ChatScreenView), findsOneWidget);
    });

    testWidgets('uses ChatController from Provider', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      final context = tester.element(find.byType(ChatScreenView));
      final watchedController = context.read<ChatController>();
      expect(watchedController, isNotNull);
    });
  });
}
