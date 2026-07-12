import 'package:flutter/foundation.dart';

import '../data/repositories/notification_repository.dart';
import '../models/notification_item.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationProvider({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  List<NotificationItem> _items = [];
  bool _isLoading = false;

  List<NotificationItem> get items => _items;
  bool get isLoading => _isLoading;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> loadForUser(String userId) async {
    _isLoading = true;
    notifyListeners();
    _items = await _repository.getForUser(userId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markRead(String id, String userId) async {
    await _repository.markRead(id);
    await loadForUser(userId);
  }

  Future<void> markAllRead(String userId) async {
    await _repository.markAllRead(userId);
    await loadForUser(userId);
  }
}
