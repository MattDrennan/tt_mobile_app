import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:tt_mobile_app/custom/AppBar.dart';
import 'package:tt_mobile_app/custom/Functions.dart';
import 'package:tt_mobile_app/models/Costume.dart';
import 'package:tt_mobile_app/page/EventPage.dart';

class SignUpScreen extends StatefulWidget {
  final int troopid;
  final int limitedEvent;
  final int allowTentative;
  final List<dynamic> shifts;

  const SignUpScreen({
    super.key,
    required this.troopid,
    required this.limitedEvent,
    required this.allowTentative,
    this.shifts = const [],
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String? selectedStatus;
  Costume? selectedCostume;
  Costume? backupCostume;
  int? selectedShiftId;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.limitedEvent == 1 ? 'pending' : 'going';
    if (widget.shifts.isNotEmpty) {
      selectedShiftId = widget.shifts.first['id'] as int?;
    }
  }

  bool get hasMultipleShifts => widget.shifts.length > 1;

  /// Fetch costumes dynamically for the dropdown
  Future<List<Costume>> fetchCostumes(String? filter) async {
    final box = Hive.box('TTMobileApp');
    final rawData = box.get('userData');
    final userData = json.decode(rawData);

    final response = await http.get(
      mobileApiUri({
        'action': 'get_costumes_for_trooper',
        'trooperid': userData['user']['user_id'].toString(),
        'friendid': 0,
      }),
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
    return Scaffold(
      appBar: buildAppBar(context, 'Sign Up'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasMultipleShifts) ...[
              const Text('Shift:', style: TextStyle(fontSize: 16)),
              DropdownButton<int>(
                value: selectedShiftId,
                items: widget.shifts.map<DropdownMenuItem<int>>((shift) {
                  return DropdownMenuItem<int>(
                    value: shift['id'] as int,
                    child: Text(shift['display']?.toString() ?? 'Shift ${shift['id']}'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    selectedShiftId = newValue;
                  });
                },
                isExpanded: true,
                underline: Container(
                  height: 2,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
            ],
            DropdownButton<String>(
              value: selectedStatus,
              items: [
                if (widget.limitedEvent != 1) ...[
                  DropdownMenuItem<String>(
                    value: 'going',
                    child: Text("I'll be there!"),
                  ),
                  if (widget.allowTentative == 1)
                    DropdownMenuItem<String>(
                      value: 'tentative',
                      child: Text("Tentative"),
                    ),
                ] else
                  DropdownMenuItem<String>(
                    value: 'pending',
                    child: Text("Request to attend (Pending)"),
                  ),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  selectedStatus = newValue;
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
                onPressed: () {
                  if (selectedStatus == null || selectedCostume == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please select a costume before signing up!'),
                      ),
                    );
                  } else if (hasMultipleShifts && selectedShiftId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a shift before signing up!'),
                      ),
                    );
                  } else {
                    _submitSignUp();
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

  Future<void> _submitSignUp() async {
    final box = Hive.box('TTMobileApp');
    final rawData = box.get('userData');
    final userData = json.decode(rawData);

    final params = {
      'action': 'sign_up',
      'trooperid': userData['user']['user_id'],
      'addedby': 0,
      'troopid': widget.troopid,
      'status': selectedStatus,
      'costume': selectedCostume?.id ?? 0,
      'backupcostume': backupCostume?.id ?? 0,
    };

    if (selectedShiftId != null) {
      params['shiftid'] = selectedShiftId!;
    }

    final response = await http.get(
      mobileApiUri(params),
      headers: {
        'API-Key': box.get('apiKey') ?? '',
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['success_message'] ?? 'Unknown')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => EventPage(troopid: widget.troopid),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign up!')),
      );
    }
  }
}
