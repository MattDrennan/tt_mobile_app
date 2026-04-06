import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/custom/info_row.dart';

Widget _build(InfoRow widget) =>
    MaterialApp(home: Scaffold(body: widget));

void main() {
  group('InfoRow', () {
    testWidgets('renders label with colon and plain value', (tester) async {
      await tester.pumpWidget(_build(
        const InfoRow(label: 'Venue', value: 'Convention Center'),
      ));
      expect(find.text('Venue:'), findsOneWidget);
      expect(find.text('Convention Center'), findsOneWidget);
    });

    testWidgets('shows N/A when value is null', (tester) async {
      await tester.pumpWidget(_build(
        const InfoRow(label: 'Website', value: null),
      ));
      expect(find.text('N/A'), findsOneWidget);
    });

    testWidgets('shows N/A when value is empty string', (tester) async {
      await tester.pumpWidget(_build(
        const InfoRow(label: 'Website', value: ''),
      ));
      expect(find.text('N/A'), findsOneWidget);
    });

    testWidgets('renders plain text style for non-URL value', (tester) async {
      await tester.pumpWidget(_build(
        const InfoRow(label: 'Venue', value: 'Some Place'),
      ));
      // Plain value should not be wrapped in a GestureDetector
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('renders link style for URL value', (tester) async {
      await tester.pumpWidget(_build(
        const InfoRow(label: 'Website', value: 'https://example.com'),
      ));
      // URL should be wrapped in a GestureDetector
      expect(find.byType(GestureDetector), findsOneWidget);
      expect(find.text('https://example.com'), findsOneWidget);
    });

    testWidgets('renders link for URL without scheme', (tester) async {
      await tester.pumpWidget(_build(
        const InfoRow(label: 'Link', value: 'www.example.com'),
      ));
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('applies custom labelStyle when provided', (tester) async {
      const customStyle = TextStyle(color: Colors.red);
      await tester.pumpWidget(_build(
        const InfoRow(
          label: 'Label',
          value: 'Value',
          labelStyle: customStyle,
        ),
      ));
      final text = tester.widget<Text>(find.text('Label:'));
      expect(text.style?.color, Colors.red);
    });

    testWidgets('applies custom valueStyle when provided', (tester) async {
      const customStyle = TextStyle(color: Colors.green);
      await tester.pumpWidget(_build(
        const InfoRow(
          label: 'Label',
          value: 'Value',
          valueStyle: customStyle,
        ),
      ));
      final text = tester.widget<Text>(find.text('Value'));
      expect(text.style?.color, Colors.green);
    });
  });
}
