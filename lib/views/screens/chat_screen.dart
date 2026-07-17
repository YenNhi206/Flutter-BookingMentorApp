import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../models/message.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/chat_vm.dart';

/// Hội thoại 1-1 với 1 cửa hàng. Bubble tin của mình nền đen bo góc phải
/// dưới nhọn, tin cửa hàng nền xám. Có auto-reply mô phỏng sau 1s.
class ChatScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  const ChatScreen({super.key, required this.storeId, required this.storeName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthViewModel>().currentUser?.id;
      if (userId != null) context.read<ChatViewModel>().loadMessages(userId, widget.storeId);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    final userId = context.read<AuthViewModel>().currentUser?.id;
    if (userId == null) return;
    _inputController.clear();
    await context.read<ChatViewModel>().sendMessage(userId: userId, storeId: widget.storeId, content: text);
    if (!mounted) return;
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatVm = context.watch<ChatViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.storeName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatVm.messages.length,
              itemBuilder: (context, index) => _Bubble(message: chatVm.messages[index]),
            ),
          ),
          if (chatVm.isSending)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Store is typing...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(hintText: 'Type a message...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isFromUser = message.isFromUser;
    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isFromUser ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isFromUser ? 20 : 4),
            bottomRight: Radius.circular(isFromUser ? 4 : 20),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(color: isFromUser ? Colors.white : AppColors.textPrimary),
        ),
      ),
    );
  }
}
