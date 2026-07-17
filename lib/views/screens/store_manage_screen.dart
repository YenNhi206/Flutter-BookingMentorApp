import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../models/food.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/food_vm.dart';
import '../widgets/empty_state.dart';
import 'food_form_screen.dart';

/// Tab "Menu" trong [OwnerShell]: xem/thêm/sửa/xoá món, bật-tắt trạng thái
/// mở bán của cửa hàng gắn với tài khoản [AppUser.isOwner] đang đăng nhập -
/// không cần kiểm tra quyền lại ở đây vì đây là app local-only, không có API
/// công khai.
class StoreManageScreen extends StatefulWidget {
  const StoreManageScreen({super.key});

  @override
  State<StoreManageScreen> createState() => _StoreManageScreenState();
}

class _StoreManageScreenState extends State<StoreManageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<FoodViewModel>().loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<AuthViewModel>().currentUser?.storeId;
    final foodVm = context.watch<FoodViewModel>();

    if (storeId == null) {
      return const Scaffold(body: Center(child: Text('Không tìm thấy cửa hàng của bạn')));
    }

    final store = foodVm.getStoreById(storeId);
    final foods = foodVm.foodsForStore(storeId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(store?.name ?? 'Quản lý quán')),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 88),
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => FoodFormScreen(storeId: storeId)),
          ),
          child: const Icon(Icons.add),
        ),
      ),
      body: foodVm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : foods.isEmpty
          ? const EmptyState(
              emoji: '🍽️',
              title: 'Chưa có món nào',
              subtitle: 'Nhấn nút + để thêm món đầu tiên cho cửa hàng của bạn.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: foods.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _FoodManageTile(food: foods[index], storeId: storeId),
            ),
    );
  }
}

class _FoodManageTile extends StatelessWidget {
  final Food food;
  final String storeId;

  const _FoodManageTile({required this.food, required this.storeId});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá món này?'),
        content: Text('"${food.name}" sẽ bị xoá vĩnh viễn khỏi menu.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoá', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<FoodViewModel>().deleteFood(food.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Text(food.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(AppFormatters.currency(food.price), style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: food.isAvailable,
            onChanged: (_) => context.read<FoodViewModel>().toggleAvailability(food),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => FoodFormScreen(storeId: storeId, food: food)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }
}
