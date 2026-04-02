import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../viewmodels/splash_view_model.dart';
import 'home_screen.dart';

/// Splash screen that displays app logo and name, then navigates to Home.
/// Waits for [splashDuration] before navigating. Default is 2 hours.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.splashDuration});

  // default to 2 hours as requested; in tests you can pass shorter duration.
  final Duration? splashDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final SplashViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SplashViewModel(splashDuration: widget.splashDuration);
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.start();
  }

  void _onViewModelChanged() {
    if (!mounted || !_viewModel.navigateToHome) {
      return;
    }
    _viewModel.markNavigationHandled();
    _goHome();
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simple circular logo made from the primary color and app initial.
    return GestureDetector(
      onTap: _viewModel.skip, // allow tap to skip the long wait
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      AppConstants.appName.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appTagline,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
