import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/add_friend_controller.dart';
import '../models/costume.dart';
import '../models/trooper.dart';
import '../services/api_client.dart';
import '../widgets/tt_app_bar.dart';

class AddFriendView extends StatefulWidget {
  final int troopId;
  final String addedByUserId;
  final int limitedEvent;
  final int allowTentative;
  final List<dynamic> shifts;

  const AddFriendView({
    super.key,
    required this.troopId,
    required this.addedByUserId,
    required this.limitedEvent,
    required this.allowTentative,
    this.shifts = const [],
  });

  @override
  State<AddFriendView> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends State<AddFriendView> {
  late final AddFriendController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AddFriendController(
      context.read<ApiClient>(),
      troopId: widget.troopId,
      addedByUserId: widget.addedByUserId,
      limitedEvent: widget.limitedEvent,
      allowTentative: widget.allowTentative,
      shifts: widget.shifts,
    );
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    if (_controller.submitSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_controller.successMessage ?? 'Friend added!')),
      );
      Navigator.pop(context, true);
      return;
    }
    if (_controller.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.error!)),
      );
    }
    setState(() {});
  }

  void _submit() {
    if (_controller.selectedTrooper == null ||
        _controller.selectedCostume == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select a trooper and costume before signing up!'),
        ),
      );
      return;
    }
    if (_controller.hasMultipleShifts &&
        _controller.selectedShiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shift!')),
      );
      return;
    }
    _controller.submit();
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
            if (_controller.hasMultipleShifts) ...[
              const Text('Shift:', style: TextStyle(fontSize: 16)),
              DropdownButton<int>(
                value: _controller.selectedShiftId,
                items: _controller.availableShifts
                    .map<DropdownMenuItem<int>>((shift) {
                  return DropdownMenuItem<int>(
                    value: (shift['id'] as num).toInt(),
                    child: Text(shift['display']?.toString() ??
                        'Shift ${shift['id']}'),
                  );
                }).toList(),
                onChanged: _controller.setShift,
                isExpanded: true,
                underline: Container(height: 2, color: Colors.blue),
              ),
              const SizedBox(height: 16),
            ],
            const Text('Trooper:', style: TextStyle(fontSize: 16)),
            DropdownSearch<Trooper>(
              key: ValueKey(_controller.selectedShiftId),
              items: (filter, _) =>
                  _controller.fetchAvailableTroopers(filter),
              itemAsString: (t) => t.toString(),
              selectedItem: _controller.selectedTrooper,
              compareFn: (a, b) => a.id == b.id,
              onChanged: _controller.setTrooper,
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                fit: FlexFit.loose,
                constraints: BoxConstraints(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _controller.selectedStatus,
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
              onChanged: (v) {
                if (v != null) _controller.setStatus(v);
              },
              isExpanded: true,
              underline: Container(height: 2, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            const Text('Costume:', style: TextStyle(fontSize: 16)),
            DropdownSearch<Costume>(
              items: (filter, _) => _controller.selectedTrooper != null
                  ? _controller.fetchCostumes(
                      _controller.selectedTrooper!.id, filter)
                  : Future.value([]),
              itemAsString: (c) => c.name,
              selectedItem: _controller.selectedCostume,
              compareFn: (a, b) => a.id == b.id,
              onChanged: _controller.setCostume,
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                fit: FlexFit.loose,
                constraints: BoxConstraints(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Backup Costume:', style: TextStyle(fontSize: 16)),
            DropdownSearch<Costume>(
              items: (filter, _) => _controller.selectedTrooper != null
                  ? _controller.fetchCostumes(
                      _controller.selectedTrooper!.id, filter)
                  : Future.value([]),
              itemAsString: (c) => c.name,
              selectedItem: _controller.backupCostume,
              compareFn: (a, b) => a.id == b.id,
              onChanged: _controller.setBackupCostume,
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
                onPressed: _controller.isSubmitting ? null : _submit,
                child: const Text('Add Friend'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
