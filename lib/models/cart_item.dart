import 'food.dart';

/// Model 1 dòng trong giỏ hàng - tương ứng bảng `cart_items`.
class CartItem {
  final String id;
  final String userId;
  final String foodId;
  final int quantity;
  final FoodSize size;
  final String note;

  const CartItem({
    required this.id,
    required this.userId,
    required this.foodId,
    this.quantity = 1,
    this.size = FoodSize.medium,
    this.note = '',
  });

  CartItem copyWith({int? quantity, FoodSize? size, String? note}) => CartItem(
        id: id,
        userId: userId,
        foodId: foodId,
        quantity: quantity ?? this.quantity,
        size: size ?? this.size,
        note: note ?? this.note,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'food_id': foodId,
        'quantity': quantity,
        'size': size.name,
        'note': note,
      };

  factory CartItem.fromMap(Map<String, Object?> map) => CartItem(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        foodId: map['food_id'] as String,
        quantity: (map['quantity'] as int?) ?? 1,
        size: FoodSize.values.firstWhere(
          (s) => s.name == map['size'],
          orElse: () => FoodSize.medium,
        ),
        note: map['note'] as String? ?? '',
      );
}

/// Kết hợp [CartItem] với thông tin [Food] tương ứng để hiển thị trên UI mà
/// không cần join lại nhiều lần - đây là kiểu dữ liệu dẫn xuất (derived),
/// không phải bảng riêng trong DB.
class CartItemDetail {
  final CartItem item;
  final Food food;

  const CartItemDetail({required this.item, required this.food});

  double get unitPrice => food.price + item.size.surcharge;

  double get lineTotal => unitPrice * item.quantity;
}
