import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:convert';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart' as imagePicker;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:photo_view/photo_view.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bbcode/flutter_bbcode.dart';
import 'package:html_unescape/html_unescape.dart';

// Global
types.User _user = const types.User(id: 'user');
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Unescape HTML entities
final unescape = HtmlUnescape();

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");
  // Load HIVE
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  await Hive.openBox('TTMobileApp');
  // Load Firebase
  await Firebase.initializeApp();
  initNotifications();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  setupFirebaseListeners();
  // Initialize local notifications
  initializeNotifications();
  runApp(const MyApp());
}

// Handle background messages
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.notification?.title}');
}

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

void initNotifications() async {
  NotificationSettings settings = await _firebaseMessaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else {
    print('User declined or has not accepted permission');
  }
}

Future<bool> getToken(String userId) async {
  // Retrieve APNS token
  String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();

  if (apnsToken == null) {
    print('Push notifications may not work.');
    return true;
  } else {
    // APNS Token
    print('APNS token: $apnsToken');

    // Retrieve FCM token
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      print('FCM Token: $fcmToken');

      final response = await http.post(
        Uri.parse('https://www.fl501st.com/troop-tracker/mobileapi.php'),
        body: {
          'action': 'saveFCM',
          'userid': userId,
          'fcm': fcmToken,
        },
      );

      if (response.statusCode == 200) {
        // Save FCM
        final box = Hive.box('TTMobileApp');
        box.put('fcm', fcmToken);
        print('Success');
        return true;
      } else {
        print('Fail');
        return false;
      }
    } else {
      print('Failed to retrieve FCM token.');
      return false;
    }
  }
}

void handleForegroundMessage(RemoteMessage message) async {
  print('Message received: ${message.notification?.title}');

  // Show a push notification when the app is in the foreground
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'high_importance_channel', // channel ID
    'High Importance Notifications', // channel name
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID
    message.notification?.title ?? 'Notification',
    message.notification?.body ?? 'You have a new message.',
    platformChannelSpecifics,
    payload: message.data.toString(),
  );
}

void handleMessageOpenedApp(RemoteMessage message) {
  print('Message clicked: ${message.data['threadId']}');

  // Navigate to ChatPage
  final threadId = int.parse(message.data['threadId']); // Parse thread ID
  final postId = int.parse(message.data['postId']); // Parse post ID
  final troopName = message.data['troopName'] ?? 'Unknown'; // Get troop name

  // Navigate to the ChatScreen
  Navigator.push(
    navigatorKey.currentContext!, // Use a global navigator key
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        troopName: troopName,
        threadId: threadId,
        postId: postId,
      ),
    ),
  );
}

void setupFirebaseListeners() {
  FirebaseMessaging.onMessage.listen(handleForegroundMessage);
  FirebaseMessaging.onMessageOpenedApp.listen(handleMessageOpenedApp);
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void initializeNotifications() {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );
}

class SizeTag extends StyleTag {
  SizeTag() : super('size');

