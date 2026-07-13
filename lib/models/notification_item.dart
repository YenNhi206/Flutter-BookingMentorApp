enum NotificationType { booking, chat, system }

NotificationType notificationTypeFromString(String value) {
  return NotificationType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => NotificationType.system,
  );
}

/// Backend notification `type` values are more granular than this app's
/// three-way split (e.g. `booking_confirmed`, `payment_success`) - anything
/// starting with `booking`/`payment`/`course` maps to [NotificationType.booking],
/// defensive fallback to [NotificationType.system].
NotificationType notificationTypeFromBackend(String? value) {
  if (value == null) return NotificationType.system;
  if (value == 'chat') return NotificationType.chat;
  if (value.startsWith('booking') || value.startsWith('payment') || value.startsWith('course')) {
    return NotificationType.booking;
  }
  return NotificationType.system;
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

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>? ?? const {};
    final relatedId = metadata['bookingId'] ?? metadata['mentorId'] ?? metadata['courseId'];
    return NotificationItem(
      id: (json['id'] ?? json['_id']).toString(),
      userId: (json['userId'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: notificationTypeFromBackend(json['type'] as String?),
      relatedId: relatedId?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
