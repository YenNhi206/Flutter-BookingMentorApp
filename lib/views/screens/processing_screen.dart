import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../models/order.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/cart_vm.dart';
import '../../viewmodels/order_vm.dart';
import '../widgets/app_toast.dart';
import '../widgets/order_timeline.dart';
import 'order_detail_screen.dart';

/// Màn "Preparing your order" - chạy timeline 4 bước tự động, mỗi bước
/// ~1.2s. Đây mới là lúc dữ liệu đơn hàng thực sự được ghi vào SQLite
/// (transaction tạo orders + order_items + voucher, xoá cart_items, tạo
/// notification) - không ghi ở lúc bấm "Pay" trên [PaymentSheet]. Chặn nút
/// back để người dùng không thoát giữa chừng lúc đơn đang được xử lý.
class ProcessingScreen extends StatefulWidget {
  final PaymentMethod paymentMethod;
  final String? cardLast4;

  const ProcessingScreen({super.key, required this.paymentMethod, this.cardLast4});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> with SingleTickerProviderStateMixin {
  static const _stepDuration = Duration(milliseconds: 1200);

  /// Số bước đã hoàn tất (0-4). Bắt đầu ở 1: bước 0 "Payment received" coi
  /// như xong ngay khi vào màn này (đã thanh toán ở PaymentSheet), bước 1
  /// "Order created" đang chạy.
  int _completedSteps = 1;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSteps());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runSteps() async {
    await Future.delayed(_stepDuration);
    if (!mounted) return;
    setState(() => _completedSteps = 2); // "Order created" xong, "Kitchen is preparing" đang chạy

    // ── Ghi DB thật ở đây (không phải lúc bấm Pay) ──────────────
    final auth = context.read<AuthViewModel>();
    final cart = context.read<CartViewModel>();
    final orderVm = context.read<OrderViewModel>();
    final order = await orderVm.checkout(
      userId: auth.currentUser!.id,
      cartItems: cart.items,
      discount: cart.discount,
      paymentMethod: widget.paymentMethod,
      cardLast4: widget.cardLast4,
    );
    if (order != null) {
      await cart.clear();
    }

    await Future.delayed(_stepDuration);
    if (!mounted) return;
    setState(() => _completedSteps = 3); // "Kitchen is preparing" xong, "Adding final touches" đang chạy

    await Future.delayed(_stepDuration);
    if (!mounted) return;
    setState(() => _completedSteps = 4); // xong hết 4 bước

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (order == null) {
      Navigator.of(context).pop();
      AppToast.show(context, message: orderVm.errorMessage ?? 'Something went wrong placing your order.');
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 0.97 + _pulseController.value * 0.06;
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: const Icon(Icons.icecream_outlined, size: 96, color: Color(0xFFEAEAEA)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Preparing your order',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hang tight, this only takes a moment',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 40),
                OrderTimeline(completedSteps: _completedSteps),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
