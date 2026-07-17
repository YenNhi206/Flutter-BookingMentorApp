import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/cart_item.dart';
import '../models/food.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/voucher.dart';
import '../services/database_service.dart';

/// Ghép [OrderItem] với [Food] tương ứng để hiển thị lịch sử đơn hàng mà
/// không mất tên/ảnh món dù giá gốc sau này có thay đổi (giá hiển thị vẫn
/// lấy từ `price_at_order`, chỉ tên/ảnh lấy từ bảng `foods` hiện tại).
class OrderItemDetail {
  final OrderItem item;
  final Food food;

  const OrderItemDetail({required this.item, required this.food});
}

/// Số liệu thống kê của 1 cửa hàng, tổng hợp từ `order_items`/`orders` -
/// dùng cho Dashboard của chủ quán ([OwnerDashboardScreen]).
class StoreStats {
  final int todayOrders;
  final int totalOrders;
  final String? bestSellerName;

  const StoreStats({
    required this.todayOrders,
    required this.totalOrders,
    this.bestSellerName,
  });
}

/// Quản lý đơn hàng + voucher nhận hàng: tạo đơn (transaction), tra cứu
/// lịch sử, cập nhật trạng thái. Đây là repository quan trọng nhất vì thao
/// tác checkout phải đảm bảo tính toàn vẹn dữ liệu (atomicity).
class OrderRepository {
  final DatabaseService _db;
  final _uuid = const Uuid();

  OrderRepository({DatabaseService? databaseService}) : _db = databaseService ?? DatabaseService.instance;

