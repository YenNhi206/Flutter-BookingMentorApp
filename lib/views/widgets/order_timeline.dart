import 'package:flutter/material.dart';

import '../../core/colors.dart';

/// Timeline dọc 4 bước ở Processing Screen. [completedSteps] = số bước đã
/// hoàn tất (0-4): các bước có index < [completedSteps] hiển thị "đã xong"
/// (chấm đặc hồng + ✓ trắng), bước có index == [completedSteps] hiển thị
/// "đang chạy" (viền hồng + chấm hồng giữa), các bước sau hiển thị "chưa
/// tới" (viền xám rỗng). Đường nối dọc: đoạn đã qua màu hồng, chưa tới màu
/// xám `#EEEEEE`.
class OrderTimeline extends StatelessWidget {
  static const steps = [
    'Payment received',
    'Order created',
    'Kitchen is preparing your ice cream',
    'Adding the final touches',
  ];

  final int completedSteps;

  const OrderTimeline({super.key, required this.completedSteps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final isDone = i < completedSteps;
        final isCurrent = i == completedSteps;
        final isLast = i == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _StepDot(isDone: isDone, isCurrent: isCurrent),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: isDone ? AppColors.statusAccent : AppColors.divider,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28, top: 2),
                  child: Text(
                    steps[i],
                    style: TextStyle(
                      color: (isDone || isCurrent) ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: (isDone || isCurrent) ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool isDone;
  final bool isCurrent;
  const _StepDot({required this.isDone, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(color: AppColors.statusAccent, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      );
    }
    if (isCurrent) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.statusAccent, width: 2),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: AppColors.statusAccent, shape: BoxShape.circle),
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.divider, width: 2)),
    );
  }
}
