import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/custom/location_widget.dart';

Widget _build(LocationWidget widget) =>
    MaterialApp(home: Scaffold(body: widget));

void main() {
  group('LocationWidget', () {
    testWidgets('displays the provided location text', (tester) async {
      await tester.pumpWidget(_build(
        const LocationWidget(location: 'Disney World, Orlando FL'),
      ));
      expect(find.text('Disney World, Orlando FL'), findsOneWidget);
    });

    testWidgets('shows "No location provided." when location is null',
        (tester) async {
      await tester.pumpWidget(_build(
        const LocationWidget(location: null),
      ));
      expect(find.text('No location provided.'), findsOneWidget);
    });

    testWidgets('decodes HTML entities in location', (tester) async {
      await tester.pumpWidget(_build(
        const LocationWidget(location: 'Convention &amp; Center'),
      ));
      expect(find.text('Convention & Center'), findsOneWidget);
    });

    testWidgets('is wrapped in a GestureDetector (tappable)', (tester) async {
      await tester.pumpWidget(_build(
        const LocationWidget(location: '123 Main St'),
      ));
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('renders with blue underlined text style', (tester) async {
      await tester.pumpWidget(_build(
        const LocationWidget(location: '123 Main St'),
      ));
      final text = tester.widget<Text>(find.text('123 Main St'));
      expect(text.style?.color, Colors.blue);
      expect(text.style?.decoration, TextDecoration.underline);
    });

    testWidgets('tapping null location shows snack bar', (tester) async {
      await tester.pumpWidget(_build(
        const LocationWidget(location: null),
      ));
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
