import 'package:flutter/material.dart';

/// Bảng màu chủ đạo của Rentify
class AppColors {
  AppColors._(); // Không cho tạo instance

  // ── Màu chính ──────────────────────────────────────────────
  static const Color primary = Color(0xFF1976D2); // Xanh dương chủ đạo
  static const Color primaryLight = Color(0xFF63A4FF);
  static const Color primaryDark = Color(0xFF0D47A1);

  static const Color secondary = Color(0xFFFF6B6B); // Hồng coral
  static const Color secondaryLight = Color(0xFFFF9E9E);

  // ── Nền & Surface ─────────────────────────────────────────
  static const Color background = Color(0xFFF4F7FC); // Nền sáng nhẹ xanh
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEFF4FF);
  static const Color card = Color(0xFFFFFFFF);

  // ── Text ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF172033); // Đen xanh đậm
  static const Color textSecondary = Color(0xFF5E6A7D); // Xám trung
  static const Color textHint = Color(0xFF91A0B7); // Xám nhạt
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Trạng thái ────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Xanh lá
  static const Color warning = Color(0xFFF59E0B); // Vàng cam
  static const Color error = Color(0xFFEF4444); // Đỏ
  static const Color info = Color(0xFF3B82F6); // Xanh dương

  // ── Trạng thái đơn thuê ───────────────────────────────────
  static const Color statusPending = Color(0xFFF59E0B); // 🟡 Chờ xác nhận
  static const Color statusConfirmed = Color(0xFF3B82F6); // 🔵 Đã xác nhận
  static const Color statusRenting = Color(0xFF10B981); // 🟢 Đang thuê
  static const Color statusReturned = Color(0xFF6B7280); // ⚪ Đã trả
  static const Color statusCompleted = Color(0xFF059669); // ✅ Hoàn thành
  static const Color statusCancelled = Color(0xFFEF4444); // ❌ Đã hủy

  // ── Khác ──────────────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color favorite = Color(0xFFFF4757); // Đỏ tim ❤️
  static const Color star = Color(0xFFFFC107); // Vàng sao ⭐

  /// Lấy màu theo trạng thái đơn thuê
  static Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return statusPending;
      case 'confirmed':
        return statusConfirmed;
      case 'renting':
        return statusRenting;
      case 'returned':
        return statusReturned;
      case 'completed':
        return statusCompleted;
      case 'cancelled':
        return statusCancelled;
      default:
        return textSecondary;
    }
  }
}
