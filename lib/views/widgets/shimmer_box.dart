import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/colors.dart';

/// Placeholder loading dạng shimmer - dùng khi đang tải danh sách món ăn ở
/// Home Screen để tránh màn hình trắng đột ngột.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceCard,
      highlightColor: Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: borderRadius),
      ),
    );
  }
}

/// Grid shimmer mô phỏng đúng layout của lưới món ăn ở Home Screen trong
/// lúc chờ dữ liệu tải xong.
class FoodGridShimmer extends StatelessWidget {
  const FoodGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) => const ShimmerBox(borderRadius: BorderRadius.all(Radius.circular(28))),
    );
  }
}
