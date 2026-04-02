import 'dart:collection';

import 'package:flutter/foundation.dart';

class MessageItem {
  const MessageItem({required this.text, required this.isSent});

  final String text;
  final bool isSent;
}

class MessagesViewModel extends ChangeNotifier {
  final List<MessageItem> _messages = [];

  final List<String> _presets = const [
    'Tôi muốn thuê bây giờ',
    'Bạn còn hàng không?',
    'Cho tôi xin giá và kích thước',
    'Tôi cần thử vào ngày mai',
  ];

  UnmodifiableListView<MessageItem> get messages =>
      UnmodifiableListView(_messages);

  UnmodifiableListView<String> get presets => UnmodifiableListView(_presets);

  bool get isNewConversation => _messages.isEmpty;

  bool sendMessage(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return false;
    }

    _messages.insert(0, MessageItem(text: normalized, isSent: true));
    notifyListeners();
    _enqueueAutoReply(normalized);
    return true;
  }

  bool sendPreset(String text) {
    return sendMessage(text);
  }

  Future<void> _enqueueAutoReply(String userText) async {
    final reply = _buildAutoReply(userText);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    _messages.insert(0, MessageItem(text: reply, isSent: false));
    notifyListeners();
  }

  String _buildAutoReply(String input) {
    final text = input.toLowerCase();

    if (_containsAny(text, const ['giá', 'gia', 'bao nhiêu', 'bao nhieu'])) {
      return 'Hiện bên mình có nhiều mẫu từ 180,000đ/ngày đến 500,000đ/ngày. Bạn muốn mình gợi ý theo ngân sách nào ạ?';
    }

    if (_containsAny(text, const ['kích thước', 'kich thuoc', 'size'])) {
      return 'Rentify có đủ size S đến XXL cho hầu hết mẫu. Bạn cho mình chiều cao, cân nặng để mình gợi ý size chuẩn nhé.';
    }

    if (_containsAny(text, const [
      'còn hàng',
      'con hang',
      'còn không',
      'con khong',
    ])) {
      return 'Mẫu này vẫn còn hàng ở một số chi nhánh. Bạn muốn mình kiểm tra nhanh theo khu vực của bạn không?';
    }

    if (_containsAny(text, const ['thử', 'thu', 'ngày mai', 'ngay mai'])) {
      return 'Bạn có thể đặt lịch thử đồ trước tại chi nhánh gần nhất. Mình có thể giúp bạn đặt lịch vào ngày mai luôn.';
    }

    if (_containsAny(text, const ['thuê', 'thue', 'đặt', 'dat'])) {
      return 'Mình hỗ trợ bạn thuê ngay. Bạn cho mình biết mẫu bạn thích hoặc dịp sử dụng để mình đề xuất nhanh nhất nhé.';
    }

    if (_containsAny(text, const [
      'chi nhánh',
      'chi nhanh',
      'địa chỉ',
      'dia chi',
    ])) {
      return 'Mình có thể gửi chi nhánh gần bạn nhất kèm chỉ đường. Bạn muốn xem ngay không?';
    }

    return 'Mình đã nhận được tin nhắn của bạn. Bạn cần tư vấn về mẫu, giá, size hay chi nhánh gần nhất ạ?';
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
