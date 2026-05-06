import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/push_notification.dart';
import '../services/notification_api_service.dart';

class NotificationsController extends ChangeNotifier {
  List<PushNotification> _notifications = [];
  bool _isLoading = false;

  List<PushNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => n.isUnread).length;

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    _notifications = await NotificationApiService.fetchAll();
    _isLoading = false;
    _syncBadge();
    notifyListeners();
  }

  Future<void> markRead(PushNotification notification) async {
    if (!notification.isUnread) return;
    await NotificationApiService.markRead(notification.id);
    _notifications = _notifications.map((n) {
      return n.id == notification.id
          ? PushNotification(
              id: n.id,
              title: n.title,
              body: n.body,
              url: n.url,
              readAt: DateTime.now(),
              createdAt: n.createdAt,
            )
          : n;
    }).toList();
    _syncBadge();
    notifyListeners();
  }

  Future<void> clearAll() async {
    await NotificationApiService.clearAll();
    _notifications = [];
    _syncBadge();
    notifyListeners();
  }

  void _syncBadge() {
    AppBadgePlus.updateBadge(unreadCount);
  }
}
