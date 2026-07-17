import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../viewmodels/chat_vm.dart';
import '../widgets/owner_bottom_nav.dart';
import 'owner_chat_list_screen.dart';
import 'owner_dashboard_screen.dart';
import 'owner_orders_screen.dart';
import 'owner_profile_screen.dart';
import 'store_manage_screen.dart';

/// Điểm neo của tài khoản chủ quán: 5 tab Dashboard/Đơn hàng/Chat/Menu/Hồ sơ
/// trong 1 [IndexedStack] để giữ trạng thái từng tab khi chuyển qua lại -
/// tương tự [MainShell] bên phía khách hàng (cùng phong cách floating
/// bottom nav, cùng 5 tab) nhưng tách biệt hoàn toàn về nội dung.
class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _index = 0;

  static const _screens = [
    OwnerDashboardScreen(),
    OwnerOrdersScreen(),
    OwnerChatListScreen(),
    StoreManageScreen(),
    OwnerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final chatUnread = context.watch<ChatViewModel>().storeUnreadCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: OwnerBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        chatUnreadCount: chatUnread,
      ),
    );
  }
}
