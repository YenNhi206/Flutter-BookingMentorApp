import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../models/user.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/chat_vm.dart';
import '../widgets/empty_state.dart';
import 'owner_chat_screen.dart';

/// Tab "Chat" trong [OwnerShell]: danh sách hội thoại với các khách hàng đã
/// từng nhắn tới cửa hàng - đối xứng với [ChatListScreen] phía khách.
class OwnerChatListScreen extends StatefulWidget {
  const OwnerChatListScreen({super.key});

  @override
  State<OwnerChatListScreen> createState() => _OwnerChatListScreenState();
}

class _OwnerChatListScreenState extends State<OwnerChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final storeId = context.read<AuthViewModel>().currentUser?.storeId;
    if (storeId == null) return;
    await context.read<ChatViewModel>().loadStoreConversations(storeId);
  }

  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<AuthViewModel>().currentUser?.storeId;
    final chatVm = context.watch<ChatViewModel>();

    if (storeId == null) {
      return const Scaffold(body: Center(child: Text('Không tìm thấy cửa hàng của bạn')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chat với khách')),
      body: chatVm.storeConversations.isEmpty
          ? const EmptyState(
              emoji: '💬',
              title: 'Chưa có hội thoại nào',
              subtitle: 'Tin nhắn từ khách hàng sẽ hiện ở đây.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: chatVm.storeConversations.length,
                itemBuilder: (context, index) {
                  final last = chatVm.storeConversations[index];
                  return FutureBuilder<AppUser?>(
                    future: context.read<AuthViewModel>().getUserById(last.userId),
                    builder: (context, snapshot) {
                      final customerName = snapshot.data?.fullName ?? 'Khách hàng';
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: AppColors.surfaceCard, child: Icon(Icons.person)),
                          title: Text(customerName),
                          subtitle: Text(last.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Text(AppFormatters.time(last.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OwnerChatScreen(userId: last.userId, storeId: storeId, customerName: customerName),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
