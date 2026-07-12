import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/repositories/chat_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final String mentorId;
  final String mentorName;
  final String studentId;

  const ChatScreen({
    super.key,
    required this.mentorId,
    required this.mentorName,
    required this.studentId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversation(
            ChatRepository.conversationIdFor(widget.studentId, widget.mentorId),
          );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final auth = context.read<AuthProvider>();
    await context.read<ChatProvider>().sendMessage(
          studentId: widget.studentId,
          mentorId: widget.mentorId,
          mentorName: widget.mentorName,
          senderId: widget.studentId,
          senderName: auth.currentUser!.name,
          text: text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.mentorName)),
      body: Column(
        children: [
          Expanded(
            child: chat.isLoading && chat.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: false,
                    padding: const EdgeInsets.all(12),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) {
                      final message = chat.messages[index];
                      final isMe = message.senderId == widget.studentId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                          decoration: BoxDecoration(
                            color: isMe ? AppTheme.primary : const Color(0xFFEDEDF3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Type a message...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _send,
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
