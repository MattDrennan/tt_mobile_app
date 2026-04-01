import 'package:flutter/material.dart';
import 'package:flutter_bbcode/flutter_bbcode.dart';

class ColorTag extends StyleTag {
  ColorTag() : super('color');

  @override
  TextStyle transformStyle(
      TextStyle oldStyle, Map<String, String>? attributes) {
    if (attributes?.entries.isEmpty ?? true) {
      return oldStyle;
    }

    String? colorValue = attributes?.entries.first.key;
    if (colorValue == null) {
      return oldStyle;
    }

    // Attempt to resolve the color value
    Color? resolvedColor = resolveColor(colorValue);
    if (resolvedColor == null) {
      return oldStyle;
    }

    return oldStyle.copyWith(color: resolvedColor);
  }

  // Resolves a color from hex or named colors
  Color? resolveColor(String colorValue) {
    // Try to parse as hex
    if (isValidHexColor(colorValue)) {
      return HexColor.fromHex(colorValue);
    }

    // Check for named colors
    final namedColor = namedColors[colorValue.toLowerCase()];
    if (namedColor != null) {
      return namedColor;
    }

    // Return null if the color is invalid
    return null;
  }

  bool isValidHexColor(String hexColor) {
    final hexRegex = RegExp(r'^#?([0-9a-fA-F]{6})$');
    return hexRegex.hasMatch(hexColor);
  }

  // A map of named colors to their Flutter Color equivalents
  final Map<String, Color> namedColors = {
    'red': Colors.red,
    'blue': Colors.blue,
    'green': Colors.green,
    'yellow': Colors.yellow,
    'black': Colors.black,
    'white': Colors.white,
    'gray': Colors.grey,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'pink': Colors.pink,
    'brown': Colors.brown,
    'cyan': Colors.cyan,
    'lime': Colors.lime,
    // Add more named colors as needed
  };
}

class HexColor {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.startsWith('#')) {
      buffer.write(hexString.replaceFirst('#', ''));
    } else {
      buffer.write(hexString);
    }
    if (buffer.length == 6) {
      buffer.write('FF'); // Add full opacity if missing
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
