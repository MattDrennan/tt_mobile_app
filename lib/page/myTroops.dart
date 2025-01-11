import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
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
    );

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
  }

  @override
  void initState() {
    super.initState();
    fetchTroops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Troops'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: List.generate(
            troops.length,
            (index) => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventPage(
                        troopid: troops[index]['troopid'],
                      ),
                    ),
                  );
                },
                child: Text(unescape.convert(troops[index]['name'] ?? '')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
