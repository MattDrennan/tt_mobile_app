import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/widgets/tt_app_bar.dart';

Widget _buildWithContext(String title) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        appBar: buildAppBar(context, title),
      ),
    ),
  );
}

void main() {
  group('buildAppBar', () {
    testWidgets('displays the provided title', (tester) async {
      await tester.pumpWidget(_buildWithContext('Troop Tracker'));
      expect(find.text('Troop Tracker'), findsOneWidget);
    });

    testWidgets('shows a home icon button', (tester) async {
      await tester.pumpWidget(_buildWithContext('Test'));
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('home button does not throw when tapped on first route',
        (tester) async {
      await tester.pumpWidget(_buildWithContext('Test'));
      // Tapping on the first route's home button calls popUntil which is a no-op
      expect(
        () async => tester.tap(find.byIcon(Icons.home)),
        returnsNormally,
      );
    });

    testWidgets('returns an AppBar widget', (tester) async {
      await tester.pumpWidget(_buildWithContext('My Title'));
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
