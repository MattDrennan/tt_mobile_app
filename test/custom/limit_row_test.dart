import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/custom/limit_row.dart';

Widget _build(LimitRow widget) =>
    MaterialApp(home: Scaffold(body: widget));

void main() {
  group('LimitRow', () {
    testWidgets('shows N/A when all fields are null', (tester) async {
      await tester.pumpWidget(_build(const LimitRow()));
      expect(find.text('N/A'), findsOneWidget);
    });

    testWidgets('shows N/A when all fields are empty strings', (tester) async {
      await tester.pumpWidget(_build(const LimitRow(
        total: '',
        clubs: '',
        extra: '',
      )));
      expect(find.text('N/A'), findsOneWidget);
    });

    testWidgets('renders a bullet point for total', (tester) async {
      await tester.pumpWidget(_build(const LimitRow(total: '20 troopers')));
      expect(find.text('20 troopers'), findsOneWidget);
      expect(find.text('• '), findsOneWidget);
    });

    testWidgets('renders separate bullet lines for each non-empty field',
        (tester) async {
      await tester.pumpWidget(_build(const LimitRow(
        total: 'Total: 10',
        clubs: 'Club A: 5',
        extra: 'Extra: 2',
      )));
      expect(find.text('Total: 10'), findsOneWidget);
      expect(find.text('Club A: 5'), findsOneWidget);
      expect(find.text('Extra: 2'), findsOneWidget);
      expect(find.text('• '), findsNWidgets(3));
    });

    testWidgets('splits newline-separated clubs into multiple bullets',
        (tester) async {
      await tester.pumpWidget(_build(const LimitRow(
        clubs: 'FL501\nAlpha\nBeta',
      )));
      expect(find.text('FL501'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('handles escaped \\n as newlines', (tester) async {
      await tester
          .pumpWidget(_build(const LimitRow(clubs: r'Line1\nLine2')));
      expect(find.text('Line1'), findsOneWidget);
      expect(find.text('Line2'), findsOneWidget);
    });

    testWidgets('trims whitespace from lines', (tester) async {
      await tester.pumpWidget(_build(const LimitRow(total: '  trimmed  ')));
      expect(find.text('trimmed'), findsOneWidget);
    });

    testWidgets('skips blank lines in split', (tester) async {
      await tester.pumpWidget(_build(const LimitRow(clubs: 'A\n\nB')));
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('• '), findsNWidgets(2));
    });
  });
}
