import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../viewmodels/messages_view_model.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final MessagesViewModel _viewModel;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = MessagesViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (!_viewModel.sendMessage(text)) {
      return;
    }
    _controller.clear();
  }

  void _sendPreset(String text) {
    if (!_viewModel.sendPreset(text)) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Trợ lý Rentify'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _viewModel.isAIEnabled
                    ? Colors.green.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _viewModel.isAIEnabled ? 'AI' : 'FAQ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _viewModel.isAIEnabled ? Colors.green : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Cuộc trò chuyện mới',
            onPressed: () {
              _viewModel.startNewChat();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            final messages = _viewModel.messages;

            return Column(
              children: [
                // Welcome message for new conversation
                if (_viewModel.isNewConversation) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.smart_toy_rounded,
                                size: 48,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Xin chào! 👋',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mình là trợ lý ảo của Rentify.\nMình có thể giúp bạn về giá thuê, cách đặt hàng, chi nhánh và nhiều thứ khác!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
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
                        final preset = _viewModel.presets[i];
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
                          onPressed: () => _sendPreset(preset),
                          child: Text(preset),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: _viewModel.presets.length,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Messages list
                Expanded(
                  child: messages.isEmpty && !_viewModel.isNewConversation
                      ? const Center(
                          child: Text(
                            'Chưa có tin nhắn',
                            style: TextStyle(fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length + (_viewModel.isTyping ? 1 : 0),
                          itemBuilder: (c, i) {
                            // Typing indicator at top (index 0 when reversed)
                            if (_viewModel.isTyping && i == 0) {
                              return _buildTypingIndicator();
                            }

                            final messageIndex = _viewModel.isTyping ? i - 1 : i;
                            if (messageIndex < 0 || messageIndex >= messages.length) {
                              return const SizedBox.shrink();
                            }

                            final message = messages[messageIndex];
                            return _buildMessageBubble(message);
                          },
                        ),
                ),

                // Input area
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
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
                                    hintText: 'Nhập câu hỏi...',
                                  ),
                                  onSubmitted: (_) => _send(_controller.text),
                                  enabled: !_viewModel.isTyping,
                                ),
                              ),
                              IconButton(
                                onPressed: _viewModel.isTyping
                                    ? null
                                    : () => _send(_controller.text),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageItem message) {
    return Align(
      alignment: message.isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            message.isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: message.isSent
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI badge for AI responses
                if (!message.isSent && message.isFromAI) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: Colors.purple.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Gemini AI',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  message.text,
                  style: TextStyle(
                    color: message.isSent
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (message.isSent)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: Icon(
                Icons.done_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.5 + (0.5 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
