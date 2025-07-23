import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tt_mobile_app/main.dart';

class ClosedPage extends StatelessWidget {
  final String? message;

  const ClosedPage({super.key, this.message});

  Future<void> checkIfOpenAndGoHome(BuildContext context) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                'https://www.fl501st.com/troop-tracker/mobileapi.php?action=is_closed'),
          )
          .timeout(const Duration(seconds: 10));

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic> && data['isWebsiteClosed'] == 0) {
          // Website is open now, go back to home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'Troop Tracker'),
            ),
          );
        } else {
          // Still closed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['siteMessage'] ?? 'Still closed')),
          );
        }
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),
              Text(
                'Troop Tracker is Currently Closed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(
                  message!,
                  style: TextStyle(fontSize: 16, color: Colors.grey[300]),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text("Try Again"),
                onPressed: () {
                  checkIfOpenAndGoHome(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
