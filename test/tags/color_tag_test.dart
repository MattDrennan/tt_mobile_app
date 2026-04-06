import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/tags/color_tag.dart';

void main() {
  late ColorTag tag;
  const baseStyle = TextStyle(fontSize: 14);

  setUp(() {
    tag = ColorTag();
  });

  // ── HexColor.fromHex ──────────────────────────────────────────────────────

  group('HexColor.fromHex', () {
    test('returns a Color instance for 6-digit hex without #', () {
      expect(HexColor.fromHex('FF0000'), isA<Color>());
    });

    test('returns a Color instance for 6-digit hex with # prefix', () {
      expect(HexColor.fromHex('#00FF00'), isA<Color>());
    });

    test('does not throw on valid 6-digit hex', () {
      expect(() => HexColor.fromHex('0000FF'), returnsNormally);
    });

    test('two calls with the same hex produce equal colors', () {
      expect(HexColor.fromHex('AABBCC'), equals(HexColor.fromHex('AABBCC')));
    });

    test('produces different colors for different hex strings', () {
      expect(
        HexColor.fromHex('FF0000'),
        isNot(equals(HexColor.fromHex('00FF00'))),
      );
    });
  });

  // ── isValidHexColor ───────────────────────────────────────────────────────

  group('ColorTag.isValidHexColor', () {
    test('returns true for 6-digit hex with #', () {
      expect(tag.isValidHexColor('#AABBCC'), isTrue);
    });

    test('returns true for 6-digit hex without #', () {
      expect(tag.isValidHexColor('AABBCC'), isTrue);
    });

    test('returns true for lowercase hex', () {
      expect(tag.isValidHexColor('aabbcc'), isTrue);
    });

    test('returns false for 3-digit shorthand', () {
      expect(tag.isValidHexColor('#FFF'), isFalse);
    });

    test('returns false for named colors', () {
      expect(tag.isValidHexColor('red'), isFalse);
    });

    test('returns false for empty string', () {
      expect(tag.isValidHexColor(''), isFalse);
    });

    test('returns false for invalid hex characters', () {
      expect(tag.isValidHexColor('#GGGGGG'), isFalse);
    });
  });

  // ── resolveColor ──────────────────────────────────────────────────────────

  group('ColorTag.resolveColor', () {
    test('resolves hex color to a non-null Color', () {
      final color = tag.resolveColor('#FF0000');
      expect(color, isNotNull);
      expect(color, isA<Color>());
    });

    test('resolves named color "red"', () {
      expect(tag.resolveColor('red'), Colors.red);
    });

    test('resolves named color "blue"', () {
      expect(tag.resolveColor('blue'), Colors.blue);
    });

    test('resolves named color case-insensitively', () {
      expect(tag.resolveColor('RED'), Colors.red);
      expect(tag.resolveColor('Blue'), Colors.blue);
    });

    test('returns null for unknown color', () {
      expect(tag.resolveColor('notacolor'), isNull);
    });

    test('returns null for empty string', () {
      expect(tag.resolveColor(''), isNull);
    });
  });

  // ── transformStyle ────────────────────────────────────────────────────────

  group('ColorTag.transformStyle', () {
    test('applies a color to text style when given a hex attribute', () {
      final result = tag.transformStyle(baseStyle, {'#FF0000': ''});
      expect(result.color, isNotNull);
      // A color was applied — different from the original style
      expect(result.color, isNot(equals(baseStyle.color)));
    });

    test('applies named color to text style', () {
      final result = tag.transformStyle(baseStyle, {'red': ''});
      expect(result.color, Colors.red);
    });

    test('returns original style when attributes are null', () {
      final result = tag.transformStyle(baseStyle, null);
      expect(result, baseStyle);
    });

    test('returns original style when attributes are empty', () {
      final result = tag.transformStyle(baseStyle, {});
      expect(result, baseStyle);
    });

    test('returns original style for unknown color', () {
      final result = tag.transformStyle(baseStyle, {'notacolor': ''});
      expect(result, baseStyle);
    });
  });
}
