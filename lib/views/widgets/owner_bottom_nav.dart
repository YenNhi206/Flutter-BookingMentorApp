import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/theme.dart';
import 'nav_badge.dart';

/// Bottom nav dạng "floating pill" cho [OwnerShell] - 5 tab (Dashboard/Đơn
/// hàng/Chat/Menu/Hồ sơ), cùng phong cách với [FloatingBottomNav] bên khách
/// hàng (nền đen bo tròn, icon trắng, tab đang chọn nằm trong vòng tròn
/// trắng trượt mượt) nhưng không có nút giữa nổi lên vì owner không có
/// hành động "quan trọng nhất" duy nhất như giỏ hàng của khách.
class OwnerBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int chatUnreadCount;

  const OwnerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.chatUnreadCount = 0,
  });

  static const _icons = [
    Icons.dashboard_rounded,
    Icons.receipt_long_rounded,
    Icons.chat_bubble_rounded,
    Icons.storefront_rounded,
    Icons.person_rounded,
  ];

  static const _chatIndex = 2;

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
