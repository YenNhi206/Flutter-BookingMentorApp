import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../models/order.dart';
import '../../models/voucher.dart';
import '../../repositories/order_repository.dart';
import '../../viewmodels/order_vm.dart';
import '../widgets/status_pill.dart';
import '../widgets/voucher_ticket.dart';
import 'main_shell.dart';

enum _Tab { summary, voucher }

/// "Your Order" - chi tiết 1 đơn hàng vừa đặt hoặc trong lịch sử, gồm 2 tab:
/// Summary (trạng thái + danh sách món + thanh toán) và Voucher (vé QR để
/// nhận hàng tại cửa hàng).
class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  _Tab _tab = _Tab.summary;
  bool _loading = true;
  Order? _order;
  List<OrderItemDetail> _items = [];
  Voucher? _voucher;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final orderVm = context.read<OrderViewModel>();
    final order = await orderVm.getOrderById(widget.orderId);
    final items = await orderVm.getOrderItems(widget.orderId);
    final voucher = await orderVm.getVoucher(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = order;
      _items = items;
      _voucher = voucher;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final order = _order!;

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
                  const Text('Your Order', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SegmentedTabs(tab: _tab, onChanged: (t) => setState(() => _tab = t)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _tab == _Tab.summary ? _buildSummaryTab(order) : _buildVoucherTab(order),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(Order order) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(22)),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: Color(0x1F34C759), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order confirmed', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    SizedBox(height: 2),
                    Text('Ready to redeem in store', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              StatusPill(status: order.status),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order ${order.orderCode}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(AppFormatters.shortDate(order.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 14),
              ..._items.map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.pastelForSeed(d.food.name.hashCode),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(d.food.emoji, style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.food.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                '${d.item.quantity} × ${AppFormatters.currency(d.item.priceAtOrder)}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          AppFormatters.currency(d.item.priceAtOrder * d.item.quantity),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              _row('Subtotal', AppFormatters.currency(order.subtotal)),
              if (order.discount > 0) _row('Discount', '-${AppFormatters.currency(order.discount)}'),
              _row('Total', AppFormatters.currency(order.total), bold: true),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.credit_card, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Paid with ${order.paymentMethod.label}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _tab = _Tab.voucher),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(22)),
            child: const Row(
              children: [
                Icon(Icons.confirmation_number_outlined, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text('View your voucher to redeem', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: bold ? AppColors.textPrimary : AppColors.textSecondary, fontSize: bold ? 15 : 13)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontSize: bold ? 16 : 13)),
        ],
      ),
    );
  }

  Widget _buildVoucherTab(Order order) {
    final voucher = _voucher;
    if (voucher == null) {
      return const Center(
        child: Text('No voucher found for this order', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: VoucherTicket(
        orderCode: order.orderCode,
        qrData: voucher.qrData,
        expiresAt: voucher.expiresAt,
        isRedeemed: voucher.isRedeemed,
      ),
    );
  }
}

/// Segmented control "Summary / Voucher" - pill đen trượt sang tab đang chọn.
class _SegmentedTabs extends StatelessWidget {
  final _Tab tab;
  final ValueChanged<_Tab> onChanged;

  const _SegmentedTabs({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isSummary = tab == _Tab.summary;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(999)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: isSummary ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(_Tab.summary),
                  child: Center(
                    child: Text(
                      'Summary',
                      style: TextStyle(
                        color: isSummary ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(_Tab.voucher),
                  child: Center(
                    child: Text(
                      'Voucher',
                      style: TextStyle(
                        color: !isSummary ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
