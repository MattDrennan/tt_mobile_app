import 'package:flutter/material.dart';

/// Reusable app bar with a home button that pops to the first route.
AppBar buildAppBar(BuildContext context, String title) {
  return AppBar(
    title: Text(title),
    actions: [
      IconButton(
        icon: const Icon(Icons.home),
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    ],
  );
}
