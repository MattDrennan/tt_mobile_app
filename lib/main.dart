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
import 'package:tt_mobile_app/custom/Functions.dart';
import 'package:tt_mobile_app/page/LoginPage.dart';
import 'package:tt_mobile_app/page/MyHomePage.dart';
import 'package:html_unescape/html_unescape.dart';
import 'page/ChatScreen.dart';

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
  Future.delayed(const Duration(milliseconds: 500), () {
    if (navigatorKey.currentContext != null) {
      Navigator.push(
        navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            troopName: troopName,
            threadId: threadId,
            postId: postId,
          ),
        ),
      );
    } else {
      print('Navigator context is null');
    }
  });
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
      user = types.User(
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong.')),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          // Already logged in
          return const MyHomePage(title: 'Troop Tracker');
        }

        // Not logged in
        return const LoginPage();
      },
    );
  }
}
