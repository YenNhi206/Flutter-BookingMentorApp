import '../../models/chat_message.dart';
import '../db/app_database.dart';

class ChatRepository {
  /// Deterministic conversation id for a student/mentor pair.
  static String conversationIdFor(String studentId, String mentorId) =>
      '${studentId}_$mentorId';

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'chat_messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(ChatMessage.fromMap).toList();
  }

  /// Latest message per conversation the given user participates in,
  /// used to render the conversation list screen.
  Future<List<ChatMessage>> getLatestPerConversation(String userId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT m.* FROM chat_messages m
      INNER JOIN (
        SELECT conversationId, MAX(createdAt) AS maxCreatedAt
        FROM chat_messages
        WHERE conversationId LIKE ? OR conversationId LIKE ?
        GROUP BY conversationId
      ) latest
      ON m.conversationId = latest.conversationId AND m.createdAt = latest.maxCreatedAt
      ORDER BY m.createdAt DESC
    ''', ['${userId}_%', '%_$userId']);
    return rows.map(ChatMessage.fromMap).toList();
  }

  Future<void> sendMessage(ChatMessage message) async {
    final db = await AppDatabase.instance.database;
    await db.insert('chat_messages', message.toMap());
  }
}
