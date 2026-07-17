import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/theme.dart';

/// Stepper "− N +" tái sử dụng ở Cart Screen (mỗi dòng món) và Detail
/// Screen (chọn số lượng trước khi thêm vào giỏ). [outlined] = true cho
/// biến thể pill trắng viền xám + shadow mềm (Detail Screen); false cho
/// biến thể nền `#F5F5F7` phẳng (Cart Screen).
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool outlined;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.white : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(999),
        border: outlined ? Border.all(color: AppColors.divider) : null,
        boxShadow: outlined ? AppTheme.softShadow : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove, onTap: onDecrement),
          SizedBox(
            width: 32,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          _StepButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}
