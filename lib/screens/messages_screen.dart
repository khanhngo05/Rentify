import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MsgItem {
  _MsgItem({required this.text, required this.isSent});
  final String text;
  final bool isSent; // true: user sent, false: remote
}

class _MessagesScreenState extends State<MessagesScreen> {
  final List<_MsgItem> _messages = [];
  final TextEditingController _controller = TextEditingController();

  final List<String> _presets = [
    'Tôi muốn thuê bây giờ',
    'Bạn còn hàng không?',
    'Cho tôi xin giá và kích thước',
    'Tôi cần thử vào ngày mai',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.insert(0, _MsgItem(text: text.trim(), isSent: true));
    });
    _controller.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi')), // quick feedback
    );
  }

  // Send preset automatically (for new chats / quick-reply)
  void _sendPreset(String text) {
    _send(text);
  }

  @override
  Widget build(BuildContext context) {
    final isNewConversation = _messages.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: SafeArea(
        child: Column(
          children: [
            if (isNewConversation) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Gợi ý nhanh',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (c, i) {
                    final p = _presets[i];
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: AppColors.primary.withOpacity(0.12),
                          ),
                        ),
                      ),
                      onPressed: () => _sendPreset(p),
                      child: Text(p),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: _presets.length,
                ),
              ),
              const SizedBox(height: 8),
            ],

            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Chưa có tin nhắn. Chạm một gợi ý để gửi nhanh.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (c, i) {
                        final m = _messages[i];
                        return Align(
                          alignment: m.isSent
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.72,
                            ),
                            decoration: BoxDecoration(
                              color: m.isSent
                                  ? AppColors.primary.withOpacity(0.12)
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              m.text,
                              style: TextStyle(
                                color: m.isSent
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Input area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Nhập tin nhắn...',
                              ),
                              onSubmitted: (_) => _send(_controller.text),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _send(_controller.text),
                            icon: const Icon(Icons.send_rounded),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
