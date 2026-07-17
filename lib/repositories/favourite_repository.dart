import 'package:uuid/uuid.dart';

import '../services/database_service.dart';

/// Quản lý danh sách món yêu thích (bảng `favourites`, chỉ là bảng nối
/// user_id–food_id nên không cần model riêng).
class FavouriteRepository {
  final DatabaseService _db;
  final _uuid = const Uuid();

  FavouriteRepository({DatabaseService? databaseService}) : _db = databaseService ?? DatabaseService.instance;

  Future<Set<String>> getFavouriteFoodIds(String userId) async {
    final db = await _db.database;
    final rows = await db.query('favourites', columns: ['food_id'], where: 'user_id = ?', whereArgs: [userId]);
    return rows.map((r) => r['food_id'] as String).toSet();
  }

  /// Bật/tắt yêu thích cho 1 món, trả về trạng thái mới (true = đã yêu thích).
  Future<bool> toggle(String userId, String foodId) async {
    final db = await _db.database;
    final existing = await db.query(
      'favourites',
      where: 'user_id = ? AND food_id = ?',
      whereArgs: [userId, foodId],
    );
    if (existing.isNotEmpty) {
      await db.delete('favourites', where: 'user_id = ? AND food_id = ?', whereArgs: [userId, foodId]);
      return false;
    }
    await db.insert('favourites', {'id': _uuid.v4(), 'user_id': userId, 'food_id': foodId});
    return true;
  }
}
