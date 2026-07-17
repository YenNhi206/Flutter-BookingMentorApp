import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/order.dart';

/// Pill hiển thị trạng thái đơn hàng - luôn dùng tông màu riêng theo status
/// (không phải màu hành động đen), theo đúng nguyên tắc màu của app:
/// đen = hành động, hồng đỏ/màu trạng thái = trạng thái đơn hàng.
class StatusPill extends StatelessWidget {
  final OrderStatus status;
  const StatusPill({super.key, required this.status});

  (Color, Color) get _colors => switch (status) {
        OrderStatus.paid => (AppColors.statusAccent, const Color(0x1FFF4D6D)),
        OrderStatus.preparing => (const Color(0xFFFF9F1C), const Color(0x1FFF9F1C)),
        OrderStatus.ready => (AppColors.statusAccent, const Color(0x1FFF4D6D)),
        OrderStatus.completed => (AppColors.success, const Color(0x1F34C759)),
        OrderStatus.cancelled => (AppColors.textSecondary, AppColors.surfaceCard),
      };

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status.label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
