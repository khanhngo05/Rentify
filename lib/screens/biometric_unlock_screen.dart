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
        await widget.onVerified();
        return;
      }

      if (result == BiometricAuthResult.unavailable) {
        _showMessage('Vui lòng kích hoạt Face ID.');
        return;
      }

      _showMessage('Xác thực Face ID thất bại.');
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
                      backgroundImage: widget.avatarUrl != null
                          ? NetworkImage(widget.avatarUrl!)
                          : null,
                      child: widget.avatarUrl == null
                          ? Text(
                              avatarText,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 30,
                              ),
                            )
                          : null,
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
                      'Đăng nhập nhanh bằng Face ID',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isVerifying ? null : _verifyBiometric,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isVerifying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.fingerprint_rounded),
                        label: Text(
                          _isVerifying
                              ? 'Đang xác thực...'
                              : 'Xác thực Face ID / vân tay',
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
