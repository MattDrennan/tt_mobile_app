import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:tt_mobile_app/page/AccessGatePage.dart';
import 'package:tt_mobile_app/page/ClosedPage.dart';
import 'package:tt_mobile_app/page/LoginPage.dart';

// Global
types.User user = const types.User(id: 'user');

Future<void> logout(BuildContext context) async {
  final box = Hive.box('TTMobileApp');

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Logging out...')),
  );

  final response = await http.post(
    Uri.parse('https://www.fl501st.com/troop-tracker/mobileapi.php'),
    body: {
      'action': 'logoutFCM',
      'apiKey': box.get('apiKey') ?? '',
      'fcm': box.get('fcm') ?? '',
    },
    headers: {
      'API-Key': box.get('apiKey') ?? '',
    },
  );

  if (response.statusCode == 200) {
    print('Success');
    await box.clear(); // Clear all data, ensuring complete logout
  } else {
    print('Fail');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('An error occurred while logging out!')),
    );
  }

  Future.delayed(const Duration(seconds: 1), () {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  });
}

Future<void> fetchSiteStatus(BuildContext context) async {
  try {
    final response = await http
        .get(
          Uri.parse(
              'https://www.fl501st.com/troop-tracker/mobileapi.php?action=is_closed'),
        )
        .timeout(const Duration(seconds: 10)); // Set timeout

    if (!context.mounted) return; // Ensure widget is still in tree

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data is Map<String, dynamic> &&
          data['isWebsiteClosed'] == 1 &&
          data['siteMessage'] != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClosedPage(message: data['siteMessage']),
          ),
        );
      }
    } else {
      throw Exception(
          'Failed to load site status. Status code: ${response.statusCode}');
    }
  } on TimeoutException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request timed out. Please try again.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

// Returns true if user is allowed in (not banned AND has access), false otherwise.
// If blocked, it routes to AccessGatePage with a message.
Future<bool> fetchUserStatus(BuildContext context,
    {required int trooperId}) async {
  try {
    final uri = Uri.parse(
      'https://www.fl501st.com/troop-tracker/mobileapi.php?action=user_status&trooperid=$trooperId',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (!context.mounted) return false;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Defensive parsing for truthy values
      bool _asBool(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

      if (data is Map<String, dynamic>) {
        final isBanned = _asBool(data['isBanned']);
        final canAccess = _asBool(data['canAccess']);
        final msg = (data['message'] as String?) ??
            (data['error'] as String?) ??
            (isBanned
                ? 'Your forum account is banned.'
                : 'You do not have access at this time.');

        // Allowed if the endpoint is OK, not banned, and can access
        if (!isBanned && canAccess) {
          return true; // caller decides where to go next
        } else {
          // Route to your access gate (blocked screen) with reason
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AccessGatePage(
                message: msg,
                trooperId: trooperId,
              ),
            ),
          );
          return false;
        }
      } else {
        throw Exception('Unexpected response.');
      }
    } else {
      throw Exception('Failed to load user status.');
    }
  } on TimeoutException {
    return false;
  } catch (e) {
    return false;
  }
}

Future<bool> getToken(String userId) async {
  // Retrieve APNS token
  String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();

  if (apnsToken == null) {
    print('Push notifications may not work.');
    return true;
  } else {
    // APNS Token
    print('APNS token: $apnsToken');

    // Open the Hive box
    final box = Hive.box('TTMobileApp');

    // Retrieve FCM token
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      print('FCM Token: $fcmToken');

      final response = await http.post(
        Uri.parse('https://www.fl501st.com/troop-tracker/mobileapi.php'),
        body: {
          'action': 'saveFCM',
          'userid': userId,
          'fcm': fcmToken,
        },
        headers: {
          'API-Key': box.get('apiKey') ?? '',
        },
      );

      if (response.statusCode == 200) {
        // Save FCM
        final box = Hive.box('TTMobileApp');
        box.put('fcm', fcmToken);
        print('Success');
        return true;
      } else {
        print('Fail');
        return false;
      }
    } else {
      print('Failed to retrieve FCM token.');
      return false;
    }
  }
}

String formatDate(String dateStr) {
  try {
    // Parse the date string
    DateTime parsedDate = DateTime.parse(dateStr);

    // Format to 'MMM d, y' (e.g., "Mar 15, 2025")
    return DateFormat('MMM d, y').format(parsedDate);
  } catch (e) {
    print('Date parsing error: $e');
    return dateStr; // Return the original if parsing fails
  }
}

String formatDateWithTime(String start, String end) {
  try {
    DateTime startDate = DateTime.parse(start);
    DateTime endDate = DateTime.parse(end);

    String formattedStart = DateFormat('MMM d, y h:mm a').format(startDate);
    String formattedEnd = DateFormat('h:mm a').format(endDate);

    return '$formattedStart to $formattedEnd';
  } catch (e) {
    print('Error parsing date: $e');
    return start.isNotEmpty ? start : 'Invalid date';
  }
}
