import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:tt_mobile_app/custom/AppBar.dart';
import 'package:tt_mobile_app/custom/Functions.dart';
import 'package:tt_mobile_app/page/EventPage.dart';

class myTroops extends StatefulWidget {
  const myTroops({super.key});

  @override
  State<myTroops> createState() => _myTroopsState();
}

class _myTroopsState extends State<myTroops> {
  List<dynamic> troops = [];

  // Unescape HTML entities
  final unescape = HtmlUnescape();

  Future<void> fetchTroops() async {
    final box = Hive.box('TTMobileApp');
    final userData = await json.decode(box.get('userData'));
    final response = await http.get(
      Uri.parse(
          'https://www.fl501st.com/troop-tracker/mobileapi.php?user_id=${userData!['user']['user_id'].toString()}&action=troops'),
      headers: {
        'API-Key': box.get('apiKey') ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        troops = data['troops'] ?? [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load troops.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTroops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildAppBar(context, 'My Troops'),
        body: troops.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Not signed up for any troops.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Column(
                children: [
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
                                      padding:
                                          const EdgeInsets.only(bottom: 10.0),
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
                                    troops[index]['link'] != null &&
                                            troops[index]['link'] > 0
                                        ? Text(
                                            formatDateWithTime(
                                              unescape.convert(troops[index]
                                                      ['dateStart'] ??
                                                  ''),
                                              unescape.convert(troops[index]
                                                      ['dateEnd'] ??
                                                  ''),
                                            ),
                                          )
                                        : Text(
                                            formatDate(
                                              unescape.convert(troops[index]
                                                      ['dateStart'] ??
                                                  ''),
                                            ),
                                          ),
                                    SizedBox(height: 5),
                                    Text(unescape
                                        .convert(troops[index]['name'] ?? '')),
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
