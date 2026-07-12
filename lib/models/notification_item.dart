enum NotificationType { booking, chat, system }

NotificationType notificationTypeFromString(String value) {
  return NotificationType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => NotificationType.system,
  );
}

class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String relatedId;
  final DateTime createdAt;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId = '',
    required this.createdAt,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'relatedId': relatedId,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead ? 1 : 0,
      };

  factory NotificationItem.fromMap(Map<String, Object?> map) => NotificationItem(
        id: map['id'] as String,
        userId: map['userId'] as String,
        title: map['title'] as String,
        body: map['body'] as String,
        type: notificationTypeFromString(map['type'] as String),
        relatedId: (map['relatedId'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
        isRead: (map['isRead'] as int) == 1,
      );
}
