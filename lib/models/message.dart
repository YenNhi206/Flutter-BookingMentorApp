/// Model tin nhắn chat giữa khách hàng và cửa hàng - tương ứng bảng
/// `messages`. [isRead] chỉ có ý nghĩa với tin từ cửa hàng
/// (`isFromUser == false`) - dùng để tính badge số tin chưa đọc trên tab
/// Chat của [FloatingBottomNav].
class Message {
  final String id;
  final String userId;
  final String storeId;
  final String content;
  final bool isFromUser;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.content,
    required this.isFromUser,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'store_id': storeId,
        'content': content,
        'is_from_user': isFromUser ? 1 : 0,
        'is_read': isRead ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory Message.fromMap(Map<String, Object?> map) => Message(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        storeId: map['store_id'] as String,
        content: map['content'] as String,
        isFromUser: ((map['is_from_user'] as int?) ?? 1) == 1,
        isRead: ((map['is_read'] as int?) ?? 0) == 1,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
