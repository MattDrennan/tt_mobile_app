import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:tt_mobile_app/custom/AppBar.dart';
import 'package:tt_mobile_app/custom/Functions.dart';
import 'package:tt_mobile_app/models/Costume.dart';
import 'package:tt_mobile_app/models/Trooper.dart';

class AddFriend extends StatefulWidget {
  final int troopid;
  final int limitedEvent;
  final int allowTentative;
  final List<dynamic> shifts;

  const AddFriend({
    super.key,
    required this.troopid,
    required this.limitedEvent,
    required this.allowTentative,
    this.shifts = const [],
  });

  @override
  State<AddFriend> createState() => _AddFriendState();
}

class _AddFriendState extends State<AddFriend> {
  String? selectedStatus;
  Trooper? selectedTrooper;
  Costume? selectedCostume;
  Costume? backupCostume;
  int? selectedShiftId;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.limitedEvent == 1 ? 'pending' : 'going';
    if (_availableShifts.isNotEmpty) {
      selectedShiftId = (_availableShifts.first['id'] as num).toInt();
    }
  }

  List<dynamic> get _availableShifts => widget.shifts
      .where((s) => s['can_add_friend'] != false)
      .toList();

  bool get hasMultipleShifts => widget.shifts.length > 1;

  Future<List<Costume>> fetchCostumes(int trooperId, String? filter) async {
    final box = Hive.box('TTMobileApp');

    final response = await http.get(
      mobileApiUri({
        'action': 'get_costumes_for_trooper',
        'trooperid': 0,
        'friendid': trooperId,
      }),
      headers: {'API-Key': box.get('apiKey') ?? ''},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map<Costume>((c) => Costume(
                id: c['id'],
                name: '${c['abbreviation']}${c['name']}',
              ))
          .toList();
    } else {
      throw Exception('Failed to load costumes');
    }
  }

  Future<List<Trooper>> fetchAvailableTroopers(String? filter) async {
    final box = Hive.box('TTMobileApp');

    final params = {
      'action': 'get_available_troopers_for_event',
      'troopid': widget.troopid,
    };
    if (selectedShiftId != null) {
      params['shiftid'] = selectedShiftId!;
    }

    final response = await http.get(
      mobileApiUri(params),
      headers: {'API-Key': box.get('apiKey') ?? ''},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map<Trooper>((t) => Trooper(
                id: t['id'],
                name: t['display_name'] ?? '',
                tkid: t['tkid_formatted'] ?? '',
              ))
          .toList();
    } else {
      throw Exception('Failed to load troopers');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Add a Friend'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasMultipleShifts) ...[
              const Text('Shift:', style: TextStyle(fontSize: 16)),
              DropdownButton<int>(
                value: selectedShiftId,
                items: _availableShifts.map<DropdownMenuItem<int>>((shift) {
                  return DropdownMenuItem<int>(
                    value: (shift['id'] as num).toInt(),
                    child: Text(
                        shift['display']?.toString() ?? 'Shift ${shift['id']}'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    selectedShiftId = newValue;
                    // Reset trooper since available list changes per shift
                    selectedTrooper = null;
                    selectedCostume = null;
                    backupCostume = null;
                  });
                },
                isExpanded: true,
                underline: Container(height: 2, color: Colors.blue),
              ),
              const SizedBox(height: 16),
            ],
            const Text('Trooper:', style: TextStyle(fontSize: 16)),
            DropdownSearch<Trooper>(
              key: ValueKey(selectedShiftId),
              items: (String? filter, dynamic infiniteScrollProps) =>
                  fetchAvailableTroopers(filter),
              itemAsString: (Trooper? trooper) => trooper?.toString() ?? '',
              selectedItem: selectedTrooper,
              compareFn: (Trooper? item, Trooper? selectedItem) =>
                  item?.id == selectedItem?.id,
              onChanged: (Trooper? value) {
                setState(() {
                  selectedTrooper = value;
                  selectedCostume = null;
                  backupCostume = null;
                });
              },
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                fit: FlexFit.loose,
                constraints: BoxConstraints(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: selectedStatus,
              items: [
                if (widget.limitedEvent != 1) ...[
                  const DropdownMenuItem<String>(
                    value: 'going',
                    child: Text("I'll be there!"),
                  ),
                  if (widget.allowTentative == 1)
                    const DropdownMenuItem<String>(
                      value: 'tentative',
                      child: Text("Tentative"),
                    ),
                ] else
                  const DropdownMenuItem<String>(
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
              underline: Container(height: 2, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            const Text('Costume:', style: TextStyle(fontSize: 16)),
            DropdownSearch<Costume>(
              items: (String? filter, dynamic infiniteScrollProps) =>
                  selectedTrooper != null
                      ? fetchCostumes(selectedTrooper!.id, filter)
                      : Future.value([]),
              itemAsString: (Costume? costume) => costume?.name ?? '',
              selectedItem: selectedCostume,
              compareFn: (Costume? item, Costume? selectedItem) =>
                  item?.id == selectedItem?.id,
              onChanged: (Costume? value) {
                setState(() {
                  selectedCostume = value;
                });
              },
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                fit: FlexFit.loose,
                constraints: BoxConstraints(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Backup Costume:', style: TextStyle(fontSize: 16)),
            DropdownSearch<Costume>(
              items: (String? filter, dynamic infiniteScrollProps) =>
                  selectedTrooper != null
                      ? fetchCostumes(selectedTrooper!.id, filter)
                      : Future.value([]),
              itemAsString: (Costume? costume) => costume?.name ?? '',
              selectedItem: backupCostume,
              compareFn: (Costume? item, Costume? selectedItem) =>
                  item?.id == selectedItem?.id,
              onChanged: (Costume? value) {
                setState(() {
                  backupCostume = value;
                });
              },
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                fit: FlexFit.loose,
                constraints: BoxConstraints(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedStatus == null ||
                      selectedCostume == null ||
                      selectedTrooper == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please select a trooper and costume before signing up!'),
                      ),
                    );
                  } else if (hasMultipleShifts && selectedShiftId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a shift!'),
                      ),
                    );
                  } else {
                    _submitAddFriend();
                  }
                },
                child: const Text('Add Friend'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAddFriend() async {
    final box = Hive.box('TTMobileApp');
    final userData = json.decode(box.get('userData'));

    final params = {
      'action': 'sign_up',
      'trooperid': selectedTrooper!.id,
      'addedby': userData['user']['user_id'].toString(),
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
      headers: {'API-Key': box.get('apiKey') ?? ''},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['success_message'] ?? 'Added!')),
      );
      // Reset form so the same friend can be added to another shift,
      // or a different friend can be added without navigating away.
      setState(() {
        selectedTrooper = null;
        selectedCostume = null;
        backupCostume = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign up!')),
      );
    }
  }
}
