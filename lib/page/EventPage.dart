import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bbcode/flutter_bbcode.dart' hide ColorTag, UrlTag;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import 'package:tt_mobile_app/custom/AppBar.dart';
import 'package:tt_mobile_app/page/SignUpScreen.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

import '../custom/InfoRow.dart';
import '../custom/LocationWidget.dart';
import '../tags/ColorTag.dart';
import '../tags/SizeTag.dart';
import '../tags/UrlTag.dart';
import 'ChatScreen.dart';

class EventPage extends StatefulWidget {
  final int troopid;

  const EventPage({super.key, required this.troopid});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  Map<String, dynamic>? troopData;
  List<dynamic>? rosterData;
  bool isInRoster = false;

  final unescape = HtmlUnescape();

  /// **Convert String Date to DateTime for Calendar**
  DateTime? parseDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return null;

    try {
      return DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateTime);
    } catch (e) {
      print("Error parsing date: $e");
      return null;
    }
  }

  /// **Function to Add Event to Calendar**
  void addToCalendar() {
    if (troopData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event data is missing.')),
      );
      return;
    }

    DateTime? startDate = parseDateTime(troopData?['dateStart']);
    DateTime? endDate = parseDateTime(troopData?['dateEnd']);

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid event date.')),
      );
      return;
    }

    final Event event = Event(
      title: unescape.convert(troopData?['name'] ?? 'Troop Event'),
      description: unescape
          .convert(troopData?['comments'] ?? 'No additional information.'),
      location: troopData?['location'] ?? 'Location not specified',
      startDate: startDate,
      endDate: endDate,
      allDay: false,
    );

    Add2Calendar.addEvent2Cal(event).then((success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(success ? 'Loading calendar...' : 'Failed to add event.')),
      );
    });
  }

  String formatDate(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) {
      return 'N/A';
    }

    try {
      DateTime dt = DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateTime);
      return DateFormat('MM/dd/yyyy h:mm a').format(dt);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Future<void> fetchEvent(int troopid) async {
    try {
      // Open the Hive box
      final box = Hive.box('TTMobileApp');

      final response = await http.get(
        Uri.parse(
            'https://www.fl501st.com/troop-tracker/mobileapi.php?troopid=$troopid&action=event'),
        headers: {
          'API-Key': box.get('apiKey') ?? '',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          troopData = data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load troop.')),
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

  Future<void> fetchRoster(int troopid) async {
    try {
      // Open the Hive box
      final box = Hive.box('TTMobileApp');

      final response = await http.get(
        Uri.parse(
            'https://www.fl501st.com/troop-tracker/mobileapi.php?troopid=$troopid&action=get_roster_for_event'),
        headers: {
          'API-Key': box.get('apiKey') ?? '',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          fetchRoster(widget.troopid);
          rosterData = data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load roster.')),
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

  Future<void> checkInRoster() async {
    final box = Hive.box('TTMobileApp');
    final rawData = box.get('userData');
    final userData = json.decode(rawData);

    // Parse user_id as an int
    final int userId = int.parse(userData['user']['user_id'].toString());

    bool result = await fetchInRoster(userId, widget.troopid);

    if (mounted) {
      setState(() {
        isInRoster = result;
      });
    }
  }

  Future<bool> fetchInRoster(int trooperid, int troopid) async {
    try {
      // Open the Hive box
      final box = Hive.box('TTMobileApp');

      final response = await http.get(
        Uri.parse(
            'https://www.fl501st.com/troop-tracker/mobileapi.php?trooperid=$trooperid&troopid=$troopid&action=trooper_in_event'),
        headers: {
          'API-Key': box.get('apiKey') ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['inEvent'] == true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelTroop(int troopid) async {
    final box = Hive.box('TTMobileApp');
    final rawData = box.get('userData');
    final userData = json.decode(rawData);

    // Parse user_id as an int
    final int userId = int.parse(userData['user']['user_id'].toString());

    try {
      final response = await http.get(
        Uri.parse(
            'https://www.fl501st.com/troop-tracker/mobileapi.php?trooperid=$userId&troopid=$troopid&action=cancel_troop'),
        headers: {
          'API-Key': box.get('apiKey') ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Update the state variable to refresh the widget
          isInRoster =
              false; // Reflect that the user is no longer in the roster
        });
        return data['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchEvent(widget.troopid);
    fetchRoster(widget.troopid);
    checkInRoster();
  }

  final customStylesheet = defaultBBStylesheet(
    textStyle: const TextStyle(
      fontSize: 14,
      color: Colors.white,
    ),
  ).addTag(SizeTag()).replaceTag(ColorTag()).replaceTag(UrlTag());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, unescape.convert(troopData?['name'] ?? '')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Details
            Text(
              unescape.convert(troopData?['venue'] ?? ''),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            LocationWidget(location: troopData?['location']),
            const Divider(),
            InfoRow(
              label: "Start",
              value: formatDate(troopData?['dateStart'] ?? 'N/A'),
            ),
            InfoRow(
              label: "End",
              value: formatDate(troopData?['dateEnd'] ?? 'N/A'),
            ),
            InfoRow(
              label: "Website",
              value: troopData?['website']?.isEmpty ?? true
                  ? 'N/A'
                  : troopData?['website'],
            ),
            const SizedBox(height: 10),

            // Attendance Details
            Text(
              "Attendance Details",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            InfoRow(
              label: "Attendees",
              value: troopData?['numberOfAttend'].toString() ?? 'N/A',
            ),
            InfoRow(
              label: "Requested",
              value: troopData?['requestedNumber'].toString() ?? 'N/A',
            ),
            InfoRow(
              label: "Requested Characters",
              value: troopData?['requestedCharacter'].toString() ?? 'N/A',
            ),
            const SizedBox(height: 10),

            // Amenities
            Text(
              "Amenities",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            InfoRow(
              label: "Restrooms",
              value: troopData?['amenities'] ?? 'N/A',
            ),
            InfoRow(
              label: "Secure Changing Area",
              value: (troopData?['secureChanging'] ?? 0) == 1 ? 'Yes' : 'No',
            ),
            InfoRow(
              label: "Blasters Allowed",
              value: (troopData?['blasters'] ?? 0) == 1 ? 'Yes' : 'No',
            ),
            InfoRow(
              label: "Lightsabers Allowed",
              value: (troopData?['lightsabers'] ?? 0) == 1 ? 'Yes' : 'No',
            ),
            InfoRow(
              label: "Parking Available",
              value: (troopData?['parking'] ?? 0) == 1 ? 'Yes' : 'No',
            ),
            InfoRow(
              label: "Mobility Accessible",
              value: (troopData?['mobility'] ?? 0) == 1 ? 'Yes' : 'No',
            ),
            const SizedBox(height: 10),

            // POC Details
            Text(
              "Points of Contact",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            InfoRow(
              label: "Referred By",
              value: troopData?['referred'] ?? '',
            ),
            //Text("POC Name: ${troopData?['poc'] ?? ''}"),
            const SizedBox(height: 10),

            // Comments Section
            Text(
              "Additional Information",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            BBCodeText(
                data: unescape.convert(troopData?['comments'] ?? ''),
                stylesheet: customStylesheet),
            // Roster Section
            if (rosterData != null && rosterData!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Card(
                    color: Colors.grey[900],
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.resolveWith(
                              (states) => Colors.grey[800]),
                          columns: const [
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Trooper Name')),
                            DataColumn(label: Text('TKID')),
                            DataColumn(label: Text('Costume')),
                            DataColumn(label: Text('Backup Costume')),
                            DataColumn(label: Text('Signup Time')),
                          ],
                          rows: rosterData!.map((member) {
                            final String status =
                                member['status_formatted']?.toLowerCase() ?? '';
                            final bool isCanceled = status == 'canceled';
                            final bool isTentative = status == 'tentative';
                            final bool isStandBy = status == 'stand by';

                            return DataRow(
                              cells: [
                                DataCell(Text(
                                  member['status_formatted'].toString() ??
                                      'N/A',
                                  style: TextStyle(
                                    color: isCanceled
                                        ? Colors.red
                                        : isTentative
                                            ? Colors.purple
                                            : isStandBy
                                                ? Colors.orange
                                                : null,
                                    decoration: isCanceled
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                )),
                                DataCell(Text(
                                  member['trooper_name'].toString() ?? 'N/A',
                                  style: TextStyle(
                                    color: isCanceled
                                        ? Colors.red
                                        : isTentative
                                            ? Colors.purple
                                            : isStandBy
                                                ? Colors.orange
                                                : null,
                                    decoration: isCanceled
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                )),
                                DataCell(Text(
                                  member['tkid_formatted'].toString() ?? 'N/A',
                                  style: TextStyle(
                                    color: isCanceled
                                        ? Colors.red
                                        : isTentative
                                            ? Colors.purple
                                            : isStandBy
                                                ? Colors.orange
                                                : null,
                                    decoration: isCanceled
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                )),
                                DataCell(Text(
                                  member['costume_name'].toString() ?? 'N/A',
                                  style: TextStyle(
                                    color: isCanceled
                                        ? Colors.red
                                        : isTentative
                                            ? Colors.purple
                                            : isStandBy
                                                ? Colors.orange
                                                : null,
                                    decoration: isCanceled
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                )),
                                DataCell(Text(
                                  member['backup_costume_name'] != null
                                      ? member['backup_costume_name'].toString()
                                      : 'N/A',
                                  style: TextStyle(
                                    color: isCanceled
                                        ? Colors.red
                                        : isTentative
                                            ? Colors.purple
                                            : isStandBy
                                                ? Colors.orange
                                                : null,
                                    decoration: isCanceled
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                )),
                                DataCell(Text(
                                  formatDate(member['signuptime']) ?? 'N/A',
                                  style: TextStyle(
                                    color: isCanceled
                                        ? Colors.red
                                        : isTentative
                                            ? Colors.purple
                                            : isStandBy
                                                ? Colors.orange
                                                : null,
                                    decoration: isCanceled
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Text("No roster data available."),
            const Divider(),
            const SizedBox(height: 10),
            !isInRoster
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpScreen(
                              troopid: widget.troopid,
                              limitedEvent: troopData?['limitedEvent'] ?? 0,
                              allowTentative: troopData?['allowTentative'] ?? 0,
                            ),
                          ),
                        );
                      },
                      child: Text('Go To Sign Up'),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.red, // Set button color to red for "Cancel"
                      ),
                      onPressed: () async {
                        if (await cancelTroop(widget.troopid)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('You have canceled the signup.')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Something went wrong.')),
                          );
                        }
                      },
                      child: Text('Cancel Signup'),
                    ),
                  ),
            const Divider(),
            const SizedBox(height: 10),
            // **"Add to Calendar" Button**
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.calendar_today),
                label: Text("Add to Calendar"),
                onPressed: addToCalendar,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        troopName: unescape.convert(troopData?['name'] ?? ''),
                        threadId: troopData?['thread_id'] ?? '',
                        postId: troopData?['post_id'] ?? '',
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.chat_bubble, size: 20), // Chat bubble icon
                label: Text('Go To Discussion'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
