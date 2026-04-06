import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/tags/url_tag.dart';

void main() {
  group('UrlTag.transformStyle', () {
    const baseStyle = TextStyle(fontSize: 14, color: Colors.black);

    test('applies underline decoration', () {
      final tag = UrlTag();
      final result = tag.transformStyle(baseStyle, null);
      expect(result.decoration, TextDecoration.underline);
    });

    test('applies blue color', () {
      final tag = UrlTag();
      final result = tag.transformStyle(baseStyle, null);
      expect(result.color, Colors.blue);
    });

    test('preserves other style properties', () {
      final tag = UrlTag();
      const input = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
      final result = tag.transformStyle(input, null);
      expect(result.fontSize, 16.0);
      expect(result.fontWeight, FontWeight.bold);
    });

    test('applies same style regardless of attributes', () {
      final tag = UrlTag();
      final withAttrs = tag.transformStyle(baseStyle, {'https://example.com': ''});
      final withNull = tag.transformStyle(baseStyle, null);
      expect(withAttrs.color, withNull.color);
      expect(withAttrs.decoration, withNull.decoration);
    });

    test('can be constructed with onTap callback', () {
      String? captured;
      final tag = UrlTag(onTap: (url) => captured = url);
      // Verify construction doesn't throw
      expect(tag, isNotNull);
      expect(captured, isNull);
    });
  });
}
