class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead ? 1 : 0,
      };

  factory ChatMessage.fromMap(Map<String, Object?> map) => ChatMessage(
        id: map['id'] as String,
        conversationId: map['conversationId'] as String,
        senderId: map['senderId'] as String,
        senderName: map['senderName'] as String,
        text: map['text'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        isRead: (map['isRead'] as int) == 1,
      );
}
