import 'package:uuid/uuid.dart';

import '../models/message.dart';
import '../services/database_service.dart';

/// Truy vấn/ghi bảng `messages`. Việc mô phỏng độ trễ trả lời tự động nằm ở
/// [ChatViewModel] (business/UX logic), repository chỉ lo CRUD thuần.
class ChatRepository {
  final DatabaseService _db;
  final _uuid = const Uuid();

  ChatRepository({DatabaseService? databaseService}) : _db = databaseService ?? DatabaseService.instance;

  Future<List<Message>> getMessages(String userId, String storeId) async {
    final db = await _db.database;
    final rows = await db.query(
      'messages',
      where: 'user_id = ? AND store_id = ?',
      whereArgs: [userId, storeId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Message.fromMap).toList();
  }

  /// Trả về danh sách store_id đã từng có hội thoại với [userId], kèm tin
  /// nhắn cuối cùng - dùng cho màn danh sách hội thoại (Chat List) phía
  /// khách hàng.
  Future<List<Message>> getLastMessagePerStore(String userId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT messages.* FROM messages
      INNER JOIN (
        SELECT store_id, MAX(created_at) as max_created_at
        FROM messages WHERE user_id = ?
        GROUP BY store_id
      ) latest ON messages.store_id = latest.store_id AND messages.created_at = latest.max_created_at
      WHERE messages.user_id = ?
      ORDER BY messages.created_at DESC
    ''', [userId, userId]);
    return rows.map(Message.fromMap).toList();
  }

  /// Trả về tin nhắn cuối cùng của mỗi khách đã từng nhắn tới cửa hàng
  /// [storeId], kèm tin nhắn cuối cùng - dùng cho màn danh sách hội thoại
  /// phía chủ quán ([OwnerChatListScreen]).
  Future<List<Message>> getLastMessagePerCustomer(String storeId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT messages.* FROM messages
      INNER JOIN (
        SELECT user_id, MAX(created_at) as max_created_at
        FROM messages WHERE store_id = ?
        GROUP BY user_id
      ) latest ON messages.user_id = latest.user_id AND messages.created_at = latest.max_created_at
      WHERE messages.store_id = ?
      ORDER BY messages.created_at DESC
    ''', [storeId, storeId]);
    return rows.map(Message.fromMap).toList();
  }

  Future<Message> sendMessage({
    required String userId,
    required String storeId,
    required String content,
    required bool isFromUser,
  }) async {
    final db = await _db.database;
    final message = Message(
      id: _uuid.v4(),
      userId: userId,
      storeId: storeId,
      content: content,
      isFromUser: isFromUser,
      isRead: false,
      createdAt: DateTime.now(),
    );
    await db.insert('messages', message.toMap());
    return message;
  }

  /// Đếm số tin nhắn từ cửa hàng (không phải của user) mà [userId] chưa
  /// đọc, trên tất cả hội thoại - dùng cho badge tab Chat phía khách hàng.
  Future<int> getUnreadCount(String userId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE user_id = ? AND is_from_user = 0 AND is_read = 0',
      [userId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Đếm số tin nhắn từ khách (chưa đọc bởi chủ quán) trên toàn bộ hội thoại
  /// của cửa hàng [storeId] - dùng cho badge tab Chat phía chủ quán.
  Future<int> getUnreadCountForStore(String storeId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE store_id = ? AND is_from_user = 1 AND is_read = 0',
      [storeId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Đánh dấu đã đọc toàn bộ tin từ cửa hàng [storeId] trong hội thoại với
  /// [userId] - gọi khi user mở [ChatScreen] của hội thoại đó.
  Future<void> markConversationRead(String userId, String storeId) async {
    final db = await _db.database;
    await db.update(
      'messages',
      {'is_read': 1},
      where: 'user_id = ? AND store_id = ? AND is_from_user = 0',
      whereArgs: [userId, storeId],
    );
  }

  /// Đánh dấu đã đọc toàn bộ tin từ khách [userId] trong hội thoại với cửa
  /// hàng [storeId] - gọi khi chủ quán mở hội thoại đó.
  Future<void> markConversationReadByStore(String userId, String storeId) async {
    final db = await _db.database;
    await db.update(
      'messages',
      {'is_read': 1},
      where: 'user_id = ? AND store_id = ? AND is_from_user = 1',
      whereArgs: [userId, storeId],
    );
  }
}
