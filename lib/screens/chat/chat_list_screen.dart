import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/chat_repository.dart';
import '../../models/chat_message.dart';
import '../../models/mentor.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mentor_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _chatRepository = ChatRepository();
  List<ChatMessage> _conversations = [];
  final Map<String, Mentor> _mentorsById = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final mentorProvider = context.read<MentorProvider>();
    final studentId = auth.currentUser!.id;
    final latest = await _chatRepository.getLatestPerConversation(studentId);
    if (mentorProvider.mentors.isEmpty) {
      await mentorProvider.loadMentors();
    }
    for (final m in mentorProvider.mentors) {
      _mentorsById[m.id] = m;
    }
    if (!mounted) return;
    setState(() {
      _conversations = latest;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final studentId = auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages'), automaticallyImplyLeading: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No conversations yet. Book a mentor and start chatting from their profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final message = _conversations[index];
                    final mentorId = message.senderId == studentId
                        ? message.conversationId.replaceFirst('${studentId}_', '')
                        : message.senderId;
                    final mentor = _mentorsById[mentorId];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: mentor != null ? NetworkImage(mentor.avatarUrl) : null,
                        child: mentor == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(mentor?.name ?? 'Mentor'),
                      subtitle: Text(message.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: mentor == null
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    mentorId: mentor.id,
                                    mentorName: mentor.name,
                                    studentId: studentId,
                                  ),
                                ),
                              ),
                    );
                  },
                ),
    );
  }
}
