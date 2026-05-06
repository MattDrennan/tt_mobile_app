import 'package:flutter/material.dart';

/// Single source of truth for all app-wide configuration.
/// Change the URL, colors, or name here — nowhere else.
class AppConfig {
  AppConfig._();

  static const String appName = 'Troop Tracker';

  // The Tracker site loaded in the WebView
  static const String trackerUrl = 'https://test.fl501st.com/';

  // Domain used to distinguish internal vs external navigation
  static const String trackerDomain = 'fl501st.com';

  // Dark navy — used for splash background and WebView background
  static const Color splashBackgroundColor = Color(0xFF00131F);

  // Primary brand blue — used for progress indicators and theme seed
  static const Color primaryColor = Color(0xFF006899);
}
