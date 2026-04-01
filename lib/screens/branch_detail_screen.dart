import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/branch_model.dart';
import '../viewmodels/branch_detail_view_model.dart';

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
    final viewModel = BranchDetailViewModel(
      branch: branch,
      distanceText: distanceText,
      openLabel: openLabel,
      closeLabel: closeLabel,
      isOpen: isOpen,
    );

    final statusDetail = viewModel.statusDetail;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết chi nhánh')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: viewModel.openDirections,
            icon: const Icon(Icons.route_rounded),
            label: const Text('Tra đường bằng Google Maps'),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              branch.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaPill(
                  icon: Icons.near_me_rounded,
                  text: distanceText,
                  background: AppColors.surfaceVariant,
                  foreground: AppColors.primary,
                ),
                _MetaPill(
                  icon: isOpen
                      ? Icons.schedule_rounded
                      : Icons.lock_clock_rounded,
                  text: isOpen ? 'Đang mở' : 'Đã đóng',
                  background: isOpen
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  foreground: isOpen ? AppColors.success : AppColors.error,
                ),
                _MetaPill(
                  icon: Icons.info_outline_rounded,
                  text: statusDetail,
                  background: AppColors.surface,
                  foreground: AppColors.textSecondary,
                  border: const BorderSide(color: AppColors.border),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoSection(
              title: 'Thông tin liên hệ',
              children: [
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
              ],
            ),
            const SizedBox(height: 12),
            _InfoSection(
              title: 'Giờ hoạt động',
              children: [
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  label: 'Lịch hôm nay',
                  value: '$openLabel - $closeLabel',
                ),
                const SizedBox(height: 8),
                Text(
                  statusDetail,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoSection(
              title: 'Bản đồ',
              children: [
                GestureDetector(
                  onTap: viewModel.openDirections,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.network(
                        'https://static-maps.yandex.ru/1.x/?ll=${branch.longitude},${branch.latitude}&size=650,300&z=15&l=map&pt=${branch.longitude},${branch.latitude},pm2rdm',
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return Container(
                            color: AppColors.surfaceVariant,
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stack) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: Icon(Icons.map_outlined, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
    this.border,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.fromBorderSide(border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
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
