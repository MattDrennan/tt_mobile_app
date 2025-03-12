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
  int selectedSquad = 0;

  Future<void> fetchTroops(int squad) async {
    try {
      // Open the Hive box
      final box = Hive.box('TTMobileApp');

      final response = await http.get(
        Uri.parse(
            'https://www.fl501st.com/troop-tracker/mobileapi.php?squad=$squad&action=get_troops_by_squad'),
        headers: {
          'API-Key': box.get('apiKey') ?? '',
        },
      );

      selectedSquad = squad;

      if (!mounted) return; // Ensure widget is mounted before proceeding

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          troops = data['troops'];
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

  @override
  void initState() {
    super.initState();
    fetchSiteStatus(context);
    selectedSquad = 0;
    troops = [];
    fetchTroops(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildAppBar(context, 'Troops'),
        body: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(6, (int indexSquad) {
                  // Map index to squad name
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(
                    troops.length,
                    (int index) => Padding(
                      padding: const EdgeInsets.only(
                          bottom: 16.0), // Adds margin between buttons
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventPage(
                                    troopid: troops[index]['troopid'],
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
                                  ][(troops[index]['squad'] ?? 0).clamp(0,
                                      5)], // Clamp ensures index stays within valid range (0-5)
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                              Text(unescape
                                  .convert(troops[index]['name'] ?? '')),
                              SizedBox(height: 5),
                              Text(
                                (troops[index]['trooper_count'] ?? 0) < 2
                                    ? 'NOT ENOUGH TROOPERS FOR THIS EVENT!'
                                    : '${troops[index]['trooper_count']?.toString() ?? '0'} Troopers Attending',
                                style: TextStyle(
                                  color:
                                      (troops[index]['trooper_count'] ?? 0) < 2
                                          ? Colors.red
                                          : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}
