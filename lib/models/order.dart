/// Trạng thái vòng đời của 1 đơn hàng (mô hình nhận hàng tại cửa hàng qua
/// voucher, không phải giao hàng): thanh toán → đang chuẩn bị → sẵn sàng
/// lấy → đã hoàn tất, hoặc huỷ.
enum OrderStatus { paid, preparing, ready, completed, cancelled }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.paid => 'Paid',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.ready => 'Ready',
        OrderStatus.completed => 'Completed',
        OrderStatus.cancelled => 'Cancelled',
      };
}

OrderStatus orderStatusFromString(String value) {
  return OrderStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => OrderStatus.paid,
  );
}

/// Phương thức thanh toán ở bottom sheet Payment Method - chỉ mô phỏng UI,
/// không tích hợp cổng thanh toán thật.
enum PaymentMethod { applePay, card, paypal, cod }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.applePay => 'Apple Pay',
        PaymentMethod.card => 'Credit / Debit card',
        PaymentMethod.paypal => 'PayPal',
        PaymentMethod.cod => 'Cash on delivery',
      };
}

PaymentMethod paymentMethodFromString(String value) {
  return PaymentMethod.values.firstWhere(
    (m) => m.name == value,
    orElse: () => PaymentMethod.card,
  );
}

/// Model đơn hàng - tương ứng bảng `orders`. [orderCode] là mã ngắn dễ đọc
/// (vd `IC-1041`) hiển thị cho người dùng, khác với [id] (UUID nội bộ dùng
/// làm khoá chính/khoá ngoại).
class Order {
  final String id;
  final String orderCode;
  final String userId;
  final double subtotal;
  final double discount;
  final double total;
  final OrderStatus status;
  final PaymentMethod paymentMethod;

  /// 4 số cuối thẻ, chỉ có giá trị khi [paymentMethod] là [PaymentMethod.card].
  final String? cardLast4;

  final DateTime createdAt;

  const Order({
    required this.id,
    required this.orderCode,
    required this.userId,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.status,
    required this.paymentMethod,
    this.cardLast4,
    required this.createdAt,
  });

  Order copyWith({OrderStatus? status}) => Order(
        id: id,
        orderCode: orderCode,
        userId: userId,
        subtotal: subtotal,
        discount: discount,
        total: total,
        status: status ?? this.status,
        paymentMethod: paymentMethod,
        cardLast4: cardLast4,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'order_code': orderCode,
        'user_id': userId,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'status': status.name,
        'payment_method': paymentMethod.name,
        'card_last4': cardLast4,
        'created_at': createdAt.toIso8601String(),
      };

  factory Order.fromMap(Map<String, Object?> map) => Order(
        id: map['id'] as String,
        orderCode: map['order_code'] as String? ?? '',
        userId: map['user_id'] as String,
        subtotal: (map['subtotal'] as num).toDouble(),
        discount: (map['discount'] as num?)?.toDouble() ?? 0,
        total: (map['total'] as num).toDouble(),
        status: orderStatusFromString(map['status'] as String? ?? 'paid'),
        paymentMethod: paymentMethodFromString(map['payment_method'] as String? ?? 'card'),
        cardLast4: map['card_last4'] as String?,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
