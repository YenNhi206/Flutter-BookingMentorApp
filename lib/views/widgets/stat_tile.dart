import 'package:flutter/material.dart';

import '../../core/colors.dart';

/// 1 ô thông số trong hàng 3 ô (kcal / Ready in / Served) ở Detail Screen:
/// icon nhỏ → số to → label xám. Dùng chung với [StatRow] để tự chèn
/// divider dọc mảnh giữa các ô.
class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const StatTile({super.key, required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

/// Hàng chứa nhiều [StatTile], tự chèn divider dọc mảnh giữa mỗi ô.
class StatRow extends StatelessWidget {
  final List<StatTile> tiles;
  const StatRow({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) {
        children.add(Container(width: 1, height: 40, color: AppColors.divider));
      }
      children.add(Expanded(child: tiles[i]));
    }
    return Row(children: children);
  }
}
