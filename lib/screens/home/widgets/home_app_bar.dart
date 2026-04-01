import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';

class HomeAppBar extends StatelessWidget {
  final VoidCallback onCartTap;
  final VoidCallback onMessageTap;
  final VoidCallback onNotifyTap;

  const HomeAppBar({
    super.key,
    required this.onCartTap,
    required this.onMessageTap,
    required this.onNotifyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Rentify',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 34,
                height: 1,
              ),
            ),
          ),
          _ActionIcon(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Tin nhắn',
            onTap: onMessageTap,
          ),
          const SizedBox(width: 8),
          _ActionIcon(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Thông báo',
            onTap: onNotifyTap,
          ),
          const SizedBox(width: 8),
          _ActionIcon(
            icon: Icons.shopping_cart_outlined,
            tooltip: 'Giỏ hàng',
            onTap: onCartTap,
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
        ),
      ),
    );
  }
}
