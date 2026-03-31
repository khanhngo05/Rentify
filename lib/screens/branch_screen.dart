import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_colors.dart';
import '../models/branch_model.dart';
import '../services/firebase_service.dart';
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
  late final _BranchViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = _BranchViewModel()..loadNearestBranches();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi nhánh gần bạn')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.state == BranchViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.state == BranchViewState.error) {
            return _BranchErrorState(
              message: _viewModel.errorMessage,
              onRetry: _viewModel.loadNearestBranches,
            );
          }

          return RefreshIndicator(
            onRefresh: _viewModel.loadNearestBranches,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _viewModel.branchDistances.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _viewModel.branchDistances[index];
                final branch = item.branch;
                final todayHours = _viewModel.getTodayHours(branch);
                final isOpen = _viewModel.isBranchOpenNow(branch);
                final openLabel = todayHours?.open ?? '--:--';
                final closeLabel = todayHours?.close ?? '--:--';

                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
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
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${branch.name} — cách bạn ${item.distanceKmText}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Giờ mở cửa: $openLabel - $closeLabel',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOpen ? 'Đang mở' : 'Đã đóng',
                              style: TextStyle(
                                color: isOpen
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Chạm để xem chi tiết',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

enum BranchViewState { loading, success, error }

class _BranchDistanceItem {
  _BranchDistanceItem({required this.branch, required this.distanceMeters});

  final BranchModel branch;
  final double distanceMeters;

  String get distanceKmText =>
      '${(distanceMeters / 1000).toStringAsFixed(1)} km';
}

class _BranchViewModel extends ChangeNotifier {
  _BranchViewModel({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  final FirebaseService _firebaseService;

  BranchViewState state = BranchViewState.loading;
  String errorMessage = '';

  List<_BranchDistanceItem> branchDistances = [];

  DayHours? getTodayHours(BranchModel branch, {DateTime? now}) {
    final date = now ?? DateTime.now();
    final dayKey = _weekdayKey(date.weekday);
    return branch.openingHours[dayKey];
  }

  bool isBranchOpenNow(BranchModel branch, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final hours = getTodayHours(branch, now: current);
    if (hours == null || !hours.isOpen) {
      return false;
    }

    final openMinutes = _timeToMinutes(hours.open);
    final closeMinutes = _timeToMinutes(hours.close);
    final nowMinutes = current.hour * 60 + current.minute;

    // Hỗ trợ ca qua đêm, ví dụ 20:00 -> 02:00.
    if (closeMinutes < openMinutes) {
      return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
    }

    return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
  }

  int _timeToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) {
      return 0;
    }
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  String _weekdayKey(int weekday) {
    const keys = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    if (weekday < 1 || weekday > 7) {
      return 'monday';
    }
    return keys[weekday - 1];
  }

  Future<void> loadNearestBranches() async {
    state = BranchViewState.loading;
    errorMessage = '';
    notifyListeners();

    try {
      final userPosition = await _getCurrentPosition();
      final branches = await _firebaseService.getBranches();

      final mapped = branches.map((branch) {
        final distance = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          branch.latitude,
          branch.longitude,
        );

        return _BranchDistanceItem(branch: branch, distanceMeters: distance);
      }).toList();

      mapped.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

      branchDistances = mapped;
      state = BranchViewState.success;
      notifyListeners();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      state = BranchViewState.error;
      notifyListeners();
    }
  }

  Future<Position> _getCurrentPosition() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw Exception('Vui lòng bật dịch vụ định vị (GPS).');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Bạn chưa cấp quyền vị trí cho ứng dụng.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy bật lại trong cài đặt.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
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
