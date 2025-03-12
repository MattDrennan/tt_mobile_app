import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tt_mobile_app/main.dart';
import 'package:intl/intl.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['siteMessage'])),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyHomePage(title: 'Troop Tracker'),
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
