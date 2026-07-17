import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/food_vm.dart';
import 'auth_screen.dart';
import 'map_screen.dart';

/// Tab "Hồ sơ" trong [OwnerShell]: thông tin tài khoản + cửa hàng, đối
/// xứng với [ProfileScreen] phía khách hàng - và là nơi duy nhất có nút
/// đăng xuất (giống bên khách, không lặp lại logout ở mọi tab).
class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<FoodViewModel>().loadAll());
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthViewModel>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final store = user?.storeId == null ? null : context.watch<FoodViewModel>().getStoreById(user!.storeId!);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.surfaceCard,
                child: Icon(Icons.person, size: 32, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (store != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(22)),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.storefront_outlined),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(store.address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 2),
                      Text(store.rating.toStringAsFixed(1)),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          _menuItem(context, Icons.location_on_outlined, 'Vị trí cửa hàng',
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MapScreen()))),
          _menuItem(context, Icons.settings_outlined, 'Cài đặt', () {}),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _menuItem(context, Icons.logout, 'Đăng xuất', () => _logout(context), destructive: true),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool destructive = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: destructive ? AppColors.error : AppColors.textPrimary),
      title: Text(label, style: TextStyle(color: destructive ? AppColors.error : AppColors.textPrimary, fontWeight: FontWeight.w500)),
      trailing: destructive ? null : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
