import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/theme.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/chat_vm.dart';
import '../../viewmodels/food_vm.dart';
import '../../viewmodels/order_vm.dart';

/// Tổng quan hoạt động của cửa hàng: số đơn hôm nay/tổng, món bán chạy
/// nhất, và số món đang bán - điểm hạ cánh đầu tiên khi chủ quán đăng nhập.
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final storeId = context.read<AuthViewModel>().currentUser?.storeId;
    if (storeId == null) return;
    await Future.wait([
      context.read<OrderViewModel>().loadStoreStats(storeId),
      context.read<FoodViewModel>().loadAll(),
      context.read<ChatViewModel>().loadStoreUnreadCount(storeId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<AuthViewModel>().currentUser?.storeId;
    final foodVm = context.watch<FoodViewModel>();
    final stats = context.watch<OrderViewModel>().storeStats;

    if (storeId == null) {
      return const Scaffold(body: Center(child: Text('Không tìm thấy cửa hàng của bạn')));
    }

    final store = foodVm.getStoreById(storeId);
    // Chỉ đếm món đang bán (isAvailable) để khớp với số món khách hàng thực
    // sự thấy/đặt được ở Home Screen, khác với tab Menu (owner thấy cả món
    // đang ẩn để quản lý).
    final availableMenuCount = foodVm.foodsForStore(storeId).where((f) => f.isAvailable).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Dashboard')),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                          child: const Icon(Icons.storefront_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store?.name ?? 'Cửa hàng',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                store?.address ?? '',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.today_outlined,
                          label: 'Đơn hôm nay',
                          value: '${stats.todayOrders}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.receipt_long_outlined,
                          label: 'Tổng số đơn',
                          value: '${stats.totalOrders}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_fire_department_outlined,
                          label: 'Món bán chạy nhất',
                          value: stats.bestSellerName ?? '—',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.restaurant_menu_outlined,
                          label: 'Món đang bán',
                          value: '$availableMenuCount',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