  /// Tạo đơn hàng + voucher từ giỏ hàng hiện tại trong 1 transaction: tạo
  /// `orders` → tạo từng `order_items` → tạo `vouchers` → xoá `cart_items` →
  /// tạo `notifications`. Nếu bất kỳ bước nào lỗi, toàn bộ transaction
  /// rollback - giỏ hàng và dữ liệu đơn hàng không bao giờ ở trạng thái
  /// nửa vời. Gọi từ [ProcessingScreen] (không phải lúc bấm "Pay"), đúng
  /// như luồng: xác nhận thanh toán trước, ghi DB trong lúc hiển thị
  /// timeline chuẩn bị đơn.
  Future<Order> checkout({
    required String userId,
    required List<CartItemDetail> cartItems,
    required double discount,
    required PaymentMethod paymentMethod,
    String? cardLast4,
  }) async {
    if (cartItems.isEmpty) {
      throw StateError('Không thể đặt hàng với giỏ hàng trống.');
    }

    final db = await _db.database;
    final subtotal = cartItems.fold<double>(0, (sum, c) => sum + c.lineTotal);
    final total = (subtotal - discount).clamp(0, double.infinity).toDouble();
    final orderId = _uuid.v4();
    final now = DateTime.now();

    late Order order;
    await db.transaction((txn) async {
      // Dựa trên số thứ tự lớn nhất từng cấp phát (không phải COUNT(*)) để
      // mã đơn không bao giờ trùng lại nếu sau này có tính năng xoá đơn -
      // COUNT(*) sẽ giảm ngay khi 1 đơn bị xoá, dễ sinh ra mã đã dùng trước đó.
      final maxResult = await txn.rawQuery(
        "SELECT MAX(CAST(SUBSTR(order_code, 4) AS INTEGER)) as max_seq FROM orders",
      );
      final maxSeq = (maxResult.first['max_seq'] as int?) ?? 1040;
      final orderCode = 'IC-${maxSeq + 1}';

      order = Order(
        id: orderId,
        orderCode: orderCode,
        userId: userId,
        subtotal: subtotal,
        discount: discount,
        total: total,
        status: OrderStatus.paid,
        paymentMethod: paymentMethod,
        cardLast4: paymentMethod == PaymentMethod.card ? cardLast4 : null,
        createdAt: now,
      );
      await txn.insert('orders', order.toMap());

      for (final c in cartItems) {
        final orderItem = OrderItem(
          id: _uuid.v4(),
          orderId: order.id,
          foodId: c.food.id,
          quantity: c.item.quantity,
          priceAtOrder: c.unitPrice,
        );
        await txn.insert('order_items', orderItem.toMap());
      }

      final voucher = Voucher(
        id: _uuid.v4(),
        orderId: order.id,
        code: orderCode,
        qrData: 'SCOOPS-VOUCHER:${order.id}:$orderCode',
        expiresAt: now.add(const Duration(days: 7)),
      );
      await txn.insert('vouchers', voucher.toMap());

      await txn.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]);

      await txn.insert('notifications', {
        'id': _uuid.v4(),
        'user_id': userId,
        'title': 'Order confirmed 🎉',
        'body': 'Order $orderCode is ready to redeem in store.',
        'is_read': 0,
        'created_at': now.toIso8601String(),
      });
    });

    return order;
  }

  Future<List<Order>> getOrdersForUser(String userId) async {
    final db = await _db.database;
    final rows = await db.query('orders', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
    return rows.map(Order.fromMap).toList();
  }

  Future<Order?> getOrderById(String orderId) async {
    final db = await _db.database;
    final rows = await db.query('orders', where: 'id = ?', whereArgs: [orderId]);
    if (rows.isEmpty) return null;
    return Order.fromMap(rows.first);
  }

  /// [storeId] khi truyền vào sẽ chỉ trả về các dòng món thuộc cửa hàng đó -
  /// dùng cho chủ quán xem đơn ([OwnerOrdersScreen]) vì 1 đơn có thể gộp món
  /// từ nhiều cửa hàng, không được lộ phần của cửa hàng khác.
  Future<List<OrderItemDetail>> getOrderItemDetails(String orderId, {String? storeId}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT order_items.*,
             foods.id as f_id, foods.store_id as f_store_id, foods.category_id as f_category_id,
             foods.name as f_name, foods.description as f_description, foods.price as f_price,
             foods.image as f_image, foods.emoji as f_emoji, foods.rating as f_rating,
             foods.is_available as f_is_available, foods.kcal as f_kcal,
             foods.ready_minutes as f_ready_minutes, foods.serve_temp as f_serve_temp,
             foods.flavour_tags as f_flavour_tags
      FROM order_items
      INNER JOIN foods ON foods.id = order_items.food_id
      WHERE order_items.order_id = ? ${storeId != null ? 'AND foods.store_id = ?' : ''}
    ''', [orderId, ?storeId]);

    return rows.map((row) {
      final item = OrderItem.fromMap(row);
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
        'kcal': row['f_kcal'],
        'ready_minutes': row['f_ready_minutes'],
        'serve_temp': row['f_serve_temp'],
        'flavour_tags': row['f_flavour_tags'],
      });
      return OrderItemDetail(item: item, food: food);
    }).toList();
  }

  /// Đơn hàng có chứa ít nhất 1 món của [storeId] - dùng cho màn quản lý đơn
  /// của chủ quán. 1 đơn có thể gộp món nhiều cửa hàng nên phải JOIN qua
  /// `order_items`/`foods` thay vì lọc trực tiếp trên `orders`.
  Future<List<Order>> getOrdersForStore(String storeId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT orders.* FROM orders
      INNER JOIN order_items ON order_items.order_id = orders.id
      INNER JOIN foods ON foods.id = order_items.food_id
      WHERE foods.store_id = ?
      ORDER BY orders.created_at DESC
    ''', [storeId]);
    return rows.map(Order.fromMap).toList();
  }

  /// Số đơn hôm nay và tổng, cùng món bán chạy nhất - chỉ tính phần đóng
  /// góp của [storeId] (qua `order_items`/`foods`), không tính gộp cả đơn
  /// nếu đơn đó có lẫn món của cửa hàng khác.
  Future<StoreStats> getStoreStats(String storeId) async {
    final db = await _db.database;

    final totalRow = await db.rawQuery('''
      SELECT COUNT(DISTINCT order_items.order_id) as orders
      FROM order_items
      INNER JOIN foods ON foods.id = order_items.food_id
      WHERE foods.store_id = ?
    ''', [storeId]);

    final todayRow = await db.rawQuery('''
      SELECT COUNT(DISTINCT order_items.order_id) as orders
      FROM order_items
      INNER JOIN foods ON foods.id = order_items.food_id
      INNER JOIN orders ON orders.id = order_items.order_id
      WHERE foods.store_id = ? AND date(orders.created_at) = date('now', 'localtime')
    ''', [storeId]);

    final bestSellerRow = await db.rawQuery('''
      SELECT foods.name as name, SUM(order_items.quantity) as qty
      FROM order_items
      INNER JOIN foods ON foods.id = order_items.food_id
      WHERE foods.store_id = ?
      GROUP BY foods.id
      ORDER BY qty DESC
      LIMIT 1
    ''', [storeId]);

    return StoreStats(
      todayOrders: (todayRow.first['orders'] as int?) ?? 0,
      totalOrders: (totalRow.first['orders'] as int?) ?? 0,
      bestSellerName: bestSellerRow.isEmpty ? null : bestSellerRow.first['name'] as String?,
    );
  }

  /// Cập nhật trạng thái đơn (chủ quán thao tác). Khi chuyển sang
  /// [OrderStatus.completed] - nghĩa là khách đã đến quầy nhận hàng - tự
  /// động đánh dấu voucher của đơn là đã redeem luôn, vì đây là mô hình
  /// nhận hàng tại quầy: chủ quán xác nhận giao hàng chính là hành động
  /// redeem, khách không tự đánh dấu voucher của mình được nữa.
  Future<void> updateStatus(String orderId, OrderStatus status) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update(
        'orders',
        {'status': status.name},
        where: 'id = ?',
        whereArgs: [orderId],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (status == OrderStatus.completed) {
        await txn.update(
          'vouchers',
          {'is_redeemed': 1},
          where: 'order_id = ?',
          whereArgs: [orderId],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<Voucher?> getVoucherForOrder(String orderId) async {
    final db = await _db.database;
    final rows = await db.query('vouchers', where: 'order_id = ?', whereArgs: [orderId]);
    if (rows.isEmpty) return null;
    return Voucher.fromMap(rows.first);
  }
}