  @override
  TextStyle transformStyle(
      TextStyle oldStyle, Map<String, String>? attributes) {
    if (attributes == null || attributes.isEmpty) {
      return oldStyle;
    }

    String? sizeValue = attributes.entries.first.value;
    double? fontSize;

    try {
      fontSize = double.parse(sizeValue);
    } catch (e) {
      fontSize = null; // Invalid size input
    }

    if (fontSize != null && fontSize > 0) {
      return oldStyle.copyWith(fontSize: fontSize);
    }

    // Fallback to default size if parsing fails
    return oldStyle;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Troop Tracker Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(0, 104, 169, 1.0),
          brightness: Brightness.dark, // Enforces a dark color scheme
        ),
        useMaterial3: true,
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  Future<bool> isLoggedIn() async {
    try {
      // Open the Hive box
      final box = Hive.box('TTMobileApp');

      // Retrieve and decode user data
      final rawData = box.get('userData');

      // Check if data exists
      if (rawData == null) {
        return false; // No data found, user is not logged in
      }

      final userData = json.decode(rawData);

      // Validate user data structure
      if (userData['user'] == null || userData['user']['user_id'] == null) {
        return false; // Invalid data, treat as not logged in
      }

      // Set user object (assuming _user is a global or class variable)
      _user = types.User(
        id: userData['user']['user_id'].toString(),
        firstName: userData['user']['username'], // Set the user's name
        imageUrl: userData['user']?['avatar_urls']?['s'], // Avatar URL
      );

      // Call a method to get the token
      await getToken(userData['user']['user_id'].toString());

      // Return true if all checks pass
      return true;
    } catch (e) {
      // Handle exceptions (e.g., decoding errors)
      print('Error in isLoggedIn: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasData && snapshot.data == true) {
          return const MyHomePage(title: 'Troop Tracker');
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    final response = await http.post(
      Uri.parse('${dotenv.env['FORUM_URL'].toString()}api/auth'),
      headers: {
        'XF-Api-Key':
            dotenv.env['API_KEY'].toString(), // Replace with your API key
        'XF-Api-User':
            dotenv.env['API_USER'].toString(), // Replace with your API user ID
      },
      body: {
        'login': _usernameController.text,
        'password': _passwordController.text,
      },
    );

    final userData = json.decode(response.body);

    if (response.statusCode == 200) {
      final box = Hive.box('TTMobileApp');
      box.put('userData', json.encode(userData));

      _user = types.User(
        id: userData!['user']['user_id'].toString(),
        firstName: userData?['user']['username'], // Set the user's name
        imageUrl: userData?['user']?['avatar_urls']
            ?['s'], // Replace with actual avatar URL or leave null
      );

      getToken(userData!['user']['user_id'].toString());

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const MyHomePage(title: 'Troop Tracker')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/logo.png',
                height: 200,
                width: 200,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
              const SizedBox(height: 50), // Space between button and links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      launchUrl(Uri.parse(
                          'https://www.fl501st.com/boards/index.php?help/terms/'));
                    },
                    child: const Text(
                      'Terms and Rules',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20), // Space between links
                  GestureDetector(
                    onTap: () {
                      launchUrl(Uri.parse(
                          'https://www.fl501st.com/boards/index.php?help/privacy-policy/'));
                    },
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  Future<void> _logout(BuildContext context) async {
    final box = Hive.box('TTMobileApp');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging out...')),
    );

    final response = await http.post(
      Uri.parse('https://www.fl501st.com/troop-tracker/mobileapi.php'),
      body: {
        'action': 'logoutFCM',
        'fcm': box.get('fcm'),
      },
    );

    if (response.statusCode == 200) {
      print('Success');
      await box.clear(); // Clear all data, ensuring complete logout
    } else {
      print('Fail');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occured while logging out!')),
      );
    }

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/logo.png',
              height: 200,
              width: 200,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TroopPage()),
                  );
                },
                child: const Text('View Troops'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatPage()),
                  );
                },
                child: const Text('Chat'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _logout(context),
                child: const Text('Log Out'),
              ),
            ),
            const SizedBox(height: 50), // Space between button and links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    launchUrl(Uri.parse(
                        'https://www.fl501st.com/boards/index.php?help/terms/'));
                  },
                  child: const Text(
                    'Terms and Rules',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(width: 20), // Space between links
                GestureDetector(
                  onTap: () {
                    launchUrl(Uri.parse(
                        'https://www.fl501st.com/boards/index.php?help/privacy-policy/'));
                  },
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
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

class EventPage extends StatefulWidget {
  final int troopid; // Accept troop ID as a parameter

  const EventPage({super.key, required this.troopid});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  Map<String, dynamic>? troopData;
  List<dynamic>? rosterData;

  // Helper to format date
  String formatDate(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) {
      return 'N/A'; // Return 'N/A' for missing or invalid dates
    }

    try {
      DateTime dt = DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateTime);
      return DateFormat('MM/dd/yyyy h:mm a').format(dt);
    } catch (e) {
      return 'Invalid Date'; // Return a fallback message if parsing fails
    }
  }

  Future<void> fetchEvent(int troopid) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://www.fl501st.com/troop-tracker/mobileapi.php?troopid=$troopid&action=event'),
      );

      if (!mounted) return; // Ensure widget is mounted before proceeding

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

  Future<void> fetchRoster(int troopid) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://www.fl501st.com/troop-tracker/mobileapi.php?troopid=$troopid&action=get_roster_for_event'),
      );

      if (!mounted) return; // Ensure widget is mounted before proceeding

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          rosterData = data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load roster.')),
        );
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request timed out. Please try again.')),
        );
      }
    } catch (e) {
      print(e);
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
    fetchEvent(widget.troopid);
    fetchRoster(widget.troopid);
  }

  @override
  Widget build(BuildContext context) {
    var extenedStyle =
        defaultBBStylesheet(textStyle: const TextStyle(color: Colors.white))
            .addTag(SizeTag());
    return Scaffold(
      appBar: AppBar(
        title: Text(
          unescape.convert(troopData?['name'] ?? ''),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Details
            Text(
              troopData?['venue'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text("Location: ${troopData?['location']}"),
            Text("Start: ${formatDate(troopData?['dateStart'] ?? '')}"),
            Text("End: ${formatDate(troopData?['dateEnd'] ?? '')}"),
            Text("Website: ${troopData?['website'] ?? ''}"),
            const SizedBox(height: 10),

            // Attendance Details
            Text(
              "Attendance Details",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text("Attendees: ${troopData?['numberOfAttend'] ?? ''}"),
            Text("Requested: ${troopData?['requestedNumber'] ?? ''}"),
            Text(
                "Requested Characters: ${troopData?['requestedCharacter'] ?? ''}"),
            const SizedBox(height: 10),

            // Amenities
            Text(
              "Amenities",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text("Restrooms: ${troopData?['amenities'] ?? 'N/A'}"),
            Text(
                "Secure Changing Area: ${(troopData?['secureChanging'] ?? 0) == 1 ? 'Yes' : 'No'}"),
            Text(
                "Blasters Allowed: ${(troopData?['blasters'] ?? 0) == 1 ? 'Yes' : 'No'}"),
            Text(
                "Lightsabers Allowed: ${(troopData?['lightsabers'] ?? 0) == 1 ? 'Yes' : 'No'}"),
            Text(
                "Parking Available: ${(troopData?['parking'] ?? 0) == 1 ? 'Yes' : 'No'}"),
            Text(
                "Mobility Accessible: ${(troopData?['mobility'] ?? 0) == 1 ? 'Yes' : 'No'}"),
            const SizedBox(height: 10),

            // POC Details
            Text(
              "Points of Contact",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text("Referred By: ${troopData?['referred'] ?? ''}"),
            //Text("POC Name: ${troopData?['poc'] ?? ''}"),
            const SizedBox(height: 10),

            // Comments Section
            Text(
              "Additional Information",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            BBCodeText(
                data: troopData?['comments'] ?? '', stylesheet: extenedStyle),
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
                          headingRowColor: MaterialStateProperty.resolveWith(
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                          troopName: unescape.convert(troopData?['name'] ?? ''),
                          threadId: troopData?['thread_id'] ?? '',
                          postId: troopData?['post_id'] ?? ''),
                    ),
                  );
                },
                child: Text('Go To Discussion'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      final response = await http.get(
        Uri.parse(
            'https://www.fl501st.com/troop-tracker/mobileapi.php?squad=$squad&action=get_troops_by_squad'),
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
    selectedSquad = 0;
    troops = [];
    fetchTroops(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Troops'),
        ),
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
                                (troops[index]['trooper_count'] ?? 0) ==
                                        0 // Explicit comparison to 0
                                    ? 'NOT ENOUGH TROOPERS FOR THIS EVENT!'
                                    : '${troops[index]['trooper_count']?.toString() ?? '0'} Troopers Attending',
                                style: TextStyle(
                                  color:
                                      (troops[index]['trooper_count'] ?? 0) ==
                                              0 // Explicit comparison to 0
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

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<dynamic> troops = [];

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
                      builder: (context) => ChatScreen(
                          troopName:
                              unescape.convert(troops[index]['name'] ?? ''),
                          threadId: troops[index]['thread_id'],
                          postId: troops[index]['post_id']),
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

class ChatScreen extends StatefulWidget {
  final String troopName;
  final int threadId;
  final int postId;

  const ChatScreen({
    super.key,
    required this.troopName,
    required this.threadId,
    required this.postId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];
  final imagePicker.ImagePicker _picker = imagePicker.ImagePicker();
  Timer? _timer; // Timer for polling

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _startMessagePolling(); // Start periodic updates
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer on exit
    super.dispose();
  }

  void _startMessagePolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      _fetchMessages(); // Fetch messages periodically
    });
  }

  Future<void> _fetchMessages() async {
    final response = await http.get(
      Uri.parse(
          '${dotenv.env['FORUM_URL'].toString()}api/threads/${widget.threadId}?with_posts=true&page=1'),
      headers: {
        'XF-Api-Key': dotenv.env['API_KEY'].toString(),
        'XF-Api-User': dotenv.env['API_USER'].toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.containsKey('thread') && data.containsKey('posts')) {
        final posts = data['posts'] as List;

        final fetchedMessages = posts
            .where((post) => post['message_state'] == 'visible')
            .map((post) {
          final user = post['User'];
          final avatarUrl = post['User']['avatar_urls']['s'] ?? '';

          return types.CustomMessage(
            author: types.User(
              id: user['user_id'].toString(),
              firstName: user['username'] ?? 'Unknown',
              imageUrl: avatarUrl,
            ),
            createdAt: post['post_date'] * 1000,
            id: post['post_id'].toString(),
            metadata: {'html': post['message_parsed']},
          );
        }).toList();

        setState(() {
          _messages = fetchedMessages.reversed.toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No discussion to display.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load messages.')),
      );
    }
  }

  Future<void> _addMessage(types.PartialText message) async {
    final box = Hive.box('TTMobileApp');
    final userData = await json.decode(box.get('userData'));

    final customMessage = types.CustomMessage(
      author: types.User(
        id: userData!['user']['user_id'].toString(),
        firstName: userData?['user']['username'],
        imageUrl: userData?['user']['avatar_urls']?['s'],
      ),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().toString(),
      metadata: {'html': message.text},
    );

    setState(() {
      _messages.insert(0, customMessage);
    });

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['FORUM_URL'].toString()}api/posts'),
        headers: {
          'XF-Api-Key': dotenv.env['API_KEY'].toString(),
          'XF-Api-User': userData!['user']['user_id'].toString(),
        },
        body: {
          'thread_id': widget.threadId.toString(),
          'message': message.text,
        },
      );

      if (response.statusCode != 200) {
        _removeMessage(customMessage.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message.')),
        );
      }
    } catch (error) {
      _removeMessage(customMessage.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message.')),
      );
    }
  }

  void _removeMessage(String messageId) {
    setState(() {
      _messages.removeWhere((message) => message.id == messageId);
    });
  }

  Future<void> _blockUser(String userId) async {
    final box = Hive.box('TTMobileApp');

    // Retrieve and decode user data
    final rawData = box.get('userData');
    final userData = json.decode(rawData);

    final response = await http.post(
      Uri.parse('https://www.fl501st.com/boards/mobileapi.php'
          '?action=block_user'
          '&blocker_id=${userData['user']['user_id']}'
          '&blocked_id=$userId'),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User blocked successfully!')),
      );
    } else {
      print(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to block user!')),
      );
    }
  }

  Future<void> _reportMessage(String messageId) async {
    final box = Hive.box('TTMobileApp');

    // Retrieve and decode user data
    final rawData = box.get('userData');
    final userData = json.decode(rawData);

    // Show a popup to input the report reason
    String? reportReason = await _showInputDialog(context);

    // Check if the user canceled the dialog or entered nothing
    if (reportReason == null || reportReason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report reason cannot be empty!')),
      );
      return; // Stop further execution
    }

    final response = await http.post(
      Uri.parse('https://www.fl501st.com/boards/mobileapi.php'
          '?action=report_post'
          '&reporter_id=${userData['user']['user_id']}'
          '&message=$reportReason'
          '&post_id=$messageId'),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message reported successfully!')),
      );
    } else {
      print(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report message!')),
      );
    }
  }

  Future<String?> _getAttachmentKey() async {
    try {
      final box = Hive.box('TTMobileApp');
      final userData = await json.decode(box.get('userData'));

      final response = await http.post(
        Uri.parse(
            '${dotenv.env['FORUM_URL'].toString()}api/attachments/new-key'),
        headers: {
          'XF-Api-Key': dotenv.env['API_KEY'].toString(),
          'XF-Api-User': userData!['user']['user_id'].toString(),
        },
        body: {
          'type': 'post',
          'context[thread_id]': widget.threadId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Attachment Key: ${data['key']}');
        return data['key'];
      } else {
        print('Failed to fetch attachment key: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching attachment key: $e');
      return null;
    }
  }

  // Upload image and add message
  Future<void> _addImageMessage(File imageFile) async {
    try {
      final box = Hive.box('TTMobileApp');
      final userData = await json.decode(box.get('userData'));

      // Fetch attachment key
      final attachmentKey = await _getAttachmentKey();
      if (attachmentKey == null) {
        throw Exception('Failed to retrieve attachment key.');
      }

      // Determine MIME type of the image
      final mimeType = lookupMimeType(imageFile.path);

      // Create a multipart request for XenForo API
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${dotenv.env['FORUM_URL'].toString()}api/attachments',
        ),
      );

      // Add API headers
      request.headers.addAll({
        'XF-Api-Key': dotenv.env['API_KEY'].toString(),
        'XF-Api-User': userData!['user']['user_id'].toString(),
      });

      // Attach the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'attachment',
          imageFile.path,
          contentType: MediaType.parse(mimeType!),
        ),
      );

      // Add attachment key
      request.fields['key'] = attachmentKey;

      // Send the request
      final response = await request.send();

      // Read response body
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 200 && data['attachment'] != null) {
        // Get the attachment ID from the response
        final attachmentId = data['attachment']['attachment_id'];

        // Construct the image URL (use thumbnail or full-size view URL)
        final imageUrl = data['attachment']['thumbnail_url'] ??
            data['attachment']['view_url'];

        final msg = types.CustomMessage(
          author: types.User(
            id: userData!['user']['user_id'].toString(),
            firstName: userData?['user']['username'],
            imageUrl: userData?['user']['avatar_urls']?['s'],
          ),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: DateTime.now().toString(),
          metadata: {'html': '<img src=\'$imageUrl\' />'},
        );

        // Add the image message to the chat
        setState(() {
          _messages.insert(0, msg);
        });

        try {
          final responseImagePost = await http.post(
            Uri.parse('${dotenv.env['FORUM_URL'].toString()}api/posts'),
            headers: {
              'XF-Api-Key': dotenv.env['API_KEY'].toString(),
              'XF-Api-User': userData!['user']['user_id'].toString(),
            },
            body: {
              'thread_id': widget.threadId.toString(),
              'message': '[IMG]${data['attachment']['direct_url']}[/IMG]',
              'attachment_key': attachmentKey,
            },
          );

          if (responseImagePost.statusCode != 200) {
            _removeMessage(msg.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to send message.')),
            );
          }
        } catch (error) {
          _removeMessage(msg.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send message.')),
          );
        }
      } else {
        // Show error if upload fails
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image.')),
        );
      }
    } catch (e) {
      // Catch and handle errors
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading image.')),
      );
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: imagePicker.ImageSource.gallery);

    if (pickedFile != null) {
      _addImageMessage(File(pickedFile.path)); // Upload image and send message
    }
  }

  // Capture image using camera
  Future<void> _captureImage() async {
    final pickedFile =
        await _picker.pickImage(source: imagePicker.ImageSource.camera);

    if (pickedFile != null) {
      _addImageMessage(File(pickedFile.path)); // Upload image and send message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.troopName}')),
      body: Chat(
        messages: _messages,
        onSendPressed: _addMessage,
        user: _user,
        onAttachmentPressed: () {
          // Show options to pick or capture image
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Camera'),
                    onTap: () {
                      Navigator.pop(context);
                      _captureImage();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo),
                    title: const Text('Gallery'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ],
              );
            },
          );
        },
        customMessageBuilder: (message, {required int messageWidth}) {
          final isSentByUser = message.author.id == _user.id;

          if (message.metadata != null &&
              message.metadata!.containsKey('html')) {
            final htmlContent = message.metadata!['html'];

            return GestureDetector(
              onLongPress: () {
                if (!isSentByUser) {
                  // Prevent reporting or blocking yourself
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.block),
                            title: const Text('Block User'),
                            onTap: () {
                              Navigator.pop(context);
                              _blockUser(message.author.id);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.report),
                            title: const Text('Report Message'),
                            onTap: () {
                              Navigator.pop(context);
                              _reportMessage(message.id);
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                color: isSentByUser
                    ? Colors.blue[500]
                    : Colors.grey[200], // Custom solid gray
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: isSentByUser
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!isSentByUser)
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                          message.author.imageUrl ??
                              'https://www.fl501st.com/assets/images/profile.png',
                        ),
                        radius: 20,
                      ),
                    if (!isSentByUser) const SizedBox(width: 8.0),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: isSentByUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.author.firstName ?? 'Unknown',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                color: !isSentByUser
                                    ? Colors.black
                                    : Colors.white),
                          ),
                          const SizedBox(height: 4.0),
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            constraints: BoxConstraints(
                              maxWidth: messageWidth.toDouble(),
                            ),
                            decoration: BoxDecoration(
                              color: isSentByUser
                                  ? Colors.blue[500]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: HtmlWidget(
                              htmlContent,
                              textStyle: TextStyle(
                                color: isSentByUser
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 16.0,
                              ),
                              customWidgetBuilder: (element) {
                                if (element.localName == 'img' &&
                                    element.attributes['src'] != null) {
                                  final imageUrl = element.attributes['src']!;
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Scaffold(
                                            appBar: AppBar(
                                              title: const Text('Image Viewer'),
                                              leading: IconButton(
                                                icon: Icon(Icons.arrow_back),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                            ),
                                            body: PhotoViewGallery.builder(
                                              itemCount: 1,
                                              builder: (context, index) {
                                                return PhotoViewGalleryPageOptions(
                                                  imageProvider:
                                                      NetworkImage(imageUrl),
                                                  minScale:
                                                      PhotoViewComputedScale
                                                          .contained,
                                                  maxScale:
                                                      PhotoViewComputedScale
                                                              .covered *
                                                          2,
                                                );
                                              },
                                              scrollPhysics:
                                                  const BouncingScrollPhysics(),
                                              backgroundDecoration:
                                                  BoxDecoration(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Image.network(imageUrl),
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSentByUser) const SizedBox(width: 8.0),
                    if (isSentByUser)
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                          message.author.imageUrl ??
                              'https://www.fl501st.com/assets/images/profile.png',
                        ),
                        radius: 20,
                      ),
                    if (isSentByUser) const SizedBox(width: 8.0)
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

Future<String?> _showInputDialog(BuildContext context) async {
  TextEditingController textController = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Report Message'),
      content: TextField(
        controller: textController,
        decoration: const InputDecoration(
          hintText: 'Enter reason for reporting...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null), // Cancel
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(textController.text), // Submit
          child: const Text('Submit'),
        ),
      ],
    ),
  );
}
