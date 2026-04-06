import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/controllers/troop_controller.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/troop_list_view.dart';

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

class _MockTroopController extends TroopController {
  bool _isLoading = false;
  String _searchQuery = '';

  _MockTroopController() : super(ApiClient(_FakeStorage()));

  @override
  bool get isLoading => _isLoading;

  void setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  @override
  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  @override
  Future<void> fetchorganizations() async {}

  @override
  Future<void> fetchTroops(int orgId) async {}

  @override
  String iconForTroop(dynamic troop) => '⚔️';
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildSubject(_MockTroopController controller) {
  return ChangeNotifierProvider<ApiClient>.value(
    value: ApiClient(_FakeStorage()),
    child: ChangeNotifierProvider<TroopController>.value(
      value: controller,
      child: const MaterialApp(home: TroopListView()),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockTroopController controller;

  setUp(() {
    controller = _MockTroopController();
  });

  group('TroopListView', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(TroopListView), findsOneWidget);
    });

    testWidgets('displays scaffold', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('provides app bar', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('uses TroopController from Provider', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      final context = tester.element(find.byType(TroopListView));
      final watchedController = context.read<TroopController>();
      expect(watchedController, isNotNull);
    });

    testWidgets('handles loading state', (tester) async {
      controller.setLoading(true);
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      controller.setLoading(false);
      await tester.pumpAndSettle();
      expect(find.byType(TroopListView), findsOneWidget);
    });

    testWidgets('provides search functionality', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsWidgets);
    });
  });
}
