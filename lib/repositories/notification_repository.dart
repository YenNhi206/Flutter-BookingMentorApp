import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/app_notification.dart';
import '../services/database_service.dart';

/// Truy vấn/ghi bảng `notifications`.
class NotificationRepository {
  final DatabaseService _db;
  final _uuid = const Uuid();

  NotificationRepository({DatabaseService? databaseService}) : _db = databaseService ?? DatabaseService.instance;

  Future<List<AppNotification>> getForUser(String userId) async {
    final db = await _db.database;
    final rows = await db.query('notifications', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<void> create(AppNotification notification) async {
    final db = await _db.database;
    await db.insert('notifications', notification.toMap());
  }

  Future<void> markRead(String notificationId) async {
    final db = await _db.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markAllRead(String userId) async {
    final db = await _db.database;
    await db.update('notifications', {'is_read': 1}, where: 'user_id = ?', whereArgs: [userId]);
  }

  /// Sinh id ngẫu nhiên cho các repository khác cần tạo notification nhanh
  /// (vd sau khi checkout) mà không cần tự import package `uuid` riêng.
  String newId() => _uuid.v4();
}
