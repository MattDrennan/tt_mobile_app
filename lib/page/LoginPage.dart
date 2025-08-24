import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:tt_mobile_app/custom/AppBar.dart';
import 'package:tt_mobile_app/custom/Functions.dart';
import 'package:tt_mobile_app/page/MyHomePage.dart';
import 'package:url_launcher/url_launcher.dart';

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

    if (response.statusCode == 200 && userData?['success'] == true) {
      final box = Hive.box('TTMobileApp');
      box.put('userData', json.encode(userData));

      user = types.User(
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
