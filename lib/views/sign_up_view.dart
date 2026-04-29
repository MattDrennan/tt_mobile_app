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
  final List<dynamic> eventOrganizations;
  final ApiClient api;

  const SignUpView({
    super.key,
    required this.troopId,
    required this.userId,
    required this.limitedEvent,
    required this.allowTentative,
    required this.api,
    this.shifts = const [],
    this.eventOrganizations = const [],
  });

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  String? _selectedStatus;
  Costume? _selectedCostume;
  Costume? _backupCostume;
  int? _selectedShiftId;
  int? _selectedOrgId;
  bool _isSubmitting = false;

  bool get _hasMultipleShifts => widget.shifts.length > 1;

  bool get _hasOrganizations => widget.eventOrganizations.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final hasOrgs = widget.eventOrganizations.isNotEmpty;
    if (widget.limitedEvent == 1 && !hasOrgs) {
      _selectedStatus = 'pending';
    } else {
      _selectedStatus = 'going';
    }
    if (widget.shifts.isNotEmpty) {
      _selectedShiftId = (widget.shifts.first['id'] as num).toInt();
    }
  }

  Future<List<Costume>> _fetchCostumes(String? filter) async {
    final params = <String, dynamic>{
      'action': 'get_costumes_for_trooper',
      'trooperid': widget.userId,
      'friendid': 0,
    };
    if (_selectedOrgId != null) params['organization_id'] = _selectedOrgId!;

    final data = await widget.api.getJson(widget.api.mobileApiUri(params));
    final list = data as List? ?? [];
    return list
        .map((c) => Costume(
              id: (c['id'] as num).toInt(),
              name: '${c['abbreviation']}${c['name']}',
            ))
        .toList();
  }

  Future<void> _submit() async {
    if (_selectedCostume == null) {
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
    if (_hasOrganizations && _selectedOrgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select an organization before signing up!')),
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
    if (_selectedOrgId != null) params['organization_id'] = _selectedOrgId!;

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
      body: SingleChildScrollView(
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
            if (_hasOrganizations) ...[
              const Text('Organization:', style: TextStyle(fontSize: 16)),
              DropdownButton<int>(
                value: _selectedOrgId,
                hint: const Text('Select an organization'),
                items: widget.eventOrganizations
                    .map<DropdownMenuItem<int>>((org) {
                  return DropdownMenuItem<int>(
                    value: (org['id'] as num?)?.toInt() ?? 0,
                    child: Text(org['name']?.toString() ?? ''),
                  );
                }).toList(),
                onChanged: (v) => setState(() {
                  _selectedOrgId = v;
                  _selectedCostume = null;
                  _backupCostume = null;
                }),
                isExpanded: true,
                underline: Container(height: 2, color: Colors.blue),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Your status will be Going or Stand By based on availability for the selected organization.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
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
            ],
            if (!_hasOrganizations || _selectedOrgId != null) ...[
              const Text('Costume:', style: TextStyle(fontSize: 16)),
              DropdownSearch<Costume>(
                key: ValueKey('costume_$_selectedOrgId'),
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
                key: ValueKey('backup_$_selectedOrgId'),
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
            ],
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
