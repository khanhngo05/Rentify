import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Nút bấm chuẩn của ứng dụng Rentify
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        width: width,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}

/// Nút icon nhỏ (dùng cho yêu thích, chia sẻ, v.v.)
class IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;

  const IconCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.textSecondary,
          size: size * 0.5,
        ),
      ),
    );
  }
}
