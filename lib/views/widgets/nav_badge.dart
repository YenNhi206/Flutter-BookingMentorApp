import 'package:flutter/material.dart';

/// Chấm số đỏ nhỏ đè lên icon bottom nav (tin nhắn/món chưa đọc) - dùng
/// chung cho cả [FloatingBottomNav] (khách hàng) và [OwnerBottomNav] (chủ
/// quán) để 2 phong cách nav luôn nhất quán.
class NavBadge extends StatelessWidget {
  final int count;
  const NavBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16),
      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(999)),
      child: Text(
        count > 9 ? '9+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
