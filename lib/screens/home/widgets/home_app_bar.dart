import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';

class HomeAppBar extends StatelessWidget {
  final VoidCallback onCartTap;
  final VoidCallback onMessageTap;
  final VoidCallback onNotifyTap;
  final int unreadNotificationCount;
  final int cartItemCount;

  const HomeAppBar({
    super.key,
    required this.onCartTap,
    required this.onMessageTap,
    required this.onNotifyTap,
    this.unreadNotificationCount = 0,
    this.cartItemCount = 0,
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
            badgeCount: unreadNotificationCount,
          ),
          const SizedBox(width: 8),
          _ActionIcon(
            icon: Icons.shopping_cart_outlined,
            tooltip: 'Giỏ hàng',
            onTap: onCartTap,
            badgeCount: cartItemCount,
            animateBadge: true,
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
    this.badgeCount = 0,
    this.animateBadge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badgeCount;
  final bool animateBadge;

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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Icon(icon, color: AppColors.primary, size: 21),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<int>(badgeCount),
                    tween: Tween<double>(
                      begin: animateBadge ? 1.55 : 1,
                      end: 1,
                    ),
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
