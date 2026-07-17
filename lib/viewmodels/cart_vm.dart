import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/food.dart';
import '../repositories/cart_repository.dart';

/// ViewModel giỏ hàng - đây là ViewModel có logic nghiệp vụ quan trọng nhất
/// của app (tính subtotal/total, áp mã giảm giá) nên được thiết kế để test
/// độc lập: mọi phép tính và thao tác thêm/sửa/xoá món chạy đồng bộ trên
/// danh sách [_items] trong bộ nhớ trước, rồi mới đồng bộ xuống SQLite ở nền
/// (fire-and-forget) - nhờ vậy unit test không cần khởi tạo database thật.
class CartViewModel extends ChangeNotifier {
  final CartRepository _repository;

  CartViewModel({CartRepository? repository}) : _repository = repository ?? CartRepository();

  String? userId;
  bool isLoading = false;

  final List<CartItemDetail> _items = [];
  List<CartItemDetail> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  /// Tổng số lượng món (cộng dồn quantity từng dòng) - dùng cho badge
  /// "X items" ở header Cart Screen, khác với `items.length` (số dòng).
  int get totalQuantity => _items.fold(0, (sum, c) => sum + c.item.quantity);

  String? appliedCode;
  double _discountPercent = 0;

  int _localIdSeq = 0;
  String _nextLocalId() => 'local_${_localIdSeq++}';

  double get subtotal => _items.fold(0.0, (sum, c) => sum + c.lineTotal);

  double get discount => double.parse((subtotal * _discountPercent).toStringAsFixed(2));

  /// Mô hình nhận hàng tại cửa hàng (không giao hàng) nên tổng tiền chỉ là
  /// subtotal trừ giảm giá, không cộng phí ship.
  double get total {
    final raw = subtotal - discount;
    return raw < 0 ? 0 : raw;
  }

  /// Tải giỏ hàng đã lưu của [forUserId] từ SQLite (gọi khi vào Cart Screen
  /// hoặc ngay sau khi đăng nhập).
  Future<void> load(String forUserId) async {
    userId = forUserId;
    isLoading = true;
    notifyListeners();
    _items
      ..clear()
      ..addAll(await _repository.getCartItemDetails(forUserId));
    isLoading = false;
    notifyListeners();
  }

  /// Thêm [food] vào giỏ. Nếu đã có dòng cùng food+size+note thì cộng dồn
  /// [quantity] thay vì tạo dòng mới.
  Future<void> addItem(
    Food food, {
    FoodSize size = FoodSize.small,
    String note = '',
    int quantity = 1,
  }) async {
    final idx = _items.indexWhere(
      (c) => c.food.id == food.id && c.item.size == size && c.item.note == note,
    );
    if (idx >= 0) {
      final updated = _items[idx].item.copyWith(quantity: _items[idx].item.quantity + quantity);
      _items[idx] = CartItemDetail(item: updated, food: food);
    } else {
      final newItem = CartItem(
        id: _nextLocalId(),
        userId: userId ?? '',
        foodId: food.id,
        quantity: quantity,
        size: size,
        note: note,
      );
      _items.add(CartItemDetail(item: newItem, food: food));
    }
    notifyListeners();

    if (userId != null) {
      await _repository.addToCart(userId: userId!, foodId: food.id, size: size, note: note, quantity: quantity);
      // Nạp lại từ DB để id trong bộ nhớ khớp với id thật (UUID) do
      // repository sinh ra - đảm bảo các thao tác tăng/giảm/xoá sau đó
      // (dựa trên cartItemId) tác động đúng dòng trong SQLite.
      await load(userId!);
    }
  }

  void incrementQuantity(String cartItemId) => _changeQuantity(cartItemId, 1);

  void decrementQuantity(String cartItemId) => _changeQuantity(cartItemId, -1);

  void _changeQuantity(String cartItemId, int delta) {
    final idx = _items.indexWhere((c) => c.item.id == cartItemId);
    if (idx < 0) return;
    final newQuantity = _items[idx].item.quantity + delta;
    if (newQuantity <= 0) {
      removeItem(cartItemId);
      return;
    }
    _items[idx] = CartItemDetail(item: _items[idx].item.copyWith(quantity: newQuantity), food: _items[idx].food);
    notifyListeners();
    if (userId != null && !cartItemId.startsWith('local_')) {
      unawaited(_repository.updateQuantity(cartItemId, newQuantity));
    }
  }

  void removeItem(String cartItemId) {
    _items.removeWhere((c) => c.item.id == cartItemId);
    notifyListeners();
    if (userId != null && !cartItemId.startsWith('local_')) {
      unawaited(_repository.removeItem(cartItemId));
    }
  }

  /// Áp mã giảm giá. Chỉ hỗ trợ 1 mã demo `SCOOPS10` (giảm 10% subtotal) -
  /// đủ để minh hoạ luồng nghiệp vụ mà không cần thêm bảng `coupons` riêng.
  /// Trả về true nếu mã hợp lệ.
  bool applyDiscountCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized == 'SCOOPS10') {
      _discountPercent = 0.10;
      appliedCode = normalized;
      notifyListeners();
      return true;
    }
    _discountPercent = 0;
    appliedCode = null;
    notifyListeners();
    return false;
  }

  void clearDiscount() {
    _discountPercent = 0;
    appliedCode = null;
    notifyListeners();
  }

  /// Xoá sạch giỏ hàng - gọi sau khi checkout thành công.
  Future<void> clear() async {
    _items.clear();
    _discountPercent = 0;
    appliedCode = null;
    notifyListeners();
    if (userId != null) {
      await _repository.clearCart(userId!);
    }
  }
}
