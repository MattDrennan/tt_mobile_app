/// Result of the `user_status` and `is_closed` API calls.
class SiteStatus {
  final bool canAccess;
  final bool isBanned;
  final bool isClosed;
  final String? message;

  const SiteStatus({
    required this.canAccess,
    required this.isBanned,
    this.isClosed = false,
    this.message,
  });

  factory SiteStatus.fromUserStatusJson(Map<String, dynamic> json) {
    bool asBool(dynamic v) =>
        v == true || v == 1 || v == '1' || v == 'true';
    final isBanned = asBool(json['isBanned']);
    final canAccess = asBool(json['canAccess']);
    final msg = (json['message'] as String?) ??
        (json['error'] as String?) ??
        (isBanned
            ? 'Your forum account is banned.'
            : 'You do not have access at this time.');
    return SiteStatus(
      canAccess: canAccess,
      isBanned: isBanned,
      message: msg,
    );
  }

  factory SiteStatus.fromClosedJson(Map<String, dynamic> json) {
    final closed = json['isWebsiteClosed'] == 1 || json['isWebsiteClosed'] == true;
    return SiteStatus(
      canAccess: !closed,
      isBanned: false,
      isClosed: closed,
      message: json['siteMessage'] as String?,
    );
  }
}
