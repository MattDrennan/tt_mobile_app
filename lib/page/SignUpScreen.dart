import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatefulWidget {
  final int troopid;
  final int limitedEvent;
  final int allowTentative;

  const SignUpScreen(
      {super.key,
      required this.troopid,
      required this.limitedEvent,
      required this.allowTentative});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  int? selectedOption = 0;
  String? selectedCostume;
  String? backupCostume;

  /// Fetch costumes dynamically for the dropdown
  Future<List<String>> fetchCostumes(String? filter) async {
    // Open the Hive box
    final box = Hive.box('TTMobileApp');

    // Retrieve and decode user data
    final rawData = box.get('userData');
    final userData = json.decode(rawData);

    print(userData['user']['user_id'].toString());

    final response = await http.get(
      Uri.parse(
          'https://www.fl501st.com/troop-tracker/mobileapi.php?action=get_costumes_for_trooper&trooperid=${userData['user']['user_id'].toString()}&friendid=0'),
    );

    print(response.body);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map<String>(
              (costume) => '${costume['abbreviation']}${costume['name']}')
          .toList();
    } else {
      throw Exception('Failed to load costumes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<int>(
              value: selectedOption,
              items: [
                if (widget.limitedEvent != 1) ...[
                  DropdownMenuItem<int>(
                    value: 0,
                    child: Text("I'll be there!"),
                  ),
                  if (widget.allowTentative == 1)
                    DropdownMenuItem<int>(
                      value: 2,
                      child: Text("Tentative"),
                    ),
                ] else
                  DropdownMenuItem<int>(
                    value: 5,
                    child: Text("Request to attend (Pending)"),
                  ),
              ],
              onChanged: (int? newValue) {
                setState(() {
                  selectedOption = newValue;
                });
              },
              isExpanded: true,
              underline: Container(
                height: 2,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Costume:', style: TextStyle(fontSize: 16)),
            DropdownSearch<String>(
              items: (String? filter, _) => fetchCostumes(filter),
              itemAsString: (item) => item,
              selectedItem: selectedCostume,
              onChanged: (value) {
                setState(() {
                  selectedCostume = value;
                });
              },
              popupProps: PopupProps.menu(
                showSearchBox: true,
                fit: FlexFit.loose,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Backup Costume:', style: TextStyle(fontSize: 16)),
            DropdownSearch<String>(
              items: (String? filter, _) => fetchCostumes(filter),
              itemAsString: (item) => item,
              selectedItem: backupCostume,
              onChanged: (value) {
                setState(() {
                  backupCostume = value;
                });
              },
              popupProps: PopupProps.menu(
                showSearchBox: true,
                fit: FlexFit.loose,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (selectedOption == null ||
                    selectedCostume == null ||
                    backupCostume == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Please select all options before signing up!'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Signed up: $selectedOption - $selectedCostume (Backup: $backupCostume)'),
                    ),
                  );
                }
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
