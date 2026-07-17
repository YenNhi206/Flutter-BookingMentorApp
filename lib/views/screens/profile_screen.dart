import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../viewmodels/auth_vm.dart';
import 'auth_screen.dart';
import 'map_screen.dart';
import 'my_orders_screen.dart';

/// Tab Profile: avatar/tên/email + menu (Order history, Store locations,
/// Settings, Log out). Nếu là khách (guest), hiển thị lời mời đăng nhập.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (user != null) ...[
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
                      Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _menuItem(context, Icons.receipt_long_outlined, 'My Orders',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen()))),
            _menuItem(context, Icons.favorite_border, 'Favourites', () {}),
            _menuItem(context, Icons.location_on_outlined, 'Store locations',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MapScreen()))),
            _menuItem(context, Icons.settings_outlined, 'Settings', () {}),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _menuItem(context, Icons.logout, 'Log out', () => _logout(context), destructive: true),
          ] else ...[
            const SizedBox(height: 40),
            const Center(child: Text('👋', style: TextStyle(fontSize: 48))),
            const SizedBox(height: 12),
            const Text(
              'You are browsing as a guest',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Log in to save favourites, track orders and checkout.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen())),
              child: const Text('Log In'),
            ),
          ],
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

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthViewModel>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }
}
