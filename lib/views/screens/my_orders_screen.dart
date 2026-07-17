import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/order_vm.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_pill.dart';
import 'order_detail_screen.dart';

/// "My Orders" - lịch sử toàn bộ đơn hàng của user, mỗi card có ảnh món
/// chồng nhau (overlapping thumbnails) + status pill màu theo trạng thái.
/// Vào được từ Profile → "My Orders".
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  Future<void> _load() async {
    final userId = context.read<AuthViewModel>().currentUser?.id;
    if (userId != null) {
      await context.read<OrderViewModel>().loadOrders(userId);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final orderVm = context.watch<OrderViewModel>();

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
                  const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                ],
              ),
            ),
            Expanded(
              child: orderVm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : orderVm.orders.isEmpty
                      ? const EmptyState(
                          emoji: '📦',
                          title: 'No orders yet',
                          subtitle: 'Your past orders will show up here.',
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            itemCount: orderVm.orders.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) => _OrderCard(order: orderVm.orders[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  late final Future<List<OrderItemDetail>> _itemsFuture =
      context.read<OrderViewModel>().getOrderItems(widget.order.id);

  Order get order => widget.order;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(22)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ${order.orderCode}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(AppFormatters.shortDate(order.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                StatusPill(status: order.status),
              ],
            ),
            const Divider(height: 24),
            FutureBuilder<List<OrderItemDetail>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                final items = snapshot.data ?? const [];
                final totalQuantity = items.fold<int>(0, (sum, i) => sum + i.item.quantity);
                return Row(
                  children: [
                    SizedBox(
                      width: 24 + (items.length.clamp(0, 3)) * 18,
                      height: 36,
                      child: Stack(
                        children: [
                          for (var i = 0; i < items.length.clamp(0, 3); i++)
                            Positioned(
                              left: i * 18.0,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.pastelForSeed(items[i].food.name.hashCode),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.surfaceCard, width: 2),
                                ),
                                alignment: Alignment.center,
                                child: Text(items[i].food.emoji, style: const TextStyle(fontSize: 16)),
                              ),
                            ),
                          if (items.length > 3)
                            Positioned(
                              left: 3 * 18.0,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.surfaceCard, width: 2),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '+${items.length - 3}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text('$totalQuantity items', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(width: 12),
                    Text(AppFormatters.currency(order.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
