// Run via: scripts/take_screenshots.sh [device-id]
//
// Seeds a fake session into Hive before the app starts, bypassing the
// XenForo OAuth browser flow.  API calls to sub-screens will fail gracefully
// with the placeholder key and show empty-state UI — that is intentional for
// screenshots captured without live credentials.
//
// To capture screens with real data, log in manually on the target device
// once (Hive persists the session), then comment out the seedSession() call
// below.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:tt_mobile_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture app screenshots', (tester) async {
    await _seedSession();

    await app.main();
    await tester.pumpAndSettle();

    // 01 — Home
    await binding.takeScreenshot('01_home');

    // 02 — Troop List
    await tester.tap(find.text('View Troops'));
    await tester.pumpAndSettle();
    await _waitForNetwork();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02_troop_list');

    await tester.pageBack();
    await tester.pumpAndSettle();

    // 03 — My Troops
    await tester.tap(find.text('My Troops'));
    await tester.pumpAndSettle();
    await _waitForNetwork();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03_my_troops');

    await tester.pageBack();
    await tester.pumpAndSettle();

    // 04 — Chat
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await _waitForNetwork();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04_chat_list');

    await tester.pageBack();
    await tester.pumpAndSettle();

    // 00 — Login (captured last via logout so the session clears cleanly)
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('00_login');
  });
}

/// Seeds a placeholder authenticated session into Hive so the auth gate
/// routes to HomeView instead of LoginView.
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

/// Waits for in-flight network requests to resolve before taking a screenshot.
Future<void> _waitForNetwork() =>
    Future.delayed(const Duration(seconds: 4));
