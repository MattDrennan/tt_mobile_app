import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bbcode/flutter_bbcode.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlTag extends StyleTag {
  final Function(String)? onTap;

  UrlTag({this.onTap}) : super("url");

  @override
  void onTagStart(FlutterRenderer renderer) {
    late String url;

    // Extract the URL from the tag attributes or children
    if (renderer.currentTag?.attributes.isNotEmpty ?? false) {
      url = renderer.currentTag!.attributes.keys.first;
    } else if (renderer.currentTag?.children.isNotEmpty ?? false) {
      url = renderer.currentTag!.children.first.textContent;
    } else {
      url = "URL is missing!";
    }

    // Push a custom tap action
    renderer.pushTapAction(() async {
      if (onTap != null) {
        onTap!(url); // Use the custom onTap if provided
      } else {
        // Open the URL using url_launcher
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          log("Could not launch URL: $url");
        }
      }
    });

    super.onTagStart(renderer);
  }

  @override
  void onTagEnd(FlutterRenderer renderer) {
    renderer.popTapAction();
    super.onTagEnd(renderer);
  }

  @override
  TextStyle transformStyle(
      TextStyle oldStyle, Map<String, String>? attributes) {
    return oldStyle.copyWith(
      decoration: TextDecoration.underline, // Underline links
      color: Colors.blue, // Default link color
    );
  }
}
