/// Model thông báo trong app - tương ứng bảng `notifications`.
/// Đặt tên `AppNotification` (không phải `Notification`) để tránh trùng với
/// class `Notification` sẵn có trong Flutter framework.
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        userId: userId,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'is_read': isRead ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory AppNotification.fromMap(Map<String, Object?> map) => AppNotification(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        title: map['title'] as String,
        body: map['body'] as String? ?? '',
        isRead: ((map['is_read'] as int?) ?? 0) == 1,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
