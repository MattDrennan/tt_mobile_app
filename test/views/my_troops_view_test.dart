import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/controllers/home_controller.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/my_troops_view.dart';

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

class _MockHomeController extends HomeController {
  bool _isLoading = false;

  _MockHomeController() : super(ApiClient(_FakeStorage()));

  @override
  bool get isLoading => _isLoading;

  void setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildSubject(_MockHomeController controller) {
  return ChangeNotifierProvider<HomeController>.value(
    value: controller,
    child: const MaterialApp(home: MyTroopsView()),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockHomeController controller;

  setUp(() {
    controller = _MockHomeController();
  });

  group('MyTroopsView', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(MyTroopsView), findsOneWidget);
    });

    testWidgets('displays scaffold', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('uses HomeController from Provider', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      final context = tester.element(find.byType(MyTroopsView));
      final watchedController = context.read<HomeController>();
      expect(watchedController, isNotNull);
    });

    testWidgets('provides app bar', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('handles loading state', (tester) async {
      controller.setLoading(true);
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      controller.setLoading(false);
      await tester.pumpAndSettle();
      expect(find.byType(MyTroopsView), findsOneWidget);
    });
  });
}
