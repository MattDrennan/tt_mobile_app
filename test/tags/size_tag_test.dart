import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/tags/size_tag.dart';

void main() {
  late SizeTag tag;
  const baseStyle = TextStyle(fontSize: 14);

  setUp(() {
    tag = SizeTag();
  });

  group('SizeTag.transformStyle', () {
    test('applies valid font size from attribute value', () {
      final result = tag.transformStyle(baseStyle, {'size': '20'});
      expect(result.fontSize, 20.0);
    });

    test('applies fractional font size', () {
      final result = tag.transformStyle(baseStyle, {'size': '16.5'});
      expect(result.fontSize, 16.5);
    });

    test('returns original style when attributes are null', () {
      final result = tag.transformStyle(baseStyle, null);
      expect(result, baseStyle);
    });

    test('returns original style when attributes are empty', () {
      final result = tag.transformStyle(baseStyle, {});
      expect(result, baseStyle);
    });

    test('returns original style when size value is not a number', () {
      final result = tag.transformStyle(baseStyle, {'size': 'large'});
      expect(result, baseStyle);
    });

    test('returns original style when size is zero', () {
      final result = tag.transformStyle(baseStyle, {'size': '0'});
      expect(result, baseStyle);
    });

    test('returns original style when size is negative', () {
      final result = tag.transformStyle(baseStyle, {'size': '-5'});
      expect(result, baseStyle);
    });

    test('preserves other style properties when applying size', () {
      const bold = TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
      final result = tag.transformStyle(bold, {'size': '18'});
      expect(result.fontSize, 18.0);
      expect(result.fontWeight, FontWeight.bold);
    });
  });
}
