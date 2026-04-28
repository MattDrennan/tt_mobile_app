import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'storage_service.dart';

/// Thrown when an HTTP request returns a non-2xx status code.
class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}

/// Central HTTP client.
///
/// Provides:
/// - URI builder helpers (moved verbatim from Functions.dart)
/// - Authenticated GET/POST helpers that attach the API-Key header
class ApiClient {
  final StorageService _storage;

  ApiClient(this._storage);

  // ── URI builders ─────────────────────────────────────────────────────────

  Uri _buildConfiguredUri(String rawUrl,
      [Map<String, dynamic>? queryParameters]) {
    var uri = Uri.parse(rawUrl);

    if (Platform.isAndroid &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      uri = uri.replace(host: '10.0.2.2');
    }

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final mergedQuery = <String, String>{
      ...uri.queryParameters,
      ...queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    };

    return uri.replace(queryParameters: mergedQuery);
  }

  Uri mobileApiUri([Map<String, dynamic>? queryParameters]) {
    final rawUrl = dotenv.env['MOBILE_API_URL'] ??
        'https://www.fl501st.com/troop-tracker/mobile-api';
    return _buildConfiguredUri(rawUrl, queryParameters);
  }

  Uri forumApiUri(String path, [Map<String, dynamic>? queryParameters]) {
    final rawBaseUrl = dotenv.env['FORUM_API_BASE_URL'];
    if (rawBaseUrl == null || rawBaseUrl.isEmpty) {
      throw StateError('FORUM_API_BASE_URL is not configured in .env');
    }
    final baseUri = _buildConfiguredUri(rawBaseUrl);
    final normalizedBasePath = baseUri.path.replaceAll(RegExp(r'/+$'), '');
    final normalizedChildPath = path.replaceFirst(RegExp(r'^/+'), '');
    return _buildConfiguredUri(
      baseUri
          .replace(path: '$normalizedBasePath/$normalizedChildPath')
          .toString(),
      queryParameters,
    );
  }

  // ── Default headers ──────────────────────────────────────────────────────

  Map<String, String> get _apiKeyHeaders => {
        'API-Key': _storage.getApiKey() ?? '',
      };

  /// Authorization headers for XenForo forum API requests using OAuth.
  ///
  /// The stored apiKey value is the XenForo OAuth access token returned
  /// from the forum and persisted via [StorageService]. When present,
  /// we send it as a Bearer token for all /api/* calls.
  Map<String, String> get forumAuthHeaders {
    final token = _storage.getApiKey();
    if (token == null || token.isEmpty) return const {};
    return {
      'Authorization': 'Bearer $token',
    };
  }

  // ── HTTP helpers ─────────────────────────────────────────────────────────

  /// Performs an authenticated GET and returns decoded JSON.
  /// Throws [ApiException] on non-2xx responses.
  Future<dynamic> getJson(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final response = await http.get(
      uri,
      headers: {..._apiKeyHeaders, ...?headers},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
    return json.decode(response.body);
  }

  /// Performs an authenticated POST and returns decoded JSON.
  /// Throws [ApiException] on non-2xx responses.
  Future<dynamic> postJson(
    Uri uri,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final bodyStr = body.map((k, v) => MapEntry(k, v.toString()));
    final response = await http.post(
      uri,
      body: bodyStr,
      headers: {..._apiKeyHeaders, ...?headers},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
    return json.decode(response.body);
  }

  /// Fetches a forum thread with its posts. Extracted so FakeApiClient can
  /// override it for screenshot tests without touching the HTTP layer.
  Future<dynamic> getThread(int threadId, {int page = 1}) => getJson(
        forumApiUri('threads/$threadId', {'with_posts': true, 'page': page}),
        headers: forumAuthHeaders,
      );

  /// Performs a multipart POST using the mobile API-Key header.
  Future<http.StreamedResponse> postMultipart(
    Uri uri, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Map<String, String>? headers,
  }) async {
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({..._apiKeyHeaders, ...?headers});
    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files);
    return request.send();
  }
}
