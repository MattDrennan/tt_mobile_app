class PushNotification {
  final String id;
  final String title;
  final String body;
  final String url;
  final DateTime? readAt;
  final DateTime createdAt;

  const PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.url,
    required this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  factory PushNotification.fromJson(Map<String, dynamic> json) {
    return PushNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      url: json['url'] as String,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
