import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

/// ViewModel danh sách thông báo trong app.
class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationViewModel({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  List<AppNotification> notifications = [];
  bool isLoading = false;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<void> load(String userId) async {
    isLoading = true;
    notifyListeners();
    notifications = await _repository.getForUser(userId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> markRead(String notificationId) async {
    await _repository.markRead(notificationId);
    notifications = notifications
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
    notifyListeners();
  }

  Future<void> markAllRead(String userId) async {
    await _repository.markAllRead(userId);
    notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }
}
