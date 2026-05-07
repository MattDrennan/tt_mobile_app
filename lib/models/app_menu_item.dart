import 'package:flutter/material.dart';

/// Represents a single tab in the bottom navigation bar.
class AppMenuItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const AppMenuItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
