import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/order_vm.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chip.dart';
import '../widgets/status_pill.dart';

/// Bước kế tiếp trong vòng đời đơn hàng mà chủ quán có thể chủ động đẩy tới -
/// null nghĩa là đơn đã ở trạng thái cuối (completed/cancelled).
OrderStatus? _nextStatus(OrderStatus status) => switch (status) {
      OrderStatus.paid => OrderStatus.preparing,
      OrderStatus.preparing => OrderStatus.ready,
      OrderStatus.ready => OrderStatus.completed,
      OrderStatus.completed => null,
      OrderStatus.cancelled => null,
    };

String _nextActionLabel(OrderStatus status) => switch (status) {
      OrderStatus.paid => 'Bắt đầu chuẩn bị',
      OrderStatus.preparing => 'Đã sẵn sàng lấy',
      OrderStatus.ready => 'Hoàn tất đơn',
      _ => '',
    };

/// Màn quản lý đơn hàng của chủ quán: xem đơn có chứa món của cửa hàng mình,
/// lọc theo trạng thái, và cập nhật trạng thái từng đơn (paid → preparing →
/// ready → completed, hoặc huỷ).
class OwnerOrdersScreen extends StatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen> {
  OrderStatus? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final storeId = context.read<AuthViewModel>().currentUser?.storeId;
    if (storeId == null) return;
    await context.read<OrderViewModel>().loadOrdersForStore(storeId);
  }

  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<AuthViewModel>().currentUser?.storeId;
    final orderVm = context.watch<OrderViewModel>();

    if (storeId == null) {
      return const Scaffold(body: Center(child: Text('Không tìm thấy cửa hàng của bạn')));
    }

    final orders = _filter == null
        ? orderVm.storeOrders
        : orderVm.storeOrders.where((o) => o.status == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Đơn hàng')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppFilterChip(label: 'Tất cả', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                ),
                for (final status in OrderStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppFilterChip(
                      label: status.label,
                      selected: _filter == status,
                      onTap: () => setState(() => _filter = status),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: orderVm.isLoadingStoreOrders
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                    ? const EmptyState(
                        emoji: '🧾',
                        title: 'Chưa có đơn nào',
                        subtitle: 'Đơn hàng của khách sẽ hiện ở đây khi có người đặt món từ quán bạn.',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          itemCount: orders.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _OrderCard(order: orders[index], storeId: storeId),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;
  final String storeId;

  const _OrderCard({required this.order, required this.storeId});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;
  bool _updating = false;

  Future<void> _advance() async {
    final next = _nextStatus(widget.order.status);
    if (next == null) return;
    setState(() => _updating = true);
    await context.read<OrderViewModel>().updateOrderStatus(widget.order.id, next, widget.storeId);
    if (mounted) setState(() => _updating = false);
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Huỷ đơn này?'),
        content: Text('Đơn ${widget.order.orderCode} sẽ được đánh dấu là đã huỷ.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Không')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Huỷ đơn', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _updating = true);
    await context.read<OrderViewModel>().updateOrderStatus(widget.order.id, OrderStatus.cancelled, widget.storeId);
    if (mounted) setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final next = _nextStatus(order.status);
    final canCancel = order.status != OrderStatus.completed && order.status != OrderStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderCode, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(AppFormatters.dateTime(order.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              StatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Text(
                  _expanded ? 'Ẩn chi tiết' : 'Xem chi tiết món',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
          if (_expanded) _OrderItemsList(orderId: order.id, storeId: widget.storeId),
          if (_updating) ...[
            const SizedBox(height: 12),
            const Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))),
          ] else if (next != null || canCancel) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (canCancel)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancel,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Huỷ đơn'),
                    ),
                  ),
                if (canCancel && next != null) const SizedBox(width: 12),
                if (next != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _advance,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                      child: Text(_nextActionLabel(order.status)),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderItemsList extends StatefulWidget {
  final String orderId;
  final String storeId;

  const _OrderItemsList({required this.orderId, required this.storeId});

  @override
  State<_OrderItemsList> createState() => _OrderItemsListState();
}

class _OrderItemsListState extends State<_OrderItemsList> {
  late final Future<List<OrderItemDetail>> _itemsFuture =
      context.read<OrderViewModel>().getOrderItemsForStore(widget.orderId, widget.storeId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderItemDetail>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final items = snapshot.data!;
        final subtotal = items.fold<double>(0, (sum, d) => sum + d.item.priceAtOrder * d.item.quantity);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 20),
              ...items.map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(d.food.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(d.food.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                        Text(
                          '${d.item.quantity} × ${AppFormatters.currency(d.item.priceAtOrder)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Phần của quán bạn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(AppFormatters.currency(subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
