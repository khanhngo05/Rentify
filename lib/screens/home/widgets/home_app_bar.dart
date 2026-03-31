import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';

class HomeAppBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onCartTap;
  final VoidCallback onMessageTap;
  final VoidCallback onNotifyTap;
  final VoidCallback onClear;

  const HomeAppBar({
    super.key,
    required this.searchController,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onCartTap,
    required this.onMessageTap,
    required this.onNotifyTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Text(
                        'Rentify',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          letterSpacing: 0.4,
                          shadows: [
                            Shadow(
                              color: AppColors.primary.withOpacity(0.12),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        size: 22,
                        color: AppColors.primary,
                      ),
                      onPressed: onMessageTap,
                      tooltip: 'Tin nhắn',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        size: 24,
                        color: AppColors.primary,
                      ),
                      onPressed: onNotifyTap,
                      tooltip: 'Thông báo',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        size: 26,
                        color: AppColors.primary,
                      ),
                      onPressed: onCartTap,
                      tooltip: 'Giỏ hàng',
                    ),
                  ],
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: GestureDetector(
              onTap: onToggleExpand,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tìm sản phẩm...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchController.clear();
                          FocusScope.of(context).unfocus();
                          onClear();
                        },
                      ),
                    ),
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
