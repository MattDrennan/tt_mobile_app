import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../models/app_organization.dart';
import '../models/app_user.dart';
import '../models/chat_room.dart';
import '../services/api_client.dart';

/// Page-scoped controller for ChatListView and ChatScreenView.
class ChatController extends ChangeNotifier {
  final ApiClient _api;
  final AppUser currentUser;

  // ── Room list state ───────────────────────────────────────────────────────

  List<ChatRoom> _rooms = [];
  List<AppOrganization> _organizations = [];
  bool _isLoadingRooms = false;

  // ── Active chat state ─────────────────────────────────────────────────────

  List<types.CustomMessage> _messages = [];
  bool _isLoadingMessages = false;
  bool _isSending = false;
  Timer? _pollTimer;
  int? _activeThreadId;
  String? _actionError;

  ChatController(this._api, {required this.currentUser});

  // ── Exposed state ──────────────────────────────────────────────────────────

  List<ChatRoom> get rooms => _rooms;
  List<AppOrganization> get organizations => _organizations;
  List<types.CustomMessage> get messages => _messages;
  bool get isLoadingRooms => _isLoadingRooms;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;
  String? get actionError => _actionError;

  // ── Room list ──────────────────────────────────────────────────────────────

  Future<void> fetchRooms() async {
    _isLoadingRooms = true;
    notifyListeners();
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({
          'user_id': currentUser.id,
          'action': 'troops',
        }),
      );
      final list = (data as Map<String, dynamic>)['troops'] as List? ?? [];
      _rooms = list
          .map((t) => ChatRoom.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (_) {
    } finally {
      _isLoadingRooms = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrganizations() async {
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({'action': 'get_organizations'}),
      );
      final list =
          (data as Map<String, dynamic>)['organizations'] as List? ?? [];
      _organizations = list
          .map((o) => AppOrganization.fromJson(o as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  String iconForRoom(ChatRoom room) {
    final org = _organizations.where((o) => o.id == room.squad).firstOrNull;
    return org?.iconPath ?? AppOrganization.fallbackIcon;
  }

  // ── Active chat ────────────────────────────────────────────────────────────

  void openRoom(int threadId) {
    _activeThreadId = threadId;
    _messages = [];
    fetchMessages();
    startPolling();
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchMessages();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> fetchMessages() async {
    if (_activeThreadId == null) return;
    _isLoadingMessages = true;
    notifyListeners();
    try {
      final response = await http.get(
        _api.forumApiUri('threads/$_activeThreadId', {
          'with_posts': true,
          'page': 1,
        }),
        headers: {
          'XF-Api-Key': dotenv.env['API_KEY'].toString(),
          'XF-Api-User': dotenv.env['API_USER'].toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data.containsKey('thread') && data.containsKey('posts')) {
          final posts = data['posts'] as List;
          final fetched =
              posts.where((p) => p['message_state'] == 'visible').map((post) {
            final u = post['User'] as Map<String, dynamic>;
            return types.CustomMessage(
              author: types.User(
                id: u['user_id'].toString(),
                firstName: u['username']?.toString() ?? 'Unknown',
                imageUrl: u['avatar_urls']?['s'] as String?,
              ),
              createdAt: (post['post_date'] as num).toInt() * 1000,
              id: post['post_id'].toString(),
              metadata: {'html': post['message_parsed']},
            );
          }).toList();
          _messages = fetched.reversed.toList();
        }
      }
    } catch (_) {
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String text) async {
    if (_activeThreadId == null) return false;
    _isSending = true;
    _actionError = null;

    // Optimistic insert
    final optimistic = types.CustomMessage(
      author: currentUser.toChatUser(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().toString(),
      metadata: {'html': text},
    );
    _messages.insert(0, optimistic);
    notifyListeners();

    try {
      final response = await http.post(
        _api.forumApiUri('posts'),
        headers: {
          'XF-Api-Key': dotenv.env['API_KEY'].toString(),
          'XF-Api-User': currentUser.id,
        },
        body: {
          'thread_id': _activeThreadId.toString(),
          'message': text,
        },
      );

      if (response.statusCode != 200) {
        _removeMessage(optimistic.id);
        _actionError = 'Failed to send message.';
        _isSending = false;
        notifyListeners();
        return false;
      }

      _isSending = false;
      notifyListeners();
      return true;
    } catch (_) {
      _removeMessage(optimistic.id);
      _actionError = 'Failed to send message.';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendImageMessage(File imageFile) async {
    if (_activeThreadId == null) return false;

    // Get attachment key
    final attachmentKey = await _getAttachmentKey();
    if (attachmentKey == null) {
      _actionError = 'Failed to retrieve attachment key.';
      notifyListeners();
      return false;
    }

    _isSending = true;
    notifyListeners();

    try {
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final request = http.MultipartRequest(
        'POST',
        _api.forumApiUri('attachments'),
      )
        ..headers.addAll({
          'XF-Api-Key': dotenv.env['API_KEY'].toString(),
          'XF-Api-User': currentUser.id,
        })
        ..files.add(await http.MultipartFile.fromPath(
          'attachment',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ))
        ..fields['key'] = attachmentKey;

      final uploadResponse = await request.send();
      final uploadData =
          json.decode(await uploadResponse.stream.bytesToString())
              as Map<String, dynamic>;

      if (uploadResponse.statusCode != 200 ||
          uploadData['attachment'] == null) {
        _actionError = _extractForumError(
            json.encode(uploadData), 'Failed to upload image.');
        _isSending = false;
        notifyListeners();
        return false;
      }

      final attachment = uploadData['attachment'] as Map<String, dynamic>;
      final imageUrl = attachment['thumbnail_url'] ?? attachment['view_url'];
      final directUrl = attachment['direct_url'];

      // Optimistic insert
      final optimistic = types.CustomMessage(
        author: currentUser.toChatUser(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: DateTime.now().toString(),
        metadata: {'html': '<img src=\'$imageUrl\' />'},
      );
      _messages.insert(0, optimistic);
      notifyListeners();

      final postResponse = await http.post(
        _api.forumApiUri('posts'),
        headers: {
          'XF-Api-Key': dotenv.env['API_KEY'].toString(),
          'XF-Api-User': currentUser.id,
        },
        body: {
          'thread_id': _activeThreadId.toString(),
          'message': '[IMG]$directUrl[/IMG]',
          'attachment_key': attachmentKey,
        },
      );

      if (postResponse.statusCode != 200) {
        _removeMessage(optimistic.id);
        _actionError = 'Failed to send image message.';
        _isSending = false;
        notifyListeners();
        return false;
      }

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = 'Error uploading image: $e';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> blockUser(String targetUserId) async {
    try {
      final response = await http.get(
        _api.forumApiUri('trooper-api/block-user', {
          'blocked_id': targetUserId,
        }),
        headers: {
          'XF-Api-Key': dotenv.env['API_KEY'].toString(),
          'XF-Api-User': currentUser.id,
        },
      );
      final success = response.statusCode == 200;
      if (!success) {
        _actionError = _extractForumError(
          response.body,
          'Failed to block user.',
        );
        notifyListeners();
      }
      return success;
    } catch (_) {
      _actionError = 'Failed to block user.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> reportMessage(String messageId, String reason) async {
    try {
      final response = await http.get(
        _api.forumApiUri('trooper-api/report-post', {
          'post_id': messageId,
          'message': reason,
        }),
        headers: {
          'XF-Api-Key': dotenv.env['API_KEY'].toString(),
          'XF-Api-User': currentUser.id,
        },
      );
      final success = response.statusCode == 200;
      if (!success) {
        _actionError = _extractForumError(
          response.body,
          'Failed to report message.',
        );
        notifyListeners();
      }
      return success;
    } catch (_) {
      _actionError = 'Failed to report message.';
      notifyListeners();
      return false;
    }
  }

  void clearActionError() {
    _actionError = null;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _removeMessage(String id) {
    _messages.removeWhere((m) => m.id == id);
  }

  Future<String?> _getAttachmentKey() async {
    try {
      final response = await http.post(
        _api.forumApiUri('attachments/new-key'),
        headers: {
          'XF-Api-Key': dotenv.env['API_KEY'].toString(),
          'XF-Api-User': currentUser.id,
        },
        body: {
          'type': 'post',
          'context[thread_id]': _activeThreadId.toString(),
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['key'] as String?;
      }
    } catch (_) {}
    return null;
  }

  String _extractForumError(String body, String fallback) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];
        if (errors is List && errors.isNotEmpty) {
          final first = errors.first;
          if (first is Map<String, dynamic>) {
            final msg = first['message']?.toString();
            if (msg != null && msg.isNotEmpty) return msg;
          }
        }
        final error = decoded['error']?.toString();
        if (error != null && error.isNotEmpty) return error;
      }
    } catch (_) {}
    return fallback;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
