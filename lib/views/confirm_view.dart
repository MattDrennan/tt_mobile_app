import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/confirm_controller.dart';
import '../models/costume.dart';
import '../services/api_client.dart';
import '../widgets/tt_app_bar.dart';

class ConfirmView extends StatefulWidget {
  final int trooperId;

  const ConfirmView({super.key, required this.trooperId});

  @override
  State<ConfirmView> createState() => _ConfirmViewState();
}

class _ConfirmViewState extends State<ConfirmView> {
  late final ConfirmController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfirmController(
      context.read<ApiClient>(),
      trooperId: widget.trooperId,
    );
    _controller.addListener(_onChanged);
    _controller.fetchTroops();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _confirmAttendance() async {
    if (_controller.selectedTroopIds.isEmpty ||
        _controller.selectedCostume == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select troops and a costume.')),
      );
      return;
    }
    final success = await _controller.confirmAttendance();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Attendance confirmed for selected troops.'
            : _controller.error ?? 'Something went wrong.'),
      ),
    );
  }

  void _adviseNoShow() async {
    if (_controller.selectedTroopIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select troops.')),
      );
      return;
    }
    final success = await _controller.adviseNoShow();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Marked as not attended for selected troops.'
            : _controller.error ?? 'Something went wrong.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Confirm Troops'),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller.troops.isEmpty
              ? const Center(child: Text('No troops available.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownSearch<Costume>(
                        items: (filter, _) =>
                            _controller.fetchCostumes(filter),
                        itemAsString: (c) => c.name,
                        selectedItem: _controller.selectedCostume,
                        compareFn: (a, b) => a.id == b.id,
                        onChanged: _controller.selectCostume,
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                          fit: FlexFit.loose,
                          constraints: BoxConstraints(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _controller.troops.length,
                          itemBuilder: (context, index) {
                            final troop = _controller.troops[index];
                            final troopId =
                                (troop['troopid'] as num).toInt();
                            return CheckboxListTile(
                              title: Text(troop['name'].toString()),
                              subtitle: Text(
                                'Start: ${troop['dateStart']}\nEnd: ${troop['dateEnd']}',
                              ),
                              value: _controller.selectedTroopIds
                                  .contains(troopId),
                              onChanged: (selected) =>
                                  _controller.toggleTroop(
                                      troopId, selected ?? false),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _controller.isSubmitting
                                  ? null
                                  : _confirmAttendance,
                              child: const Text('Confirm Attendance'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: _controller.isSubmitting
                                  ? null
                                  : _adviseNoShow,
                              child:
                                  const Text('Advise Did Not Make It'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
