import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:tt_mobile_app/custom/AppBar.dart';
import 'package:tt_mobile_app/models/Costume.dart';
import 'package:tt_mobile_app/page/EventPage.dart';

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
  Costume? selectedCostume;
  Costume? backupCostume;

  /// Fetch costumes dynamically for the dropdown
  Future<List<Costume>> fetchCostumes(String? filter) async {
    final box = Hive.box('TTMobileApp');
    final rawData = box.get('userData');
    final userData = json.decode(rawData);

    final response = await http.get(
      Uri.parse(
          'https://www.fl501st.com/troop-tracker/mobileapi.php?action=get_costumes_for_trooper&trooperid=${userData['user']['user_id'].toString()}&friendid=0'),
      headers: {
        'API-Key': box.get('apiKey') ?? '',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map<Costume>((costume) => Costume(
                id: costume['id'],
                name: '${costume['abbreviation']}${costume['name']}',
              ))
          .toList();
    } else {
      throw Exception('Failed to load costumes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('TTMobileApp');
    final rawData = box.get('userData');
    final userData = json.decode(rawData);

    return Scaffold(
      appBar: buildAppBar(context, 'Sign Up'),
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
            DropdownSearch<Costume>(
              items: (String? filter, dynamic infiniteScrollProps) =>
                  fetchCostumes(filter),
              itemAsString: (Costume? costume) =>
                  costume?.name ?? '', // Display the name of the costume
              selectedItem: selectedCostume,
              compareFn: (Costume? item, Costume? selectedItem) =>
                  item?.id == selectedItem?.id,
              onChanged: (Costume? value) {
                setState(() {
                  selectedCostume = value; // Store the selected costume object
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
            DropdownSearch<Costume>(
              items: (String? filter, dynamic infiniteScrollProps) =>
                  fetchCostumes(filter),
              itemAsString: (Costume? costume) =>
                  costume?.name ?? '', // Display the name of the costume
              selectedItem: backupCostume,
              compareFn: (Costume? item, Costume? selectedItem) =>
                  item?.id == selectedItem?.id,
              onChanged: (Costume? value) {
                setState(() {
                  backupCostume =
                      value; // Store the selected back up costume object
                });
              },
              popupProps: PopupProps.menu(
                showSearchBox: true,
                fit: FlexFit.loose,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedOption == null || selectedCostume == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please select a costume before signing up!'),
                      ),
                    );
                  } else {
                    final response = await http.get(
                      Uri.parse(
                          'https://www.fl501st.com/troop-tracker/mobileapi.php?action=sign_up&trooperid=${userData['user']['user_id']}&addedby=0&troopid=${widget.troopid}&status=$selectedOption&costume=${selectedCostume?.id ?? 0}&backupcostume=${backupCostume?.id ?? 0}'),
                      headers: {
                        'API-Key': box.get('apiKey') ?? '',
                      },
                    );

                    if (response.statusCode == 200) {
                      final Map<String, dynamic> data =
                          json.decode(response.body);

                      // Show message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(data['success_message'] ?? 'Unknown'),
                        ),
                      );

                      // Navigate back to event
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventPage(
                            troopid: widget.troopid,
                          ),
                        ),
                        (route) => false, // Remove all previous routes
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to sign up!'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Sign Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
