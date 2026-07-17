import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/voucher.dart';
import '../repositories/order_repository.dart';

/// ViewModel đơn hàng: đặt hàng (checkout), tra cứu lịch sử đơn, và voucher
/// nhận hàng tại cửa hàng gắn với mỗi đơn.
class OrderViewModel extends ChangeNotifier {
  final OrderRepository _repository;

  OrderViewModel({OrderRepository? repository}) : _repository = repository ?? OrderRepository();

  List<Order> orders = [];
  bool isLoading = false;
  String? errorMessage;

  /// Đơn hàng chứa món của cửa hàng chủ quán đang quản lý - dùng cho
  /// [OwnerOrdersScreen], tách riêng khỏi [orders] (lịch sử mua hàng của
  /// chính user đó với vai trò khách).
  List<Order> storeOrders = [];
  bool isLoadingStoreOrders = false;
  StoreStats? storeStats;

  Future<void> loadOrders(String userId) async {
    isLoading = true;
    notifyListeners();
    orders = await _repository.getOrdersForUser(userId);
    isLoading = false;
    notifyListeners();
  }

  Future<Order?> getOrderById(String orderId) => _repository.getOrderById(orderId);

  Future<List<OrderItemDetail>> getOrderItems(String orderId) => _repository.getOrderItemDetails(orderId);

  Future<Voucher?> getVoucher(String orderId) => _repository.getVoucherForOrder(orderId);

  Future<void> loadOrdersForStore(String storeId) async {
    isLoadingStoreOrders = true;
    notifyListeners();
    storeOrders = await _repository.getOrdersForStore(storeId);
    isLoadingStoreOrders = false;
    notifyListeners();
  }

  Future<List<OrderItemDetail>> getOrderItemsForStore(String orderId, String storeId) =>
      _repository.getOrderItemDetails(orderId, storeId: storeId);

  Future<void> loadStoreStats(String storeId) async {
    storeStats = await _repository.getStoreStats(storeId);
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status, String storeId) async {
    await _repository.updateStatus(orderId, status);
    await loadOrdersForStore(storeId);
  }

  /// Đặt hàng từ giỏ hàng hiện tại. Gọi từ [ProcessingScreen] (không phải
  /// lúc bấm "Pay" ở [PaymentSheet]) - đúng luồng: xác nhận thanh toán
  /// trước, ghi DB trong lúc hiển thị timeline chuẩn bị đơn. Trả về [Order]
  /// vừa tạo nếu thành công, null nếu có lỗi (xem [errorMessage]).
  Future<Order?> checkout({
    required String userId,
    required List<CartItemDetail> cartItems,
    required double discount,
    required PaymentMethod paymentMethod,
    String? cardLast4,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final order = await _repository.checkout(
        userId: userId,
        cartItems: cartItems,
        discount: discount,
        paymentMethod: paymentMethod,
        cardLast4: cardLast4,
      );
      orders = [order, ...orders];
      return order;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
