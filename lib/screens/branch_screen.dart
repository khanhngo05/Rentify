import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_colors.dart';
import '../models/branch_model.dart';
import '../viewmodels/branch_view_model.dart';
import 'branch_detail_screen.dart';

/// Màn hình hiển thị danh sách chi nhánh gần nhất dựa theo GPS.
///
/// Áp dụng MVVM đơn giản:
/// - View: `BranchScreen`
/// - ViewModel: `_BranchViewModel`
class BranchScreen extends StatefulWidget {
  const BranchScreen({super.key});

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  late final BranchViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BranchViewModel()..loadNearestBranches();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi nhánh gần bạn')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.state == BranchViewState.loading) {
            return const _BranchListSkeleton();
          }

          if (_viewModel.state == BranchViewState.error) {
            return _BranchErrorState(
              message: _viewModel.errorMessage,
              onRetry: _viewModel.loadNearestBranches,
            );
          }

          final items = _viewModel.visibleBranchDistances;

          return RefreshIndicator(
            onRefresh: _viewModel.loadNearestBranches,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: _viewModel.updateSearchQuery,
                          decoration: const InputDecoration(
                            hintText: 'Tìm tên chi nhánh hoặc khu vực...',
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilterChip(
                      selected: _viewModel.openNowOnly,
                      onSelected: _viewModel.setOpenNowOnly,
                      label: const Text('Đang mở hiện tại'),
                      avatar: Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: _viewModel.openNowOnly
                            ? AppColors.textOnPrimary
                            : AppColors.textSecondary,
                      ),
                      selectedColor: AppColors.primary,
                      checkmarkColor: AppColors.textOnPrimary,
                      labelStyle: TextStyle(
                        color: _viewModel.openNowOnly
                            ? AppColors.textOnPrimary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    const Spacer(),
                    Text(
                      '${items.length} chi nhánh',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  _BranchEmptyState(onClearFilters: _viewModel.clearFilters)
                else
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    final branch = item.branch;
                    final todayHours = _viewModel.getTodayHours(branch);
                    final isOpen = _viewModel.isBranchOpenNow(branch);
                    final openLabel = todayHours?.open ?? '--:--';
                    final closeLabel = todayHours?.close ?? '--:--';

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == items.length - 1 ? 0 : 12,
                      ),
                      child: _BranchCard(
                        branch: branch,
                        distanceText: item.distanceKmText,
                        openLabel: openLabel,
                        closeLabel: closeLabel,
                        isOpen: isOpen,
                        statusDetail: _viewModel.getStatusDetailText(branch),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BranchDetailScreen(
                                branch: branch,
                                distanceText: item.distanceKmText,
                                openLabel: openLabel,
                                closeLabel: closeLabel,
                                isOpen: isOpen,
                              ),
                            ),
                          );
                        },
                        onDirections: () => _viewModel.openDirections(branch),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BranchListSkeleton extends StatelessWidget {
  const _BranchListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: const [
          _SkeletonBox(height: 46, radius: 16),
          SizedBox(height: 10),
          Row(
            children: [
              _SkeletonBox(height: 34, width: 150, radius: 999),
              Spacer(),
              _SkeletonBox(height: 14, width: 70, radius: 8),
            ],
          ),
          SizedBox(height: 12),
          _BranchCardSkeleton(),
          SizedBox(height: 12),
          _BranchCardSkeleton(),
          SizedBox(height: 12),
          _BranchCardSkeleton(),
        ],
      ),
    );
  }
}

class _BranchCardSkeleton extends StatelessWidget {
  const _BranchCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 24, radius: 8)),
              SizedBox(width: 8),
              _SkeletonBox(height: 30, width: 66, radius: 999),
            ],
          ),
          SizedBox(height: 10),
          _SkeletonBox(height: 14, radius: 8),
          SizedBox(height: 6),
          _SkeletonBox(height: 14, width: 210, radius: 8),
          SizedBox(height: 12),
          _SkeletonBox(height: 14, width: 120, radius: 8),
          SizedBox(height: 10),
          Row(
            children: [
              _SkeletonBox(height: 30, width: 88, radius: 999),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBox(height: 14, radius: 8)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 38, radius: 10)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBox(height: 38, radius: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, this.width, required this.radius});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _BranchErrorState extends StatelessWidget {
  const _BranchErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchEmptyState extends StatelessWidget {
  const _BranchEmptyState({required this.onClearFilters});

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Column(
        children: [
          const Icon(
            Icons.store_mall_directory_outlined,
            color: AppColors.textHint,
            size: 30,
          ),
          const SizedBox(height: 10),
          const Text(
            'Không tìm thấy chi nhánh phù hợp',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy thử từ khóa khác hoặc bỏ lọc "Đang mở hiện tại".',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Xóa bộ lọc'),
          ),
        ],
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.distanceText,
    required this.openLabel,
    required this.closeLabel,
    required this.isOpen,
    required this.statusDetail,
    required this.onTap,
    required this.onDirections,
  });

  final BranchModel branch;
  final String distanceText;
  final String openLabel;
  final String closeLabel;
  final bool isOpen;
  final String statusDetail;
  final VoidCallback onTap;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        branch.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        distanceText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  branch.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$openLabel - $closeLabel',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isOpen ? 'Đang mở' : 'Đã đóng',
                        style: TextStyle(
                          color: isOpen ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        statusDetail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text(
                          'Xem chi tiết',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDirections,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.route_rounded, size: 16),
                        label: const Text(
                          'Chỉ đường',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
