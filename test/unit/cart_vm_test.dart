import 'package:flutter_test/flutter_test.dart';
import 'package:scoops/models/food.dart';
import 'package:scoops/viewmodels/cart_vm.dart';

/// Test độc lập với database: [CartViewModel] không có `userId` (chế độ
/// khách) nên mọi thao tác chạy hoàn toàn trong bộ nhớ, không cần mock
/// SQLite - đúng như thiết kế "fake class thủ công" trong yêu cầu đề bài.
Food _food(String id, double price) => Food(
      id: id,
      storeId: 'store_1',
      categoryId: 'cat_1',
      name: 'Food $id',
      description: 'Test food',
      price: price,
    );

void main() {
  group('CartViewModel', () {
    late CartViewModel cart;

    setUp(() {
      cart = CartViewModel();
    });

    test('thêm món mới vào giỏ hàng trống', () async {
      await cart.addItem(_food('f1', 5.0));

      expect(cart.items.length, 1);
      expect(cart.items.first.food.id, 'f1');
      expect(cart.items.first.item.quantity, 1);
    });

    test('thêm cùng món (cùng size/note) sẽ cộng dồn số lượng, không tạo dòng mới', () async {
      final food = _food('f1', 5.0);
      await cart.addItem(food, quantity: 1);
      await cart.addItem(food, quantity: 2);

      expect(cart.items.length, 1);
      expect(cart.items.first.item.quantity, 3);
    });

    test('thêm cùng món nhưng khác size sẽ tạo 2 dòng riêng biệt', () async {
      final food = _food('f1', 5.0);
      await cart.addItem(food, size: FoodSize.small);
      await cart.addItem(food, size: FoodSize.large);

      expect(cart.items.length, 2);
    });

    test('tăng số lượng cộng đúng 1 mỗi lần gọi', () async {
      await cart.addItem(_food('f1', 5.0));
      final id = cart.items.first.item.id;

      cart.incrementQuantity(id);
      cart.incrementQuantity(id);

      expect(cart.items.first.item.quantity, 3);
    });

    test('giảm số lượng về 0 thì tự động xoá dòng khỏi giỏ', () async {
      await cart.addItem(_food('f1', 5.0), quantity: 1);
      final id = cart.items.first.item.id;

      cart.decrementQuantity(id);

      expect(cart.items, isEmpty);
    });

    test('xoá món khỏi giỏ hàng', () async {
      await cart.addItem(_food('f1', 5.0));
      final id = cart.items.first.item.id;

      cart.removeItem(id);

      expect(cart.items, isEmpty);
    });

    test('tính subtotal đúng theo giá + phụ phí size, nhân số lượng', () async {
      // (5.00 + 1.00 phụ phí size Large) * 2 = 12.00
      await cart.addItem(_food('f1', 5.0), size: FoodSize.large, quantity: 2);
      // (3.00 + 0 phụ phí size Small) * 1 = 3.00
      await cart.addItem(_food('f2', 3.0), size: FoodSize.small, quantity: 1);

      expect(cart.subtotal, closeTo(15.0, 0.001));
    });

    test('không giao hàng (nhận tại cửa hàng) nên total bằng subtotal khi chưa có giảm giá', () async {
      await cart.addItem(_food('f1', 5.0), size: FoodSize.small);
      expect(cart.total, closeTo(cart.subtotal, 0.001));
    });

    test('áp mã giảm giá hợp lệ SCOOPS10 giảm đúng 10% subtotal', () async {
      // Dùng size Small (không phụ phí) để subtotal = đúng giá gốc 10.0.
      await cart.addItem(_food('f1', 10.0), size: FoodSize.small);

      final applied = cart.applyDiscountCode('scoops10');

      expect(applied, isTrue);
      expect(cart.appliedCode, 'SCOOPS10');
      expect(cart.discount, closeTo(1.0, 0.001));
      expect(cart.total, closeTo(cart.subtotal - 1.0, 0.001));
    });

    test('áp mã giảm giá không hợp lệ thì không giảm giá gì cả', () async {
      await cart.addItem(_food('f1', 10.0));

      final applied = cart.applyDiscountCode('INVALID_CODE');

      expect(applied, isFalse);
      expect(cart.discount, 0);
      expect(cart.appliedCode, isNull);
    });

    test('total không bao giờ âm dù discount lớn hơn subtotal', () async {
      await cart.addItem(_food('f1', 1.0));
      cart.applyDiscountCode('SCOOPS10');

      expect(cart.total, greaterThanOrEqualTo(0));
    });
  });
}
