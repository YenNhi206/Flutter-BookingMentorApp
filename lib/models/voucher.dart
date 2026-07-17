/// Model voucher nhận hàng tại cửa hàng - tương ứng bảng `vouchers`. Mỗi
/// đơn hàng có đúng 1 voucher (quan hệ 1-1 qua [orderId]), chứa mã QR để
/// nhân viên cửa hàng quét khi khách tới lấy hàng.
class Voucher {
  final String id;
  final String orderId;
  final String code;
  final String qrData;
  final DateTime expiresAt;
  final bool isRedeemed;

  const Voucher({
    required this.id,
    required this.orderId,
    required this.code,
    required this.qrData,
    required this.expiresAt,
    this.isRedeemed = false,
  });

  Voucher copyWith({bool? isRedeemed}) => Voucher(
        id: id,
        orderId: orderId,
        code: code,
        qrData: qrData,
        expiresAt: expiresAt,
        isRedeemed: isRedeemed ?? this.isRedeemed,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'order_id': orderId,
        'code': code,
        'qr_data': qrData,
        'expires_at': expiresAt.toIso8601String(),
        'is_redeemed': isRedeemed ? 1 : 0,
      };

  factory Voucher.fromMap(Map<String, Object?> map) => Voucher(
        id: map['id'] as String,
        orderId: map['order_id'] as String,
        code: map['code'] as String,
        qrData: map['qr_data'] as String,
        expiresAt: DateTime.tryParse(map['expires_at'] as String? ?? '') ?? DateTime.now(),
        isRedeemed: ((map['is_redeemed'] as int?) ?? 0) == 1,
      );
}
