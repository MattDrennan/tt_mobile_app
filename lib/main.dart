import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:tt_mobile_app/custom/AppBar.dart';
import 'package:tt_mobile_app/custom/Functions.dart';
import 'package:tt_mobile_app/page/ConfirmPage.dart';
import 'package:tt_mobile_app/page/myTroops.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html_unescape/html_unescape.dart';

import 'page/ChatScreen.dart';
import 'page/EventPage.dart';

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

    // Open the Hive box
    final box = Hive.box('TTMobileApp');

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
        headers: {
          'API-Key': box.get('apiKey') ?? '',
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

Future<bool> fetchConfirmTroops(int trooperid) async {
  try {
    // Open the Hive box
    final box = Hive.box('TTMobileApp');

    final response = await http.get(
      Uri.parse(
          'https://www.fl501st.com/troop-tracker/mobileapi.php?trooperid=$trooperid&action=get_confirm_events_trooper'),
      headers: {
        'API-Key': box.get('apiKey') ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Check if 'troops' exists and is not empty
      if (data['troops'] != null && (data['troops'] as List).isNotEmpty) {
        return true; // Troops are present
      } else {
        return false; // No troops available
      }
    } else {
      return false; // HTTP error
    }
  } catch (e) {
    return false; // Exception occurred
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

      // Store the apiKey in the Hive box if it exists
      final apiKey = userData?['apiKey'];
      if (apiKey != null) {
        box.put('apiKey', apiKey); // Save the apiKey
      } else {
        print('apiKey not found in userData');
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
      Uri.parse(
          'https://www.fl501st.com/troop-tracker/mobileapi.php?action=login_with_forum'),
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

      box.put('apiKey', userData?['apiKey']);

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
      appBar: buildAppBar(context, 'Troop Tracker'),
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<bool> confirmTroopsFuture;

  @override
  void initState() {
    super.initState();
    confirmTroopsFuture = fetchConfirmTroops(int.parse(_user.id));
  }

  void refreshConfirmTroops() {
    setState(() {
      confirmTroopsFuture = fetchConfirmTroops(int.parse(_user.id));
    });
  }

  Future<void> _logout(BuildContext context) async {
    final box = Hive.box('TTMobileApp');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging out...')),
    );

    final response = await http.post(
      Uri.parse('https://www.fl501st.com/troop-tracker/mobileapi.php'),
      body: {
        'action': 'logoutFCM',
        'apiKey': box.get('apiKey') ?? '',
        'fcm': box.get('fcm') ?? '',
      },
      headers: {
        'API-Key': box.get('apiKey') ?? '',
      },
    );

    if (response.statusCode == 200) {
      print('Success');
      await box.clear(); // Clear all data, ensuring complete logout
    } else {
      print('Fail');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while logging out!')),
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
      appBar: buildAppBar(context, widget.title),
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
                    MaterialPageRoute(builder: (context) => const myTroops()),
                  ).then((_) => refreshConfirmTroops()); // Refresh on return
                },
                child: const Text('My Troops'),
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
                  ).then((_) => refreshConfirmTroops()); // Refresh on return
                },
                child: const Text('Chat'),
              ),
            ),
            const SizedBox(height: 20),
            // Confirm Troops Button (conditionally displayed)
            FutureBuilder<bool>(
              future: confirmTroopsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConfirmPage(
                                  trooperId: int.parse(_user.id),
                                ),
                              ),
                            ).then((_) =>
                                refreshConfirmTroops()); // Refresh on return
                          },
                          child: const Text('Confirm Troops'),
                        ),
                      ),
                      const SizedBox(height: 20), // Add some spacing
                    ],
                  );
                } else {
                  return const SizedBox.shrink(); // Don't render anything
                }
              },
            ),
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
