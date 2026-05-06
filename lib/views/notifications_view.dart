import 'package:flutter/material.dart';

/// Native notifications screen.
/// Shows an empty state — no WebView involved.
/// Structure is ready to accept a NotificationsController and list
/// when push notification backend integration is added later.
class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 72,
            color: Colors.white24,
          ),
          SizedBox(height: 20),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Notifications will appear here.',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
