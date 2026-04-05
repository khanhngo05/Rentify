import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/biometric_service.dart';

class BiometricUnlockScreen extends StatefulWidget {
  const BiometricUnlockScreen({
    super.key,
    required this.displayName,
    required this.userUid,
    this.avatarUrl,
    this.email,
    required this.onVerified,
    this.onUseAnotherAccount,
  });

  final String displayName;
  final String userUid;
  final String? avatarUrl;
  final String? email;
  final Future<void> Function() onVerified;
  final Future<void> Function()? onUseAnotherAccount;

  @override
  State<BiometricUnlockScreen> createState() => _BiometricUnlockScreenState();
}

class _BiometricUnlockScreenState extends State<BiometricUnlockScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _isVerifying = false;

  Future<void> _verifyBiometric() async {
    if (_isVerifying) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final result = await _biometricService.authenticateForLogin();
      if (!mounted) {
        return;
      }

      if (result == BiometricAuthResult.verified) {
        try {
          await widget.onVerified();
        } catch (_) {
          _showMessage(
            'Xác thực thành công nhưng không thể đăng nhập. Vui lòng thử lại.',
          );
        }
        return;
      }

      if (result == BiometricAuthResult.unavailable) {
        _showMessage(
          'Thiết bị chưa sẵn sàng sinh trắc học. Vui lòng kiểm tra vân tay.',
        );
        return;
      }

      _showMessage('Xác thực vân tay không hợp lệ. Vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.displayName.trim().isNotEmpty
        ? widget.displayName.trim()
        : (widget.email ?? 'Rentify User');
    final avatarUrl = widget.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final avatarText = displayName.characters.first.toUpperCase();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.surfaceVariant,
                      child: hasAvatar
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: avatarUrl,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                fadeInDuration: const Duration(
                                  milliseconds: 120,
                                ),
                                placeholder: (context, url) => const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Text(
                                    avatarText,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 30,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              avatarText,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 30,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đăng nhập nhanh bằng vân tay',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyBiometric,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isVerifying
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.fingerprint_rounded,
                                      size: 20,
                                    ),
                              const SizedBox(width: 8),
                              Text(
                                _isVerifying
                                    ? 'Đang xác thực...'
                                    : 'Quét vân tay để đăng nhập',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (widget.onUseAnotherAccount != null) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _isVerifying
                            ? null
                            : () async {
                                await widget.onUseAnotherAccount!();
                              },
                        child: const Text('Dùng tài khoản khác'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
