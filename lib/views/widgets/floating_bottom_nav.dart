import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/theme.dart';
import 'nav_badge.dart';

/// Bottom navigation dạng "floating pill" tự vẽ thay cho
/// [BottomNavigationBar] mặc định: nền đen bo tròn hoàn toàn, icon trắng,
/// 5 tab xếp đều nhau (không có nút nào nổi to hơn), tab đang chọn nằm
/// trong vòng tròn trắng trượt mượt sang vị trí mới và icon phóng to nhẹ.
class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;
  final int chatUnreadCount;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
    this.chatUnreadCount = 0,
  });

  static const _icons = [
    Icons.home_rounded,
    Icons.favorite_rounded,
    Icons.shopping_bag_rounded,
    Icons.chat_bubble_rounded,
    Icons.person_rounded,
  ];

  static const _cartIndex = 2;
  static const _chatIndex = 3;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          boxShadow: AppTheme.softShadow,
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment(-1 + (2 * currentIndex) / (_icons.length - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / _icons.length,
                child: Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
            Row(
              children: List.generate(_icons.length, (i) {
                final active = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: SizedBox(
                      height: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedScale(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            scale: active ? 1.2 : 1,
                            child: Icon(_icons[i], color: active ? AppColors.primary : Colors.white, size: 24),
                          ),
                          if (i == _cartIndex && cartCount > 0)
                            Positioned(top: 10, right: 20, child: NavBadge(count: cartCount)),
                          if (i == _chatIndex && chatUnreadCount > 0)
                            Positioned(top: 10, right: 20, child: NavBadge(count: chatUnreadCount)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
