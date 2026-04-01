import 'dart:async';

import 'package:flutter/foundation.dart';

class SplashViewModel extends ChangeNotifier {
  SplashViewModel({Duration? splashDuration})
    : splashDuration = splashDuration ?? const Duration(seconds: 2);

  final Duration splashDuration;
  Timer? _timer;
  bool _navigateToHome = false;

  bool get navigateToHome => _navigateToHome;

  void start() {
    _timer?.cancel();
    _timer = Timer(splashDuration, _requestNavigate);
  }

  void skip() {
    _requestNavigate();
  }

  void markNavigationHandled() {
    _navigateToHome = false;
  }

  void _requestNavigate() {
    if (_navigateToHome) {
      return;
    }
    _navigateToHome = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
