import 'package:uuid/uuid.dart';

import '../models/cart_item.dart';
import '../models/food.dart';
import '../services/database_service.dart';

/// Truy vấn/ghi giỏ hàng (bảng `cart_items`), kèm hàm join với `foods` để
/// trả về dữ liệu đủ hiển thị trên UI mà không cần query riêng từng món.
class CartRepository {
  final DatabaseService _db;
  final _uuid = const Uuid();

  CartRepository({DatabaseService? databaseService}) : _db = databaseService ?? DatabaseService.instance;

  Future<List<CartItem>> getCartItems(String userId) async {
    final db = await _db.database;
    final rows = await db.query('cart_items', where: 'user_id = ?', whereArgs: [userId]);
    return rows.map(CartItem.fromMap).toList();
  }

  /// Lấy giỏ hàng đã join sẵn với thông tin món (`foods`) để hiển thị UI.
  Future<List<CartItemDetail>> getCartItemDetails(String userId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT cart_items.*,
             foods.id as f_id, foods.store_id as f_store_id, foods.category_id as f_category_id,
             foods.name as f_name, foods.description as f_description, foods.price as f_price,
             foods.image as f_image, foods.emoji as f_emoji, foods.rating as f_rating,
             foods.is_available as f_is_available
      FROM cart_items
      INNER JOIN foods ON foods.id = cart_items.food_id
      WHERE cart_items.user_id = ?
    ''', [userId]);

    return rows.map((row) {
      final item = CartItem.fromMap(row);
      final food = Food.fromMap({
        'id': row['f_id'],
        'store_id': row['f_store_id'],
        'category_id': row['f_category_id'],
        'name': row['f_name'],
        'description': row['f_description'],
        'price': row['f_price'],
        'image': row['f_image'],
        'emoji': row['f_emoji'],
        'rating': row['f_rating'],
        'is_available': row['f_is_available'],
      });
      return CartItemDetail(item: item, food: food);
    }).toList();
  }

  /// Thêm món vào giỏ - nếu đã có dòng cùng food+size+note thì cộng dồn số
  /// lượng thay vì tạo dòng mới, tránh trùng lặp hiển thị trên UI.
  Future<void> addToCart({
    required String userId,
    required String foodId,
    required FoodSize size,
    String note = '',
    int quantity = 1,
  }) async {
    final db = await _db.database;
    final existing = await db.query(
      'cart_items',
      where: 'user_id = ? AND food_id = ? AND size = ? AND note = ?',
      whereArgs: [userId, foodId, size.name, note],
    );
    if (existing.isNotEmpty) {
      final current = CartItem.fromMap(existing.first);
      await db.update(
        'cart_items',
        {'quantity': current.quantity + quantity},
        where: 'id = ?',
        whereArgs: [current.id],
      );
      return;
    }
    final item = CartItem(id: _uuid.v4(), userId: userId, foodId: foodId, quantity: quantity, size: size, note: note);
    await db.insert('cart_items', item.toMap());
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    final db = await _db.database;
    if (quantity <= 0) {
      await db.delete('cart_items', where: 'id = ?', whereArgs: [cartItemId]);
      return;
    }
    await db.update('cart_items', {'quantity': quantity}, where: 'id = ?', whereArgs: [cartItemId]);
  }

  Future<void> removeItem(String cartItemId) async {
    final db = await _db.database;
    await db.delete('cart_items', where: 'id = ?', whereArgs: [cartItemId]);
  }

  Future<void> clearCart(String userId) async {
    final db = await _db.database;
    await db.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]);
  }
}
