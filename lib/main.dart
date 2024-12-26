import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:tt_mobile_app/services/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart' as imagePicker;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:photo_view/photo_view.dart';

// Global
types.User _user = const types.User(id: 'user');
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm', fcmToken);
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
    final prefs = await SharedPreferences.getInstance();
    final userData = await SharedPrefsService().getUserData();

    _user = types.User(
      id: userData!['user']['user_id'].toString(),
      firstName: userData?['user']['username'], // Set the user's name
      imageUrl: userData?['user']?['avatar_urls']
          ?['s'], // Replace with actual avatar URL or leave null
    );

    getToken(userData!['user']['user_id'].toString());

    return prefs.containsKey('userData');
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', json.encode(userData));

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
    final prefs = await SharedPreferences.getInstance();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging out...')),
    );

    final response = await http.post(
      Uri.parse('https://www.fl501st.com/troop-tracker/mobileapi.php'),
      body: {
        'action': 'logoutFCM',
        'fcm': prefs.getString('fcm'),
      },
    );

    if (response.statusCode == 200) {
      print('Success');
      await prefs.clear(); // Clear all data, ensuring complete logout
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
            /*ElevatedButton(
          onPressed: () {
            // Navigate to View Troops page
          },
          child: const Text('View Troops'),
        ),
        const SizedBox(height: 20),*/
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
          ],
        ),
      ),
    );
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
    final userData = await SharedPrefsService().getUserData();
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
        title: const Text('Troops'),
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
                          troopName: troops[index]['name'],
                          threadId: troops[index]['thread_id'],
                          postId: troops[index]['post_id']),
                    ),
                  );
                },
                child: Text(troops[index]['name']),
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
    final userData = await SharedPrefsService().getUserData();

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

  Future<String?> _getAttachmentKey() async {
    try {
      final userData = await SharedPrefsService().getUserData();

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
      final userData = await SharedPrefsService().getUserData();

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

          if (message is types.CustomMessage &&
              message.metadata != null &&
              message.metadata!.containsKey('html')) {
            final htmlContent = message.metadata!['html'];

            return Row(
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
                            color: !isSentByUser ? Colors.black : Colors.white),
                      ),
                      const SizedBox(height: 4.0),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        constraints: BoxConstraints(
                          maxWidth: messageWidth.toDouble(),
                        ),
                        decoration: BoxDecoration(
                          color: isSentByUser
                              ? Colors.blue[400]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: HtmlWidget(
                          htmlContent,
                          textStyle: TextStyle(
                            color: isSentByUser ? Colors.white : Colors.black87,
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
                                              minScale: PhotoViewComputedScale
                                                  .contained,
                                              maxScale: PhotoViewComputedScale
                                                      .covered *
                                                  2,
                                            );
                                          },
                                          scrollPhysics:
                                              const BouncingScrollPhysics(),
                                          backgroundDecoration: BoxDecoration(
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
                if (isSentByUser)
                  const SizedBox(width: 8.0), // Space for alignment
                if (isSentByUser) // Show avatar only for received messages
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      message.author.imageUrl ??
                          'https://www.fl501st.com/assets/images/profile.png', // Placeholder image
                    ),
                    radius: 20,
                  ),
                if (isSentByUser) const SizedBox(width: 8.0)
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
