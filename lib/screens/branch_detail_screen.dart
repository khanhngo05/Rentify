import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../models/branch_model.dart';

/// Màn hình chi tiết chi nhánh + nút tra đường Google Maps.
class BranchDetailScreen extends StatelessWidget {
  const BranchDetailScreen({
    super.key,
    required this.branch,
    required this.distanceText,
    required this.openLabel,
    required this.closeLabel,
    required this.isOpen,
  });

  final BranchModel branch;
  final String distanceText;
  final String openLabel;
  final String closeLabel;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết chi nhánh')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              branch.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.near_me_rounded,
              label: 'Khoảng cách',
              value: distanceText,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Địa chỉ',
              value: branch.address,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Điện thoại',
              value: branch.phone,
            ),
            if (branch.email != null && branch.email!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: branch.email!,
              ),
            ],
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.access_time_rounded,
              label: 'Giờ mở cửa',
              value: '$openLabel - $closeLabel',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isOpen
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOpen ? 'Đang mở' : 'Đã đóng',
                style: TextStyle(
                  color: isOpen ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openDirections,
                icon: const Icon(Icons.route_rounded),
                label: const Text('Tra đường bằng Google Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDirections() async {
    final destination = '${branch.latitude},${branch.longitude}';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
