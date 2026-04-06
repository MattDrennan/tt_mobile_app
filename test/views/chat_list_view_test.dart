import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/controllers/chat_controller.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/chat_list_view.dart';

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
  _MockChatController() : super(ApiClient(_FakeStorage()));

  @override
  Future<void> fetchChatRooms() async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildSubject(_MockChatController controller) {
  return ChangeNotifierProvider<ChatController>.value(
    value: controller,
    child: const MaterialApp(home: ChatListView()),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockChatController controller;

  setUp(() {
    controller = _MockChatController();
  });

  group('ChatListView', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListView), findsOneWidget);
    });

    testWidgets('displays scaffold', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('uses ChatController from Provider', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      final context = tester.element(find.byType(ChatListView));
      final watchedController = context.read<ChatController>();
      expect(watchedController, isNotNull);
    });

    testWidgets('provides app bar', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('is part of the messaging flow', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(Material), findsWidgets);
    });
  });
}
