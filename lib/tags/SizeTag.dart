import 'package:flutter/material.dart';
import 'package:flutter_bbcode/flutter_bbcode.dart';

class SizeTag extends StyleTag {
  SizeTag() : super('size');

  @override
  TextStyle transformStyle(
      TextStyle oldStyle, Map<String, String>? attributes) {
    if (attributes == null || attributes.isEmpty) {
      return oldStyle;
    }

    String? sizeValue = attributes.entries.first.value;
    double? fontSize;

    try {
      fontSize = double.parse(sizeValue);
    } catch (e) {
      fontSize = null; // Invalid size input
    }

    if (fontSize != null && fontSize > 0) {
      return oldStyle.copyWith(fontSize: fontSize);
    }

    // Fallback to default size if parsing fails
    return oldStyle;
  }
}
