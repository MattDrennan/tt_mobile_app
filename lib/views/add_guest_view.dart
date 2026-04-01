import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../widgets/tt_app_bar.dart';

class AddGuestView extends StatefulWidget {
  final int troopId;
  final String userId;
  final List<dynamic> shifts;
  final ApiClient api;

  const AddGuestView({
    super.key,
    required this.troopId,
    required this.userId,
    required this.api,
    this.shifts = const [],
  });

  @override
  State<AddGuestView> createState() => _AddGuestViewState();
}

class _AddGuestViewState extends State<AddGuestView> {
  final TextEditingController _nameController = TextEditingController();
  int? _selectedShiftId;
  bool _isSubmitting = false;

  List<dynamic> get _availableShifts =>
      widget.shifts.where((s) => s['can_add_guest'] != false).toList();

  bool get _hasMultipleShifts => widget.shifts.length > 1;

  @override
  void initState() {
    super.initState();
    if (_availableShifts.isNotEmpty) {
      _selectedShiftId = (_availableShifts.first['id'] as num).toInt();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a guest name.')),
      );
      return;
    }
    if (_hasMultipleShifts && _selectedShiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shift.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final params = <String, dynamic>{
      'action': 'add_guest',
      'trooperid': widget.userId,
      'troopid': widget.troopId,
      'name': name,
    };
    if (_selectedShiftId != null) params['shiftid'] = _selectedShiftId!;

    try {
      final data =
          await widget.api.getJson(widget.api.mobileApiUri(params));
      if (!mounted) return;
      final map = data as Map<String, dynamic>;
      if (map['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(map['message']?.toString() ?? 'Guest added!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  map['message']?.toString() ?? 'Failed to add guest.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
            if (_hasMultipleShifts) ...[
              const Text('Shift:', style: TextStyle(fontSize: 16)),
              DropdownButton<int>(
                value: _selectedShiftId,
                items:
                    _availableShifts.map<DropdownMenuItem<int>>((shift) {
                  return DropdownMenuItem<int>(
                    value: (shift['id'] as num).toInt(),
                    child: Text(shift['display']?.toString() ??
                        'Shift ${shift['id']}'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedShiftId = v),
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
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: const Text('Add Guest'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
