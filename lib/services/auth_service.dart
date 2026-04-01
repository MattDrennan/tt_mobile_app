import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'storage_service.dart';

/// Handles OAuth2 PKCE login flow and session management.
/// Has no Flutter widget dependencies — returns data, never navigates.
class AuthService {
  final StorageService _storage;
  final ApiClient _api;

  AuthService(this._storage, this._api);

  // ── OAuth config ─────────────────────────────────────────────────────────

  String get _forumBaseUrl =>
      (dotenv.env['FORUM_URL'] ?? 'https://www.fl501st.com/boards/')
          .replaceAll(RegExp(r'/+$'), '');

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

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _randomString([int length = 64]) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _codeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String _authorizeUrl({
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

  dynamic _decodeJsonBody({
    required String body,
    required Uri uri,
    required String operation,
  }) {
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html')) {
      throw Exception(
        '$operation returned HTML instead of JSON from $uri.',
      );
    }
    try {
      return json.decode(body);
    } on FormatException {
      throw Exception('$operation returned an invalid JSON response from $uri.');
    }
  }

  Future<String> _exchangeCodeForToken({
    required String code,
    required String verifier,
  }) async {
    final tokenUri = Uri.parse('$_forumBaseUrl$_tokenPath');
    final response = await http.post(
      tokenUri,
      headers: const {'Accept': 'application/json'},
      body: {
        'grant_type': 'authorization_code',
        'client_id': _oauthClientId,
        'redirect_uri': _redirectUri,
        'code': code,
        'code_verifier': verifier,
      },
    );

    final payload = _decodeJsonBody(
      body: response.body,
      uri: tokenUri,
      operation: 'OAuth token exchange',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload is Map<String, dynamic>
          ? (payload['error_description'] ?? payload['error'] ?? 'OAuth token exchange failed.').toString()
          : 'OAuth token exchange failed.';
      throw Exception(message);
    }

    if (payload is! Map<String, dynamic> || payload['access_token'] == null) {
      throw Exception('OAuth token response did not contain an access token.');
    }

    return payload['access_token'].toString();
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Runs the full OAuth2 PKCE login flow.
  ///
  /// On success: saves userData + apiKey to storage and returns the raw user
  /// data map (the `user` sub-object) so the caller can build an [AppUser].
  /// On failure: throws [Exception] with a human-readable message.
  Future<Map<String, dynamic>> performOAuthLogin() async {
    if (_oauthClientId.isEmpty) {
      throw Exception('OAuth client ID is not configured.');
    }

    final state = _randomString(32);
    final verifier = _randomString(96);
    final challenge = _codeChallenge(verifier);

    final callbackUrl = await FlutterWebAuth2.authenticate(
      url: _authorizeUrl(state: state, codeChallenge: challenge),
      callbackUrlScheme: _callbackScheme,
    );

    final callbackUri = Uri.parse(callbackUrl);
    final returnedState = callbackUri.queryParameters['state'];
    final code = callbackUri.queryParameters['code'];
    final error = callbackUri.queryParameters['error'];

    if (error != null) throw Exception(error);
    if (returnedState != state) throw Exception('OAuth state mismatch.');
    if (code == null || code.isEmpty) {
      throw Exception('OAuth callback did not include an authorization code.');
    }

    final accessToken = await _exchangeCodeForToken(
      code: code,
      verifier: verifier,
    );

    // Complete login with the mobile API
    final mobileUri = _api.mobileApiUri();
    final response = await http.post(
      mobileUri,
      headers: const {'Accept': 'application/json'},
      body: {
        'action': 'login_with_forum',
        'access_token': accessToken,
      },
    );

    final loginData = _decodeJsonBody(
      body: response.body,
      uri: mobileUri,
      operation: 'Troop Tracker mobile login',
    );

    if (response.statusCode != 200 || loginData?['success'] != true) {
      final message = loginData is Map<String, dynamic>
          ? (loginData['error'] ?? 'Login failed.').toString()
          : 'Login failed.';
      throw Exception(message);
    }

    // Persist credentials
    await _storage.saveLoginData(
      userData: json.encode(loginData),
      apiKey: loginData['apiKey'] as String,
    );

    return loginData['user'] as Map<String, dynamic>;
  }

  /// Restores session from storage.
  ///
  /// Returns the raw user data map if a valid session exists, or null.
  Map<String, dynamic>? restoreSession() {
    final rawData = _storage.getUserData();
    if (rawData == null) return null;

    try {
      final data = json.decode(rawData) as Map<String, dynamic>;
      if (data['user'] == null || data['user']['user_id'] == null) return null;
      // Re-save apiKey in case it was only in userData
      final apiKey = data['apiKey'] as String?;
      if (apiKey != null && _storage.getApiKey() == null) {
        _storage.saveLoginData(userData: rawData, apiKey: apiKey);
      }
      return data['user'] as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clears all session data from storage.
  Future<void> clearSession() async {
    await _storage.clearAll();
  }
}
