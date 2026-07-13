import '../../core/api_client.dart';
import '../../models/notification_item.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Backed by `/notifications` (JWT-scoped, last 50) - [userId] is
  /// vestigial, kept only for call-site signature compatibility.
  Future<List<NotificationItem>> getForUser(String userId) async {
    final result = await _apiClient.get('/notifications') as Map<String, dynamic>;
    final items = result['notifications'] as List<dynamic>;
    return items.map((n) => NotificationItem.fromJson(n as Map<String, dynamic>)).toList();
  }

  Future<int> unreadCount(String userId) async {
    final result = await _apiClient.get('/notifications/unread-count') as Map<String, dynamic>;
    return (result['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String id) async {
    await _apiClient.patch('/notifications/$id/read');
  }

  Future<void> markAllRead(String userId) async {
    await _apiClient.post('/notifications/read-all');
  }
}
