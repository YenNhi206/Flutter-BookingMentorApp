import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/food.dart';

/// Card món ăn dùng ở Home Screen (grid 2 cột) và section "We Recommend".
/// Ảnh 3D nếu [Food.image] có giá trị, ngược lại fallback sang [Food.emoji]
/// cỡ lớn trên nền pastel - chỉ cần seed `image` là tự chuyển sang ảnh thật.
class FoodCard extends StatelessWidget {
  final Food food;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavourite;
  final VoidCallback onAdd;
  final Color pastelColor;

  /// Tag Hero riêng cho lần hiển thị này - bắt buộc truyền từ nơi gọi (thay
  /// vì tự sinh từ `food.id`) vì cùng 1 món có thể xuất hiện đồng thời ở cả
  /// lưới chính và mục "We Recommend"; Flutter sẽ crash nếu 2 Hero hiển thị
  /// cùng lúc mà trùng tag.
  final String heroTag;

  const FoodCard({
    super.key,
    required this.food,
    required this.isFavourite,
    required this.onTap,
    required this.onToggleFavourite,
    required this.onAdd,
    required this.pastelColor,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: AppTheme.softShadow,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: heroTag,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                        alignment: Alignment.center,
                        child: RepaintBoundary(
                          child: food.image.isEmpty
                              ? FittedBox(
                                  fit: BoxFit.contain,
                                  child: Text(food.emoji, style: const TextStyle(fontSize: 200)),
                                )
                              : Image.asset(food.image, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onToggleFavourite,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          isFavourite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFavourite ? Colors.redAccent : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              food.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppFormatters.currency(food.price),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                _AddButton(onTap: onAdd),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút "+" tròn đen thêm nhanh vào giỏ - tự phát animation scale khi bấm.
class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    lowerBound: 0.85,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.reverse();
    await _controller.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _controller,
        child: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.add, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
