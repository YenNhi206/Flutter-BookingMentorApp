import 'package:flutter/foundation.dart';

import '../models/message.dart';
import '../repositories/chat_repository.dart';

/// Vài câu trả lời mẫu để mô phỏng phản hồi tự động từ cửa hàng - app không
/// có backend/nhân viên thật ở đầu bên kia nên đây là cách hợp lý để demo
/// luồng chat 2 chiều hoàn chỉnh.
const _autoReplies = [
  'Thank you for reaching out! Your order is being prepared 🍰',
  'Sure thing! We usually deliver within 30 minutes.',
  'Great choice! That item is one of our best sellers 😋',
  'Got it, we will note that down for your order.',
];

/// ViewModel chat: danh sách hội thoại + tin nhắn trong 1 hội thoại, có mô
/// phỏng độ trễ trả lời tự động (1 giây) sau mỗi tin nhắn của người dùng.
class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repository;

  ChatViewModel({ChatRepository? repository}) : _repository = repository ?? ChatRepository();

  List<Message> conversations = [];
  List<Message> messages = [];
  bool isSending = false;
  int unreadCount = 0;

  /// Hội thoại + badge chưa đọc phía chủ quán - tách riêng khỏi
  /// [conversations]/[unreadCount] vì đó là góc nhìn khách hàng.
  List<Message> storeConversations = [];
  int storeUnreadCount = 0;

  /// Hội thoại (userId, storeId) đang mở trên [ChatScreen] - dùng để chặn
  /// auto-reply trễ (1s) của [sendMessage] chèn nhầm vào [messages] nếu
  /// người dùng đã chuyển sang hội thoại khác trong lúc chờ.
  String? _activeUserId;
  String? _activeStoreId;

  bool _isActiveConversation(String userId, String storeId) =>
      _activeUserId == userId && _activeStoreId == storeId;

  Future<void> loadConversations(String userId) async {
    conversations = await _repository.getLastMessagePerStore(userId);
    notifyListeners();
  }

  Future<void> loadUnreadCount(String userId) async {
    unreadCount = await _repository.getUnreadCount(userId);
    notifyListeners();
  }

  Future<void> loadStoreConversations(String storeId) async {
    storeConversations = await _repository.getLastMessagePerCustomer(storeId);
    notifyListeners();
  }

  Future<void> loadStoreUnreadCount(String storeId) async {
    storeUnreadCount = await _repository.getUnreadCountForStore(storeId);
    notifyListeners();
  }

  /// Tải tin nhắn của 1 hội thoại từ góc nhìn chủ quán và đánh dấu đã đọc
  /// (vì chủ quán đang xem trực tiếp hội thoại này) - đồng thời cập nhật
  /// lại [storeUnreadCount].
  Future<void> loadMessagesForStore(String userId, String storeId) async {
    messages = await _repository.getMessages(userId, storeId);
    notifyListeners();
    await _repository.markConversationReadByStore(userId, storeId);
    await loadStoreUnreadCount(storeId);
  }

  /// Chủ quán gửi tin trả lời trực tiếp cho khách - khác với
  /// [sendMessage] (phía khách hàng) vì không mô phỏng auto-reply.
  Future<void> sendMessageAsStore({
    required String userId,
    required String storeId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;
    final message = await _repository.sendMessage(
      userId: userId,
      storeId: storeId,
      content: content.trim(),
      isFromUser: false,
    );
    messages = [...messages, message];
    notifyListeners();
  }

  /// Tải tin nhắn của 1 hội thoại và đánh dấu đã đọc (vì user đang xem
  /// trực tiếp hội thoại này) - đồng thời cập nhật lại [unreadCount].
  Future<void> loadMessages(String userId, String storeId) async {
    _activeUserId = userId;
    _activeStoreId = storeId;
    messages = await _repository.getMessages(userId, storeId);
    notifyListeners();
    await _repository.markConversationRead(userId, storeId);
    await loadUnreadCount(userId);
  }

  /// Gửi tin + mô phỏng auto-reply trễ 1s. Vì [messages]/[isSending] chỉ đại
  /// diện cho 1 hội thoại đang mở trên [ChatScreen] tại 1 thời điểm, nếu
  /// người dùng chuyển sang hội thoại khác trong lúc chờ auto-reply, tin trả
  /// lời vẫn được lưu đúng dưới DB cho hội thoại này nhưng KHÔNG được chèn
  /// vào [messages] (tránh lạc sang hội thoại đang mở lúc đó) và không bị
  /// đánh dấu đã đọc (vì người dùng không còn xem trực tiếp nữa).
  Future<void> sendMessage({
    required String userId,
    required String storeId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;
    final userMessage = await _repository.sendMessage(
      userId: userId,
      storeId: storeId,
      content: content.trim(),
      isFromUser: true,
    );
    if (_isActiveConversation(userId, storeId)) {
      messages = [...messages, userMessage];
      isSending = true;
      notifyListeners();
    }

    await Future.delayed(const Duration(seconds: 1));
    final reply = _autoReplies[DateTime.now().millisecondsSinceEpoch % _autoReplies.length];
    final storeMessage = await _repository.sendMessage(
      userId: userId,
      storeId: storeId,
      content: reply,
      isFromUser: false,
    );

    if (_isActiveConversation(userId, storeId)) {
      messages = [...messages, storeMessage];
      isSending = false;
      notifyListeners();
      // Người dùng đang xem hội thoại này ngay lúc trả lời tới, nên coi như
      // đã đọc luôn - tránh badge tăng ảo trong lúc họ vẫn đang ở màn chat.
      await _repository.markConversationRead(userId, storeId);
      await loadUnreadCount(userId);
    } else {
      // Đã chuyển sang hội thoại khác: giữ tin này ở trạng thái chưa đọc,
      // chỉ cập nhật lại badge tổng cho đúng số lượng.
      await loadUnreadCount(userId);
    }
  }
}
