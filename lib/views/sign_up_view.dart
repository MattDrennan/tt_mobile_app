import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../models/costume.dart';
import '../services/api_client.dart';
import '../widgets/tt_app_bar.dart';

class SignUpView extends StatefulWidget {
  final int troopId;
  final String userId;
  final int limitedEvent;
  final int allowTentative;
  final List<dynamic> shifts;
  final ApiClient api;

  const SignUpView({
    super.key,
    required this.troopId,
    required this.userId,
    required this.limitedEvent,
    required this.allowTentative,
    required this.api,
    this.shifts = const [],
  });

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  String? _selectedStatus;
  Costume? _selectedCostume;
  Costume? _backupCostume;
  int? _selectedShiftId;
  bool _isSubmitting = false;

  bool get _hasMultipleShifts => widget.shifts.length > 1;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.limitedEvent == 1 ? 'pending' : 'going';
    if (widget.shifts.isNotEmpty) {
      _selectedShiftId = (widget.shifts.first['id'] as num).toInt();
    }
  }

  Future<List<Costume>> _fetchCostumes(String? filter) async {
    final data = await widget.api.getJson(
      widget.api.mobileApiUri({
        'action': 'get_costumes_for_trooper',
        'trooperid': widget.userId,
        'friendid': 0,
      }),
    );
    final list = data as List? ?? [];
    return list
        .map((c) => Costume(
              id: (c['id'] as num).toInt(),
              name: '${c['abbreviation']}${c['name']}',
            ))
        .toList();
  }

  Future<void> _submit() async {
    if (_selectedStatus == null || _selectedCostume == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a costume before signing up!')),
      );
      return;
    }
    if (_hasMultipleShifts && _selectedShiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a shift before signing up!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final params = <String, dynamic>{
      'action': 'sign_up',
      'trooperid': widget.userId,
      'addedby': 0,
      'troopid': widget.troopId,
      'status': _selectedStatus,
      'costume': _selectedCostume?.id ?? 0,
      'backupcostume': _backupCostume?.id ?? 0,
    };
    if (_selectedShiftId != null) params['shiftid'] = _selectedShiftId!;

    try {
      final data =
          await widget.api.getJson(widget.api.mobileApiUri(params));
      if (!mounted) return;
      final map = data as Map<String, dynamic>;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(map['success_message']?.toString() ?? 'Unknown')),
      );
      Navigator.pop(context, map['success'] == true);
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
      appBar: buildAppBar(context, 'Sign Up'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasMultipleShifts) ...[
              const Text('Shift:', style: TextStyle(fontSize: 16)),
              DropdownButton<int>(
                value: _selectedShiftId,
                items: widget.shifts.map<DropdownMenuItem<int>>((shift) {
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
            DropdownButton<String>(
              value: _selectedStatus,
              items: [
                if (widget.limitedEvent != 1) ...[
                  const DropdownMenuItem(
                      value: 'going', child: Text("I'll be there!")),
                  if (widget.allowTentative == 1)
                    const DropdownMenuItem(
                        value: 'tentative', child: Text('Tentative')),
                ] else
                  const DropdownMenuItem(
                    value: 'pending',
                    child: Text('Request to attend (Pending)'),
                  ),
              ],
              onChanged: (v) => setState(() => _selectedStatus = v),
              isExpanded: true,
              underline: Container(height: 2, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            const Text('Costume:', style: TextStyle(fontSize: 16)),
            DropdownSearch<Costume>(
              items: (filter, _) => _fetchCostumes(filter),
              itemAsString: (c) => c.name,
              selectedItem: _selectedCostume,
              compareFn: (a, b) => a.id == b.id,
              onChanged: (v) => setState(() => _selectedCostume = v),
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                fit: FlexFit.loose,
                constraints: BoxConstraints(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Backup Costume:', style: TextStyle(fontSize: 16)),
            DropdownSearch<Costume>(
              items: (filter, _) => _fetchCostumes(filter),
              itemAsString: (c) => c.name,
              selectedItem: _backupCostume,
              compareFn: (a, b) => a.id == b.id,
              onChanged: (v) => setState(() => _backupCostume = v),
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
                onPressed: _isSubmitting ? null : _submit,
                child: const Text('Sign Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
