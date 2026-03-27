import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:tt_mobile_app/custom/AppBar.dart';
import 'package:tt_mobile_app/custom/Functions.dart';

class AddGuest extends StatefulWidget {
  final int troopid;
  final List<dynamic> shifts;

  const AddGuest({
    super.key,
    required this.troopid,
    this.shifts = const [],
  });

  @override
  State<AddGuest> createState() => _AddGuestState();
}

class _AddGuestState extends State<AddGuest> {
  final TextEditingController _nameController = TextEditingController();
  int? selectedShiftId;

  @override
  void initState() {
    super.initState();
    if (_availableShifts.isNotEmpty) {
      selectedShiftId = (_availableShifts.first['id'] as num).toInt();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<dynamic> get _availableShifts => widget.shifts
      .where((s) => s['can_add_guest'] != false)
      .toList();

  bool get hasMultipleShifts => widget.shifts.length > 1;

  Future<void> _submitAddGuest() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a guest name.')),
      );
      return;
    }

    if (hasMultipleShifts && selectedShiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shift.')),
      );
      return;
    }

    final box = Hive.box('TTMobileApp');
    final userData = json.decode(box.get('userData'));

    final params = {
      'action': 'add_guest',
      'trooperid': userData['user']['user_id'].toString(),
      'troopid': widget.troopid,
      'name': name,
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
      final data = json.decode(response.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Guest added!')),
        );
        setState(() {
          _nameController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to add guest.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add guest.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Add a Guest'),
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
                  });
                },
                isExpanded: true,
                underline: Container(height: 2, color: Colors.blue),
              ),
              const SizedBox(height: 16),
            ],
            const Text('Guest Name:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter guest name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _submitAddGuest(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitAddGuest,
                child: const Text('Add Guest'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
