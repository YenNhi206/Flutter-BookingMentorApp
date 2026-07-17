import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/chat_vm.dart';
import '../../viewmodels/food_vm.dart';
import '../widgets/empty_state.dart';
import 'chat_screen.dart';

/// Danh sách hội thoại với các cửa hàng - tap vào 1 hội thoại để mở
/// [ChatScreen] chi tiết.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthViewModel>().currentUser?.id;
      if (userId != null) context.read<ChatViewModel>().loadConversations(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatVm = context.watch<ChatViewModel>();
    final foodVm = context.watch<FoodViewModel>();
    final userId = context.watch<AuthViewModel>().currentUser?.id;

    if (userId == null) {
      return const Scaffold(
        body: EmptyState(emoji: '💬', title: 'Log in to chat', subtitle: 'Sign in to message our stores.'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages')),
      body: chatVm.conversations.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Start a conversation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                ...foodVm.stores.map((store) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: AppColors.surfaceCard, child: Icon(Icons.storefront)),
                        title: Text(store.name),
                        subtitle: Text(store.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ChatScreen(storeId: store.id, storeName: store.name)),
                        ),
                      ),
                    )),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: chatVm.conversations.length,
              itemBuilder: (context, index) {
                final last = chatVm.conversations[index];
                final store = foodVm.getStoreById(last.storeId);
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppColors.surfaceCard, child: Icon(Icons.storefront)),
                    title: Text(store?.name ?? 'Store'),
                    subtitle: Text(last.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(AppFormatters.time(last.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ChatScreen(storeId: last.storeId, storeName: store?.name ?? 'Store')),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
