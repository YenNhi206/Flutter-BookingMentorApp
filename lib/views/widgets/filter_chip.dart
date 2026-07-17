import 'package:flutter/material.dart';

import '../../core/colors.dart';

/// Chip filter danh mục ở Home Screen. Chip đang chọn: nền đen chữ trắng,
/// có icon "×" để bỏ chọn; chip chưa chọn: nền trắng viền xám nhạt.
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(999),
          border: selected ? null : Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.onPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.close, size: 14, color: AppColors.onPrimary),
            ],
          ],
        ),
      ),
    );
  }
}
