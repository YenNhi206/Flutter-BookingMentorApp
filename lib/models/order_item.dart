/// Model 1 dòng món trong đơn hàng - tương ứng bảng `order_items`.
/// [priceAtOrder] chốt giá tại thời điểm đặt hàng, không đổi kể cả khi giá
/// gốc của món (`foods.price`) sau này thay đổi.
class OrderItem {
  final String id;
  final String orderId;
  final String foodId;
  final int quantity;
  final double priceAtOrder;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.foodId,
    required this.quantity,
    required this.priceAtOrder,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'order_id': orderId,
        'food_id': foodId,
        'quantity': quantity,
        'price_at_order': priceAtOrder,
      };

  factory OrderItem.fromMap(Map<String, Object?> map) => OrderItem(
        id: map['id'] as String,
        orderId: map['order_id'] as String,
        foodId: map['food_id'] as String,
        quantity: (map['quantity'] as int?) ?? 1,
        priceAtOrder: (map['price_at_order'] as num).toDouble(),
      );
}
