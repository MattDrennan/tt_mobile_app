import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tt_mobile_app/controllers/confirm_controller.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';
import 'package:tt_mobile_app/views/confirm_view.dart';

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

class _MockConfirmController extends ConfirmController {
  bool _isLoading = false;
  String? _error;

  _MockConfirmController() : super(ApiClient(_FakeStorage()));

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

Widget _buildSubject(_MockConfirmController controller) {
  return ChangeNotifierProvider<ConfirmController>.value(
    value: controller,
    child: const MaterialApp(home: ConfirmView()),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockConfirmController controller;

  setUp(() {
    controller = _MockConfirmController();
  });

  group('ConfirmView', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmView), findsOneWidget);
    });

    testWidgets('displays scaffold', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      controller.setLoading(true);
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when set', (tester) async {
      controller.setError('Confirmation failed');
      await tester.pumpWidget(_buildSubject(controller));
      await tester.pumpAndSettle();
      expect(find.textContaining('Confirmation'), findsWidgets);
    });

    testWidgets('uses ConfirmController from Provider', (tester) async {
      await tester.pumpWidget(_buildSubject(controller));
      final context = tester.element(find.byType(ConfirmView));
      final watchedController = context.read<ConfirmController>();
      expect(watchedController, isNotNull);
    });
  });
}
