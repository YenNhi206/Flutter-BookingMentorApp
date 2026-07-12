import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/notification_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

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
      final auth = context.read<AuthProvider>();
      context.read<NotificationProvider>().loadForUser(auth.currentUser!.id);
    });
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Icons.event_available;
      case NotificationType.chat:
        return Icons.chat_bubble_outline;
      case NotificationType.system:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifications = context.watch<NotificationProvider>();
    final studentId = auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        automaticallyImplyLeading: false,
        actions: [
          if (notifications.unreadCount > 0)
            TextButton(
              onPressed: () => notifications.markAllRead(studentId),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.items.isEmpty
              ? const Center(child: Text('No notifications yet', style: TextStyle(color: Colors.black54)))
              : ListView.separated(
                  itemCount: notifications.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = notifications.items[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.isRead ? Colors.grey.shade200 : AppTheme.primarySoft,
                        child: Icon(_iconFor(item.type), color: item.isRead ? Colors.grey : AppTheme.primary),
                      ),
                      title: Text(item.title, style: TextStyle(fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Text(item.body),
                      trailing: Text(
                        '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.black38, fontSize: 12),
                      ),
                      onTap: () => notifications.markRead(item.id, studentId),
                    );
                  },
                ),
    );
  }
}
