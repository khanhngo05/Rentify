import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/branch_model.dart';
import '../services/firebase_service.dart';

enum BranchViewState { loading, success, error }

class BranchDistanceItem {
  BranchDistanceItem({required this.branch, required this.distanceMeters});

  final BranchModel branch;
  final double distanceMeters;

  String get distanceKmText =>
      '${(distanceMeters / 1000).toStringAsFixed(1)} km';
}

class BranchViewModel extends ChangeNotifier {
  BranchViewModel({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  final FirebaseService _firebaseService;

  BranchViewState state = BranchViewState.loading;
  String errorMessage = '';

  List<BranchDistanceItem> branchDistances = [];
  String searchQuery = '';
  bool openNowOnly = false;

  List<BranchDistanceItem> get visibleBranchDistances {
    return branchDistances.where((item) {
      final branch = item.branch;
      final normalizedQuery = searchQuery.trim().toLowerCase();

      final matchesQuery =
          normalizedQuery.isEmpty ||
          branch.name.toLowerCase().contains(normalizedQuery) ||
          branch.address.toLowerCase().contains(normalizedQuery);

      final matchesOpenState = !openNowOnly || isBranchOpenNow(branch);
      return matchesQuery && matchesOpenState;
    }).toList();
  }

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

  String getStatusDetailText(BranchModel branch, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final isOpen = isBranchOpenNow(branch, now: current);
    final todayHours = getTodayHours(branch, now: current);

    if (isOpen) {
      final closeLabel = todayHours?.close ?? '--:--';
      return 'Đóng lúc $closeLabel';
    }

    final openLabel = todayHours?.open ?? '--:--';
    if (todayHours != null && todayHours.isOpen) {
      return 'Mở lại lúc $openLabel';
    }

    final tomorrow = current.add(const Duration(days: 1));
    final nextDayHours = getTodayHours(branch, now: tomorrow);
    if (nextDayHours != null && nextDayHours.isOpen) {
      return 'Mở ngày mai lúc ${nextDayHours.open}';
    }

    return 'Tạm ngưng phục vụ';
  }

  void updateSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setOpenNowOnly(bool value) {
    openNowOnly = value;
    notifyListeners();
  }

  void clearFilters() {
    searchQuery = '';
    openNowOnly = false;
    notifyListeners();
  }

  Future<void> openDirections(BranchModel branch) async {
    final destination = '${branch.latitude},${branch.longitude}';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
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

        return BranchDistanceItem(branch: branch, distanceMeters: distance);
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
