import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
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
  bool _isLoggingIn = false;

  String get _forumBaseUrl =>
      (dotenv.env['FORUM_URL'] ?? 'https://www.fl501st.com/boards/')
          .replaceAll(RegExp(r'/+$'), '');

  String get _mobileApiUrl =>
      dotenv.env['MOBILE_API_URL'] ??
      'https://www.fl501st.com/troop-tracker/mobile-api';

  String get _oauthClientId => dotenv.env['OAUTH_CLIENT_ID'] ?? '';

  String get _authorizePath =>
      dotenv.env['OAUTH_AUTHORIZE_PATH'] ?? '/index.php?oauth2/authorize';

  String get _tokenPath =>
      dotenv.env['OAUTH_TOKEN_PATH'] ?? '/index.php?api/oauth2/token';

  String get _redirectUri =>
      dotenv.env['OAUTH_REDIRECT_URI'] ??
      'https://redirectmeto.com/ttmobileapp://oauth-callback';

  String get _callbackScheme =>
      dotenv.env['OAUTH_CALLBACK_SCHEME'] ?? 'ttmobileapp';

  String get _oauthScopes => dotenv.env['OAUTH_SCOPES'] ?? 'user:read';

  String _buildRandomString([int length = 64]) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();

    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _buildCodeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));

    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String _buildAuthorizeUrl({
    required String state,
    required String codeChallenge,
  }) {
    final query = <String, String>{
      'response_type': 'code',
      'client_id': _oauthClientId,
      'redirect_uri': _redirectUri,
      'scope': _oauthScopes,
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };

    return '$_forumBaseUrl$_authorizePath&${Uri(queryParameters: query).query}';
  }

  Uri _buildTokenUri() {
    return Uri.parse('$_forumBaseUrl$_tokenPath');
  }

  Future<String> _exchangeCodeForAccessToken({
    required String code,
    required String verifier,
  }) async {
    final response = await http.post(
      _buildTokenUri(),
      headers: const {
        'Accept': 'application/json',
      },
      body: {
        'grant_type': 'authorization_code',
        'client_id': _oauthClientId,
        'redirect_uri': _redirectUri,
        'code': code,
        'code_verifier': verifier,
      },
    );

    final payload = json.decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload is Map<String, dynamic>
          ? (payload['error_description'] ??
                  payload['error'] ??
                  'OAuth token exchange failed.')
              .toString()
          : 'OAuth token exchange failed.';

      throw Exception(message);
    }

    if (payload is! Map<String, dynamic> || payload['access_token'] == null) {
      throw Exception('OAuth token response did not contain an access token.');
    }

    return payload['access_token'].toString();
  }

  Future<void> _completeMobileLogin(String accessToken) async {
    final response = await http.post(
      Uri.parse(_mobileApiUrl),
      body: {
        'action': 'login_with_forum',
        'access_token': accessToken,
      },
    );

    final userData = json.decode(response.body);

    if (response.statusCode != 200 || userData?['success'] != true) {
      final message = userData is Map<String, dynamic>
          ? (userData['error'] ?? 'Login failed.').toString()
          : 'Login failed.';

      throw Exception(message);
    }

    final box = Hive.box('TTMobileApp');
    await box.put('userData', json.encode(userData));
    await box.put('apiKey', userData?['apiKey']);

    user = types.User(
      id: userData['user']['user_id'].toString(),
      firstName: userData['user']['username'],
      imageUrl: userData['user']?['avatar_urls']?['s'],
    );

    await getToken(userData['user']['user_id'].toString());

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MyHomePage(title: 'Troop Tracker'),
      ),
    );
  }

  Future<void> _login() async {
    if (_isLoggingIn) {
      return;
    }

    if (_oauthClientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OAuth client ID is not configured.')),
      );

      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {
      final state = _buildRandomString(32);
      final verifier = _buildRandomString(96);
      final challenge = _buildCodeChallenge(verifier);

      final callbackUrl = await FlutterWebAuth2.authenticate(
        url: _buildAuthorizeUrl(state: state, codeChallenge: challenge),
        callbackUrlScheme: _callbackScheme,
      );

      final callbackUri = Uri.parse(callbackUrl);
      final returnedState = callbackUri.queryParameters['state'];
      final code = callbackUri.queryParameters['code'];
      final error = callbackUri.queryParameters['error'];

      if (error != null) {
        throw Exception(error);
      }

      if (returnedState != state) {
        throw Exception('OAuth state mismatch.');
      }

      if (code == null || code.isEmpty) {
        throw Exception(
            'OAuth callback did not include an authorization code.');
      }

      final accessToken = await _exchangeCodeForAccessToken(
        code: code,
        verifier: verifier,
      );

      await _completeMobileLogin(accessToken);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
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
              const Text(
                'Sign in with your Florida Garrison forum account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoggingIn ? null : _login,
                child: _isLoggingIn
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue with XenForo'),
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
