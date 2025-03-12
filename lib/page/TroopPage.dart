import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:tt_mobile_app/custom/AppBar.dart';
import 'package:tt_mobile_app/custom/Functions.dart';
import 'package:tt_mobile_app/page/EventPage.dart';

// Unescape HTML entities
final unescape = HtmlUnescape();

class TroopPage extends StatefulWidget {
  const TroopPage({super.key});

  @override
  State<TroopPage> createState() => _TroopPageState();
}

class _TroopPageState extends State<TroopPage> {
  List<dynamic> troops = [];
  List<dynamic> filteredTroops = []; // Holds the filtered results
  int selectedSquad = 0;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTroops(0);
    searchController.addListener(() {
      filterTroops();
    });
  }

  Future<void> fetchTroops(int squad) async {
    try {
      final box = Hive.box('TTMobileApp');

      final response = await http.get(
        Uri.parse(
            'https://www.fl501st.com/troop-tracker/mobileapi.php?squad=$squad&action=get_troops_by_squad'),
        headers: {
          'API-Key': box.get('apiKey') ?? '',
        },
      );

      selectedSquad = squad;

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          troops = data['troops'];
          filteredTroops = troops; // Initialize filtered list
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load troops.')),
        );
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request timed out. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// **Filters troops as user types in the search bar**
  void filterTroops() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredTroops = troops
          .where((troop) => unescape
              .convert(troop['name'] ?? '')
              .toLowerCase()
              .contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Troops'),
      body: Column(
        children: [
          /// **Search Bar**
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Troops',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          /// **Squad Selection Row**
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(6, (int indexSquad) {
                const squadNames = [
                  'All',
                  'Everglades Squad',
                  'Makaze Squad',
                  'Parjai Squad',
                  'Squad 7',
                  'Tampa Bay Squad'
                ];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: () => fetchTroops(indexSquad),
                    child: Text(squadNames[indexSquad]),
                  ),
                );
              }),
            ),
          ),

          /// **Troops List**
          Expanded(
            child: filteredTroops.isEmpty
                ? Center(child: Text('No troops found!'))
                : ListView.builder(
                    itemCount: filteredTroops.length,
                    itemBuilder: (context, index) {
                      var troop = filteredTroops[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventPage(
                                      troopid: troop['troopid'],
                                    ),
                                  ));
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Image.asset(
                                    [
                                      'assets/icons/garrison_icon.png',
                                      'assets/icons/everglades_icon.png',
                                      'assets/icons/makaze_icon.png',
                                      'assets/icons/parjai_icon.png',
                                      'assets/icons/squad7_icon.png',
                                      'assets/icons/tampabay_icon.png'
                                    ][(troop['squad'] ?? 0).clamp(0, 5)],
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                                troop['link'] != null && troop['link'] > 0
                                    ? Text(
                                        formatDateWithTime(
                                          unescape.convert(
                                              troop['dateStart'] ?? ''),
                                          unescape
                                              .convert(troop['dateEnd'] ?? ''),
                                        ),
                                        style: TextStyle(color: Colors.blue),
                                      )
                                    : Text(
                                        formatDate(
                                          unescape.convert(
                                              troop['dateStart'] ?? ''),
                                        ),
                                      ),
                                const SizedBox(height: 5),
                                Text(
                                  unescape.convert(troop['name'] ?? ''),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  (troop['trooper_count'] ?? 0) < 2
                                      ? 'NOT ENOUGH TROOPERS FOR THIS EVENT!'
                                      : '${troop['trooper_count']?.toString() ?? '0'} Troopers Attending',
                                  style: TextStyle(
                                    color: (troop['trooper_count'] ?? 0) < 2
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
