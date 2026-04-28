// Run via: scripts/take_screenshots.sh [device-id]
//
// Uses FakeApiClient (via main_screenshot.dart) so every screen renders with
// realistic fixture data — no network calls, no real credentials needed.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:tt_mobile_app/main_screenshot.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture app screenshots', (tester) async {
    await _seedSession();

    await app.main();
    await tester.pumpAndSettle();

    // 01 — Home
    await binding.takeScreenshot('01_home');

    // ── Troop List → Event → Chat ─────────────────────────────────────────────

    await tester.tap(find.text('View Troops'));
    await tester.pumpAndSettle();

    // 02 — Troop List
    await binding.takeScreenshot('02_troop_list');

    await tester.tap(find.text('Star Wars Celebration 2025'));
    await tester.pumpAndSettle();

    // 03 — Event detail
    await binding.takeScreenshot('03_event');

    await tester.ensureVisible(find.text('Go To Discussion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go To Discussion'));
    await tester.pumpAndSettle();
    // addPostFrameCallback → openRoom → fetchMessages is async; yield to the
    // Dart event loop so the Future resolves, then render the resulting frame.
    await Future.delayed(const Duration(milliseconds: 500));
    await tester.pump();

    // 04 — Chat screen
    await binding.takeScreenshot('04_chat_screen');

    // Pop back to Home via the home-icon button (avoids pageBack() which
    // requires a Cupertino back button that isn't always present on iOS).
    await _tapHomeIcon(tester);
    await tester.pumpAndSettle();

    // ── My Troops ─────────────────────────────────────────────────────────────

    await tester.tap(find.text('My Troops'));
    await tester.pumpAndSettle();

    // 05 — My Troops
    await binding.takeScreenshot('05_my_troops');

    await _tapHomeIcon(tester);
    await tester.pumpAndSettle();

    // ── Chat List ─────────────────────────────────────────────────────────────

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    // 06 — Chat room list
    await binding.takeScreenshot('06_chat_list');

    await _tapHomeIcon(tester);
    await tester.pumpAndSettle();

    // ── Login (via logout) ────────────────────────────────────────────────────

    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // 00 — Login
    await binding.takeScreenshot('00_login');
  });
}

/// Taps the home icon in the app bar, which pops all routes back to root.
Future<void> _tapHomeIcon(WidgetTester tester) =>
    tester.tap(find.byIcon(Icons.home).last);

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
