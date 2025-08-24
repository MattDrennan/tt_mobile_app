import 'package:flutter/material.dart';
import 'package:tt_mobile_app/page/MyHomePage.dart';

AppBar buildAppBar(BuildContext context, String title) {
  return AppBar(
    title: Text(title),
    actions: [
      IconButton(
        icon: const Icon(Icons.home),
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MyHomePage(
                title: 'Troop Tracker',
              ), // Replace with your home screen widget
            ),
            (route) => false, // Remove all previous routes
          );
        },
      ),
    ],
  );
}
