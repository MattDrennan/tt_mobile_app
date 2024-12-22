import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:tt_mobile_app/services/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Global
types.User _user = const types.User(id: 'user');

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const MyHomePage(title: 'Troop Tracker')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all data, ensuring complete logout

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging out...')),
    );

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/logo.png',
              height: 200,
              width: 200,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to View Troops page
              },
              child: const Text('View Troops'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatPage()),
                );
              },
              child: const Text('Chat'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _logout(context),
              child: const Text('Log Out'),
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
      body: ListView.builder(
        itemCount: troops.length,
        itemBuilder: (context, index) {
          return ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    troopName: troops[index]['name'],
                    threadId: troops[index]['thread_id'],
                  ),
                ),
              );
            },
            child: Text(troops[index]['name']),
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String troopName;
  final int threadId;

  const ChatScreen({
    super.key,
    required this.troopName,
    required this.threadId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
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
            metadata: {'html': post['message_parsed']}, // Store HTML content
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

    // Create the CustomMessage object for immediate display
    final customMessage = types.CustomMessage(
      author: types.User(
        id: userData!['user']['user_id'].toString(),
        firstName: userData?['user']['username'], // User's name
        imageUrl: userData?['user']['avatar_urls']?['s'], // Avatar URL
      ),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().toString(),
      metadata: {'html': message.text}, // Store text as HTML
    );

    // Add the message to the UI immediately
    setState(() {
      _messages.insert(0, customMessage);
    });

    try {
      // Send POST request to XenForo API
      final response = await http.post(
        Uri.parse('${dotenv.env['FORUM_URL'].toString()}api/posts'),
        headers: {
          'XF-Api-Key':
              dotenv.env['API_KEY'].toString(), // Replace with your API key
          'XF-Api-User': userData!['user']['user_id']
              .toString(), // Replace with your API user ID
        },
        body: {
          'thread_id':
              widget.threadId.toString(), // Replace with your thread ID
          'message': message.text, // Text message to post
        },
      );

      // Handle the API response
      if (response.statusCode == 200) {
        print('Message posted successfully: ${response.body}');
      } else {
        print('Failed to post message: ${response.statusCode}');
        print('Response: ${response.body}');
        _removeMessage(customMessage.id); // Remove message if posting fails
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message.')),
        );
      }
    } catch (error) {
      print('Error posting message: $error');
      _removeMessage(customMessage.id); // Remove message if an error occurs
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message.')),
      );
    }
  }

// Function to remove a message
  void _removeMessage(String messageId) {
    setState(() {
      _messages.removeWhere((message) => message.id == messageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.troopName}')),
      body: Chat(
        messages: _messages,
        onSendPressed: _addMessage,
        user: _user,
        // Custom message builder for rendering HTML
        customMessageBuilder: (message, {required int messageWidth}) {
          // Determine if the message was sent by the user
          final isSentByUser = message.author.id == _user.id;

          if (message is types.CustomMessage &&
              message.metadata != null &&
              message.metadata!.containsKey('html')) {
            final htmlContent = message.metadata!['html'];

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: isSentByUser
                  ? MainAxisAlignment.end // Sent messages on the right
                  : MainAxisAlignment.start, // Received messages on the left
              children: [
                if (!isSentByUser) // Show avatar only for received messages
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      message.author.imageUrl ??
                          'https://www.fl501st.com/assets/images/profile.png', // Placeholder image
                    ),
                    radius: 20,
                  ),
                if (!isSentByUser)
                  const SizedBox(width: 8.0), // Spacing for avatar
                Flexible(
                  child: Column(
                    crossAxisAlignment: isSentByUser
                        ? CrossAxisAlignment.end // Sent messages aligned right
                        : CrossAxisAlignment.start, // Received aligned left
                    children: [
                      // Display name above the message
                      Text(
                        message.author.firstName ?? 'Unknown',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                            color: !isSentByUser ? Colors.black : Colors.white),
                      ),
                      const SizedBox(
                          height: 4.0), // Spacing between name and bubble
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        constraints: BoxConstraints(
                          maxWidth: messageWidth.toDouble(),
                        ),
                        decoration: BoxDecoration(
                          color: isSentByUser
                              ? Colors.blue[400] // Sent message color
                              : Colors.grey[300], // Received message color
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16.0),
                            topRight: const Radius.circular(16.0),
                            bottomLeft: isSentByUser
                                ? const Radius.circular(16.0)
                                : const Radius.circular(
                                    4.0), // Pointed for received
                            bottomRight: isSentByUser
                                ? const Radius.circular(4.0) // Pointed for sent
                                : const Radius.circular(16.0),
                          ),
                        ),
                        child: HtmlWidget(
                          htmlContent,
                          textStyle: TextStyle(
                            color: isSentByUser
                                ? Colors.white // Text color for sent messages
                                : Colors
                                    .black87, // Text color for received messages
                            fontSize: 16.0,
                          ),
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

          return const SizedBox.shrink(); // Fallback for unsupported messages
        },
      ),
    );
  }
}
