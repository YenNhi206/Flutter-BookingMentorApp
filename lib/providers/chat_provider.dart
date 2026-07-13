import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/repositories/chat_repository.dart';
import '../models/chat_message.dart';
import '../services/local_notification_service.dart';

/// Canned mentor replies used to simulate a live conversation without a
/// real-time backend or a second logged-in user.
const _mentorAutoReplies = [
  "Thanks for reaching out! I'll review this before our session.",
  'Sounds good — see you at the scheduled time.',
  'Could you share more details so I can prepare?',
  "Great question, let's dig into that during the call.",
];

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;
  final _uuid = const Uuid();

  ChatProvider({ChatRepository? repository}) : _repository = repository ?? ChatRepository();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> loadConversation(String conversationId) async {
    _isLoading = true;
    notifyListeners();
    _messages = await _repository.getMessages(conversationId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage({
    required String studentId,
    required String mentorId,
    required String mentorName,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final conversationId = ChatRepository.conversationIdFor(studentId, mentorId);
    final message = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      createdAt: DateTime.now(),
    );
    await _repository.sendMessage(message);
    await loadConversation(conversationId);

    if (senderId == studentId) {
      await _simulateMentorReply(
        conversationId: conversationId,
        mentorId: mentorId,
        mentorName: mentorName,
      );
    }
  }

  Future<void> _simulateMentorReply({
    required String conversationId,
    required String mentorId,
    required String mentorName,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final reply = _mentorAutoReplies[DateTime.now().millisecond % _mentorAutoReplies.length];
    final message = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: mentorId,
      senderName: mentorName,
      text: reply,
      createdAt: DateTime.now(),
    );
    await _repository.sendMessage(message);
    await loadConversation(conversationId);

    // The backend has no "create my own notification" endpoint, so this can
    // no longer add an in-app Notifications-tab entry - the local device
    // push is still shown so the reply doesn't go unnoticed.
    await LocalNotificationService.instance.show(
      title: 'New message from $mentorName',
      body: reply,
    );
  }
}
