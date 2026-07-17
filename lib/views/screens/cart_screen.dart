import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/cart_item.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/cart_vm.dart';
import '../../viewmodels/main_tab_vm.dart';
import '../widgets/app_toast.dart';
import '../widgets/empty_state.dart';
import '../widgets/payment_sheet.dart';
import '../widgets/primary_button.dart';
import '../widgets/quantity_stepper.dart';
import 'processing_screen.dart';

/// Giỏ hàng: danh sách món (swipe để xoá, có Undo), ô mở dialog nhập mã
/// giảm giá, tóm tắt subtotal/total, nút Checkout mở [PaymentSheet].
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _openPromoDialog(BuildContext context) async {
    final cart = context.read<CartViewModel>();
    final controller = TextEditingController(text: cart.appliedCode ?? '');
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Promo code'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'e.g. SCOOPS10'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (code == null || !context.mounted) return;
    final applied = cart.applyDiscountCode(code);
    if (!context.mounted) return;
    AppToast.show(context, message: applied ? 'Promo code applied! 🎉' : 'Invalid promo code');
  }

  Future<void> _startCheckout(BuildContext context) async {
    final auth = context.read<AuthViewModel>();
    final cart = context.read<CartViewModel>();
    if (auth.currentUser == null) {
      AppToast.show(context, message: 'Please log in to checkout.');
      return;
    }

    final result = await PaymentSheet.show(context, total: cart.total);
    if (result == null || !context.mounted) return;
    final (method, cardLast4) = result;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(paymentMethod: method, cardLast4: cardLast4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: AppColors.surfaceCard, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('My Cart', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 22)),
                  const Spacer(),
                  if (!cart.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration:
                          BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        '${cart.totalQuantity} items',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: cart.isEmpty
                  ? EmptyState(
                      emoji: '🍨',
                      title: 'Your cart is empty',
                      subtitle: 'Looks like you haven\'t added any sweets yet.',
                      actionLabel: 'Browse sweets',
                      onAction: () {
                        context.read<MainTabViewModel>().setIndex(0);
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _CartItemTile(detail: cart.items[index]),
                    ),
            ),
            if (!cart.isEmpty) _buildSummary(context, cart),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, CartViewModel cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusCard)),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.08), blurRadius: 28, offset: const Offset(0, -10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => _openPromoDialog(context),
            child: Row(
              children: [
                const Icon(Icons.local_offer_outlined, size: 20, color: AppColors.textPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cart.appliedCode == null
                        ? 'Do you have any promo code?'
                        : 'Promo applied: ${cart.appliedCode}',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow('Subtotal', AppFormatters.currency(cart.subtotal)),
          if (cart.discount > 0) _summaryRow('Discount', '-${AppFormatters.currency(cart.discount)}'),
          const Divider(height: 24),
          _summaryRow('Total', AppFormatters.currency(cart.total), bold: true),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Checkout', trailingIcon: null, onPressed: () => _startCheckout(context)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: bold ? AppColors.textPrimary : AppColors.textSecondary, fontSize: bold ? 16 : 13)),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontSize: bold ? 18 : 13),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItemDetail detail;
  const _CartItemTile({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(detail.item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        final cart = context.read<CartViewModel>();
        final removedFood = detail.food;
        final removedSize = detail.item.size;
        final removedQuantity = detail.item.quantity;
        final removedNote = detail.item.note;
        cart.removeItem(detail.item.id);
        AppToast.show(
          context,
          message: '${removedFood.name} removed',
          actionLabel: 'Undo',
          onAction: () => cart.addItem(removedFood, size: removedSize, note: removedNote, quantity: removedQuantity),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(22)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.pastelForSeed(detail.food.name.hashCode),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(detail.food.emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(detail.food.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.currency(detail.unitPrice),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            QuantityStepper(
              quantity: detail.item.quantity,
              onIncrement: () => context.read<CartViewModel>().incrementQuantity(detail.item.id),
              onDecrement: () => context.read<CartViewModel>().decrementQuantity(detail.item.id),
            ),
          ],
        ),
      ),
    );
  }
}
