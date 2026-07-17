import '../models/category.dart';
import '../models/food.dart';
import '../models/store.dart';
import '../services/database_service.dart';

/// Truy vấn dữ liệu món ăn / danh mục / cửa hàng - tầng Repository chỉ chịu
/// trách nhiệm đọc/ghi SQLite, không chứa logic nghiệp vụ (logic lọc/tìm
/// kiếm nằm ở [FoodViewModel]).
class FoodRepository {
  final DatabaseService _db;

  FoodRepository({DatabaseService? databaseService}) : _db = databaseService ?? DatabaseService.instance;

  Future<List<Food>> getAllFoods() async {
    final db = await _db.database;
    final rows = await db.query('foods', orderBy: 'name ASC');
    return rows.map(Food.fromMap).toList();
  }

  Future<Food?> getFoodById(String id) async {
    final db = await _db.database;
    final rows = await db.query('foods', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Food.fromMap(rows.first);
  }

  Future<List<Food>> getRecommended({int limit = 6}) async {
    final db = await _db.database;
    final rows = await db.query('foods', orderBy: 'rating DESC', limit: limit);
    return rows.map(Food.fromMap).toList();
  }

  Future<List<FoodCategory>> getAllCategories() async {
    final db = await _db.database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map(FoodCategory.fromMap).toList();
  }

  Future<List<Store>> getAllStores() async {
    final db = await _db.database;
    final rows = await db.query('stores', orderBy: 'name ASC');
    return rows.map(Store.fromMap).toList();
  }

  Future<Store?> getStoreById(String id) async {
    final db = await _db.database;
    final rows = await db.query('stores', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Store.fromMap(rows.first);
  }

  Future<List<Food>> getFoodsByStore(String storeId) async {
    final db = await _db.database;
    final rows = await db.query('foods', where: 'store_id = ?', whereArgs: [storeId], orderBy: 'name ASC');
    return rows.map(Food.fromMap).toList();
  }

  Future<void> insertFood(Food food) async {
    final db = await _db.database;
    await db.insert('foods', food.toMap());
  }

  Future<void> updateFood(Food food) async {
    final db = await _db.database;
    await db.update('foods', food.toMap(), where: 'id = ?', whereArgs: [food.id]);
  }

  /// Xoá món kèm dọn dẹp mọi tham chiếu tới nó ở `cart_items`/`favourites` -
  /// nếu không, món biến mất khỏi giỏ hàng/yêu thích của khách một cách âm
  /// thầm (INNER JOIN chỉ lặng lẽ bỏ qua dòng mồ côi) mà không có gì báo cho
  /// khách biết món họ đã thêm không còn tồn tại nữa.
  Future<void> deleteFood(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('cart_items', where: 'food_id = ?', whereArgs: [id]);
      await txn.delete('favourites', where: 'food_id = ?', whereArgs: [id]);
      await txn.delete('foods', where: 'id = ?', whereArgs: [id]);
    });
  }
}
