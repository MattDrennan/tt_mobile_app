import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:tt_mobile_app/custom/AppBar.dart';
import 'package:tt_mobile_app/models/Costume.dart';

class ConfirmPage extends StatefulWidget {
  final int trooperId;

  const ConfirmPage({super.key, required this.trooperId});

  @override
  State<ConfirmPage> createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  List<dynamic> troops = [];
  List<int> selectedTroops = [];
  bool isLoading = true;
  Costume? selectedCostume;

  @override
  void initState() {
    super.initState();
    fetchTroops();
  }

  /// Fetch costumes dynamically for the dropdown
  Future<List<Costume>> fetchCostumes(String? filter) async {
    // Open the Hive box
    final box = Hive.box('TTMobileApp');

    final response = await http.get(
      Uri.parse(
          'https://www.fl501st.com/troop-tracker/mobileapi.php?action=get_costumes_for_trooper&trooperid=${widget.trooperId}&friendid=0&allowDualCostume=true'),
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

  Future<void> fetchTroops() async {
    try {
      // Open the Hive box
      final box = Hive.box('TTMobileApp');

      final response = await http.get(
        Uri.parse(
            'https://www.fl501st.com/troop-tracker/mobileapi.php?trooperid=${widget.trooperId}&action=get_confirm_events_trooper'),
        headers: {
          'API-Key': box.get('apiKey') ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          troops = data['troops'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load troops.')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> updateStatusAndCostume(
      {required int troopId, required int status, int? costumeId}) async {
    try {
      // Open the Hive box
      final box = Hive.box('TTMobileApp');

      final trooperId = widget.trooperId;

      final response = await http.get(
        Uri.parse(
            'https://www.fl501st.com/troop-tracker/mobileapi.php?action=set_status_costume&trooperid=$trooperId&troopid=$troopId&status=$status&costume=${costumeId ?? 0}'),
        headers: {
          'API-Key': box.get('apiKey') ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!data['success']) {
          throw Exception('Failed to update status for troop $troopId.');
        }
      } else {
        throw Exception(
            'Failed to update status. HTTP status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void confirmAttendance() async {
    if (selectedTroops.isEmpty || selectedCostume == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select troops and a costume.')),
      );
      return;
    }

    // Keep track of successful updates
    List<int> updatedTroops = [];

    for (int troopId in selectedTroops) {
      await updateStatusAndCostume(
        troopId: troopId,
        status: 3,
        costumeId: selectedCostume?.id,
      );
      updatedTroops.add(troopId); // Mark as updated
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Attendance confirmed for selected troops.')),
    );

    // Remove updated troops from the list
    setState(() {
      troops.removeWhere((troop) => updatedTroops.contains(troop['troopid']));
      selectedTroops.clear(); // Clear selections after updating
    });
  }

  void adviseNotAttended() async {
    if (selectedTroops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select troops.')),
      );
      return;
    }

    // Keep track of successful updates
    List<int> updatedTroops = [];

    for (int troopId in selectedTroops) {
      await updateStatusAndCostume(
        troopId: troopId,
        status: 4,
      );
      updatedTroops.add(troopId); // Mark as updated
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Marked as not attended for selected troops.')),
    );

    // Remove updated troops from the list
    setState(() {
      troops.removeWhere((troop) => updatedTroops.contains(troop['troopid']));
      selectedTroops.clear(); // Clear selections after updating
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Confirm Troops'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : troops.isEmpty
              ? const Center(child: Text('No troops available.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Costume Dropdown
                      DropdownSearch<Costume>(
                        items: (String? filter, dynamic infiniteScrollProps) =>
                            fetchCostumes(filter),
                        itemAsString: (Costume? costume) =>
                            costume?.name ??
                            '', // Display the name of the costume
                        selectedItem: selectedCostume,
                        compareFn: (Costume? item, Costume? selectedItem) =>
                            item?.id == selectedItem?.id,
                        onChanged: (Costume? value) {
                          setState(() {
                            selectedCostume =
                                value; // Store the selected costume object
                          });
                        },
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          fit: FlexFit.loose,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Troop Multi-Selection
                      Expanded(
                        child: ListView.builder(
                          itemCount: troops.length,
                          itemBuilder: (context, index) {
                            final troop = troops[index];
                            final troopId = troop['troopid'];
                            return CheckboxListTile(
                              title: Text(troop['name']),
                              subtitle: Text(
                                  'Start: ${troop['dateStart']}\nEnd: ${troop['dateEnd']}'),
                              value: selectedTroops.contains(troopId),
                              onChanged: (isSelected) {
                                setState(() {
                                  if (isSelected ?? false) {
                                    selectedTroops.add(troopId);
                                  } else {
                                    selectedTroops.remove(troopId);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: confirmAttendance,
                              child: const Text('Confirm Attendance'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: adviseNotAttended,
                              child: const Text('Advise Did Not Make It'),
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
