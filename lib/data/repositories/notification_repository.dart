import 'package:sqflite/sqflite.dart';

import '../../models/notification_item.dart';
import '../db/app_database.dart';

class NotificationRepository {
  Future<List<NotificationItem>> getForUser(String userId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(NotificationItem.fromMap).toList();
  }

  Future<int> unreadCount(String userId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE userId = ? AND isRead = 0',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> create(NotificationItem item) async {
    final db = await AppDatabase.instance.database;
    await db.insert('notifications', item.toMap());
  }

  Future<void> markRead(String id) async {
    final db = await AppDatabase.instance.database;
    await db.update('notifications', {'isRead': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAllRead(String userId) async {
    final db = await AppDatabase.instance.database;
    await db.update('notifications', {'isRead': 1}, where: 'userId = ?', whereArgs: [userId]);
  }
}
