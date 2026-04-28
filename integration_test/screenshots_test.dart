// Run via: scripts/take_screenshots.sh [device-id]
//
// Uses FakeApiClient (via main_screenshot.dart) so every screen renders with
// realistic fixture data — no network calls, no real credentials needed.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:tt_mobile_app/main_screenshot.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture app screenshots', (tester) async {
    // Seed a logged-in session so the auth gate routes to HomeView instead of
    // LoginView, bypassing the XenForo OAuth browser flow.
    await _seedSession();

    await app.main();
    await tester.pumpAndSettle();

    // 01 — Home
    await binding.takeScreenshot('01_home');

    // 02 — Troop List (FakeApiClient returns instantly, no real wait needed)
    await tester.tap(find.text('View Troops'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02_troop_list');

    await tester.pageBack();
    await tester.pumpAndSettle();

    // 03 — My Troops
    await tester.tap(find.text('My Troops'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03_my_troops');

    await tester.pageBack();
    await tester.pumpAndSettle();

    // 04 — Chat
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04_chat_list');

    await tester.pageBack();
    await tester.pumpAndSettle();

    // 00 — Login (captured via logout so session clears cleanly)
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('00_login');
  });
}

Future<void> _seedSession() async {
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  final box = await Hive.openBox('TTMobileApp');
  await box.put(
    'userData',
    jsonEncode({
      'success': true,
      'apiKey': 'screenshot-placeholder',
      'user': {
        'user_id': '99999',
        'username': 'Demo Trooper',
        'avatar_urls': {'s': null},
        'tkid': null,
      },
    }),
  );
  await box.put('apiKey', 'screenshot-placeholder');
}
