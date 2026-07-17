import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../viewmodels/cart_vm.dart';
import '../../viewmodels/chat_vm.dart';
import '../../viewmodels/main_tab_vm.dart';
import '../widgets/floating_bottom_nav.dart';
import 'cart_screen.dart';
import 'chat_list_screen.dart';
import 'favourites_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Điểm neo của [FloatingBottomNav]: giữ 4 tab Home/Chat/Cart/Profile trong
/// 1 [IndexedStack] để không mất trạng thái khi chuyển tab, nổi bên trên là
/// thanh nav dạng pill.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _screens = [
    HomeScreen(),
    FavouritesScreen(),
    CartScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tabIndex = context.watch<MainTabViewModel>().index;
    final cartCount = context.watch<CartViewModel>().items.length;
    final chatUnread = context.watch<ChatViewModel>().unreadCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: tabIndex, children: _screens),
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: tabIndex,
        onTap: context.read<MainTabViewModel>().setIndex,
        cartCount: cartCount,
        chatUnreadCount: chatUnread,
      ),
    );
  }
}
