/// A troop entry shown in the chat room list.
/// The app uses the same `troops` endpoint for both MyTroops and Chat lists.
class ChatRoom {
  final int id;
  final String name;
  final int? threadId;
  final int? postId;
  final int squad;
  final String dateStart;
  final String dateEnd;
  final bool hasLink;

  const ChatRoom({
    required this.id,
    required this.name,
    this.threadId,
    this.postId,
    required this.squad,
    required this.dateStart,
    required this.dateEnd,
    required this.hasLink,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    final link = json['link'];
    final hasLink = link != null &&
        (link is int
            ? link > 0
            : (int.tryParse(link.toString()) ?? 0) > 0);
    return ChatRoom(
      id: (json['troopid'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      threadId: _asInt(json['thread_id']),
      postId: _asInt(json['post_id']),
      squad: (json['squad'] as num?)?.toInt() ?? 0,
      dateStart: json['dateStart']?.toString() ?? '',
      dateEnd: json['dateEnd']?.toString() ?? '',
      hasLink: hasLink,
    );
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }
}
