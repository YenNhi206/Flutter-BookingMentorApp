import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';

/// Card dạng vé xé (ticket) hiển thị mã QR để đổi hàng tại cửa hàng: có 2
/// khuyết tròn ở giữa 2 cạnh trái/phải và 1 đường kẻ răng cưa ngang giữa,
/// y hệt hình dáng vé xem phim/vé số thật. Chỉ chủ quán mới đánh dấu được
/// voucher đã redeem (qua hành động "Hoàn tất đơn") - khách chỉ xem, không
/// tự redeem được, tránh trường hợp tự đánh dấu đã nhận hàng mà không cần
/// ra quán.
class VoucherTicket extends StatelessWidget {
  final String orderCode;
  final String qrData;
  final DateTime expiresAt;
  final bool isRedeemed;

  const VoucherTicket({
    super.key,
    required this.orderCode,
    required this.qrData,
    required this.expiresAt,
    required this.isRedeemed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TicketNotchClipper(),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _DashedLinePainter())),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 160,
                          gapless: false,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(orderCode, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
                      const SizedBox(height: 4),
                      const Text(
                        'Show this QR code at the counter',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24), // chừa chỗ cho khuyết tròn 2 bên
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Expires', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Text(AppFormatters.dateTime(expiresAt), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (isRedeemed)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0x1F34C759),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '✓ Redeemed',
                            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Waiting to be redeemed at the counter',
                            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Cắt 2 khuyết bán nguyệt ở giữa cạnh trái/phải để tạo dáng vé xé.
class _TicketNotchClipper extends CustomClipper<Path> {
  static const double notchRadius = 14;

  @override
  Path getClip(Size size) {
    final midY = size.height / 2;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, midY - notchRadius)
      ..arcToPoint(Offset(size.width, midY + notchRadius), radius: const Radius.circular(notchRadius))
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, midY + notchRadius)
      ..arcToPoint(Offset(0, midY - notchRadius), radius: const Radius.circular(notchRadius))
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Vẽ đường kẻ răng cưa (dashed line) ngang giữa vé, đúng vị trí khuyết
/// tròn 2 bên.
class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final paint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1.5;
    const dashWidth = 6.0;
    const dashSpace = 5.0;
    var x = _TicketNotchClipper.notchRadius + 12;
    final endX = size.width - _TicketNotchClipper.notchRadius - 12;
    while (x < endX) {
      canvas.drawLine(Offset(x, midY), Offset(x + dashWidth, midY), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
