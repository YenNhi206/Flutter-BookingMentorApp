import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/notification_vm.dart';
import '../widgets/empty_state.dart';

/// Danh sách thông báo: đơn đã xác nhận, đang giao, khuyến mãi... item
/// chưa đọc có chấm đen bên trái. Có nút "Mark all as read".
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthViewModel>().currentUser?.id;
      if (userId != null) context.read<NotificationViewModel>().load(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    final userId = context.watch<AuthViewModel>().currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (vm.unreadCount > 0 && userId != null)
            TextButton(
              onPressed: () => context.read<NotificationViewModel>().markAllRead(userId),
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: vm.notifications.isEmpty
          ? const EmptyState(emoji: '🔔', title: 'No notifications yet', subtitle: 'We will let you know when something happens.')
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: vm.notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = vm.notifications[index];
                return GestureDetector(
                  onTap: () => context.read<NotificationViewModel>().markRead(n.id),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(22)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6, right: 10),
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          )
                        else
                          const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(n.body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text(AppFormatters.dateTime(n.createdAt),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
