import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../models/message.dart';
import '../../viewmodels/chat_vm.dart';

/// Hội thoại 1-1 giữa chủ quán và 1 khách hàng cụ thể - đối xứng với
/// [ChatScreen] phía khách nhưng gửi tin qua [ChatViewModel.sendMessageAsStore]
/// (không mô phỏng auto-reply) và bubble của "mình" đổi thành tin từ cửa
/// hàng (`isFromUser == false`) thay vì tin từ khách.
class OwnerChatScreen extends StatefulWidget {
  final String userId;
  final String storeId;
  final String customerName;

  const OwnerChatScreen({
    super.key,
    required this.userId,
    required this.storeId,
    required this.customerName,
  });

  @override
  State<OwnerChatScreen> createState() => _OwnerChatScreenState();
}

class _OwnerChatScreenState extends State<OwnerChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ChatViewModel>().loadMessagesForStore(widget.userId, widget.storeId),
    );
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
    _inputController.clear();
    await context.read<ChatViewModel>().sendMessageAsStore(
          userId: widget.userId,
          storeId: widget.storeId,
          content: text,
        );
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
      appBar: AppBar(title: Text(widget.customerName)),
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(hintText: 'Nhập tin nhắn trả lời khách...'),
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
    final isMine = !message.isFromUser;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isMine ? 20 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 20),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(color: isMine ? Colors.white : AppColors.textPrimary),
        ),
      ),
    );
  }
}
