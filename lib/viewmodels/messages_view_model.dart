import 'dart:collection';

import 'package:flutter/foundation.dart';
import '../services/chat_service.dart';

/// Model cho một tin nhắn
class MessageItem {
  const MessageItem({
    required this.text,
    required this.isSent,
    this.isLoading = false,
    this.isFromAI = false,
  });

  final String text;
  final bool isSent;
  final bool isLoading; // Đang chờ phản hồi
  final bool isFromAI; // Phản hồi từ AI (không phải FAQ)
}

class MessagesViewModel extends ChangeNotifier {
  final List<MessageItem> _messages = [];
  final ChatService _chatService = ChatService();
  bool _isTyping = false;

  UnmodifiableListView<MessageItem> get messages =>
      UnmodifiableListView(_messages);

  List<String> get presets => _chatService.getQuickSuggestions();

  bool get isNewConversation => _messages.isEmpty;

  bool get isTyping => _isTyping;

  bool get isAIEnabled => _chatService.isAIEnabled;

  bool sendMessage(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty || _isTyping) {
      return false;
    }

    _messages.insert(0, MessageItem(text: normalized, isSent: true));
    notifyListeners();
    _processMessage(normalized);
    return true;
  }

  bool sendPreset(String text) {
    return sendMessage(text);
  }

  Future<void> _processMessage(String userText) async {
    _isTyping = true;
    notifyListeners();

    try {
      // Gọi ChatService để lấy câu trả lời (FAQ first, AI fallback)
      final response = await _chatService.getAnswer(userText);

      // Kiểm tra xem có phải từ AI không (để hiển thị badge)
      final isFromAI =
          _chatService.isAIEnabled && _chatService.findFAQAnswer(userText) == null;

      _messages.insert(
        0,
        MessageItem(text: response, isSent: false, isFromAI: isFromAI),
      );
    } catch (e) {
      _messages.insert(
        0,
        const MessageItem(
          text: 'Xin lỗi, có lỗi xảy ra. Vui lòng thử lại!',
          isSent: false,
        ),
      );
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  /// Bắt đầu cuộc trò chuyện mới
  void startNewChat() {
    _messages.clear();
    _chatService.resetChat();
    notifyListeners();
  }
}
