import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../models/order.dart';
import 'primary_button.dart';

/// Bottom sheet chọn phương thức thanh toán, mở từ nút "Checkout" ở Cart
/// Screen. Chỉ mô phỏng UI, không tích hợp cổng thanh toán thật. Trả về
/// `(PaymentMethod, cardLast4)` qua [Navigator.pop] khi bấm "Pay" - màn gọi
/// tự quyết định điều hướng tiếp (không tự chuyển màn ở đây để tách bạch
/// trách nhiệm UI chọn phương thức khỏi luồng điều hướng checkout).
class PaymentSheet extends StatefulWidget {
  final double total;
  const PaymentSheet({super.key, required this.total});

  static Future<(PaymentMethod, String?)?> show(BuildContext context, {required double total}) {
    return showModalBottomSheet<(PaymentMethod, String?)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => PaymentSheet(total: total),
    );
  }

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  PaymentMethod _method = PaymentMethod.card;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Payment method', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 4),
              const Text(
                "Choose how you'd like to pay",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _MethodCard(
                icon: Icons.apple,
                title: PaymentMethod.applePay.label,
                description: 'Fast & secure checkout',
                selected: _method == PaymentMethod.applePay,
                onTap: () => setState(() => _method = PaymentMethod.applePay),
              ),
              const SizedBox(height: 10),
              _MethodCard(
                icon: Icons.credit_card,
                title: PaymentMethod.card.label,
                description: '•••• •••• •••• 4242',
                selected: _method == PaymentMethod.card,
                onTap: () => setState(() => _method = PaymentMethod.card),
              ),
              const SizedBox(height: 10),
              _MethodCard(
                icon: Icons.account_balance_wallet_outlined,
                title: PaymentMethod.paypal.label,
                description: 'Linked account',
                selected: _method == PaymentMethod.paypal,
                onTap: () => setState(() => _method = PaymentMethod.paypal),
              ),
              const SizedBox(height: 10),
              _MethodCard(
                icon: Icons.payments_outlined,
                title: PaymentMethod.cod.label,
                description: 'Pay when it arrives',
                selected: _method == PaymentMethod.cod,
                onTap: () => setState(() => _method = PaymentMethod.cod),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  Text(
                    AppFormatters.currency(widget.total),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Pay ${AppFormatters.currency(widget.total)}',
                trailingIcon: null,
                onPressed: () => Navigator.of(context).pop(
                  (_method, _method == PaymentMethod.card ? '4242' : null),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            _RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.divider, width: 1.6)),
    );
  }
}
