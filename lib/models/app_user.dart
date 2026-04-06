import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

/// Domain model for the logged-in user.
/// Replaces the global `types.User user` variable in Functions.dart.
class AppUser {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? tkid;

  const AppUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.tkid,
  });

  /// Builds from the `user` sub-object returned by the mobile login API.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['user_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatarUrl: json['avatar_urls']?['s'] as String?,
      tkid: json['tkid']?.toString(),
    );
  }

  /// Converts to the flutter_chat_types.User required by the Chat widget.
  types.User toChatUser() => types.User(
        id: id,
        firstName: username,
        imageUrl: avatarUrl,
      );

  @override
  String toString() => username;
}
