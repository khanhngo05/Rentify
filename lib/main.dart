import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:provider/provider.dart'; // Phần bạn thêm: Import thư viện Provider

import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'screens/biometric_unlock_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/biometric_preference_service.dart';
import 'services/firebase_service.dart';
import 'providers/cart_provider.dart'; // Phần bạn thêm: Import CartProvider của bạn

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await supabase.Supabase.initialize(
      url: 'https://tjydkxdvipovzqnmejrt.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqeWRreGR2aXBvdnpxbm1lanJ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4NTIzNzAsImV4cCI6MjA5MDQyODM3MH0.ezOVGMfTuqHX3nwmJjdliw3qBfp6cH72-TqWt6wRO1Y',
    );
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  // Phần bạn thêm: Bọc ứng dụng trong MultiProvider để Giỏ hàng hoạt động xuyên suốt
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
      child: const RentifyApp(),
    ),
  );
}

class RentifyApp extends StatelessWidget {
  const RentifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(nextScreen: AuthGate(), durationSeconds: 2),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final BiometricPreferenceService _biometricPreferenceService =
      BiometricPreferenceService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _biometricVerified = false;
  String? _verifiedUserId;
  bool _isRestoringSessionAfterBiometric = false;
  bool _postLoginBypassGranted = false;
  String? _postLoginBypassUid;
  bool _forceShowLoginFormWhenLoggedOut = false;
  bool _skipBiometricOnceForAccountSwitch = false;
  bool _isSigningOutForDisabledBiometric = false;

  void _markBiometricVerified(String uid) {
    if (!mounted) {
      return;
    }

    setState(() {
      _biometricVerified = true;
      _verifiedUserId = uid;
    });
  }

  Future<void> _forceSignOutForDisabledBiometric(User user) async {
    if (_isSigningOutForDisabledBiometric) {
      return;
    }

    _isSigningOutForDisabledBiometric = true;
    try {
      if (_authService.currentUser?.uid == user.uid) {
        await _authService.signOut();
      }
    } finally {
      _isSigningOutForDisabledBiometric = false;
    }
  }

  bool _canBypassBiometricForUser(User user) {
    if (_postLoginBypassUid != user.uid) {
      _postLoginBypassUid = user.uid;
      _postLoginBypassGranted = false;
    }

    if (!_postLoginBypassGranted) {
      _postLoginBypassGranted = _authService.consumePostLoginBypass(user.uid);
    }

    return _postLoginBypassGranted;
  }

  Widget _buildAuthorizedArea(User user) {
    // Load giỏ hàng khi user đăng nhập và đã qua bước xác thực sinh trắc học
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
    });

    // Kiểm tra role của user để phân luồng
    return FutureBuilder<UserModel?>(
      future: _firebaseService.getUserById(user.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userModel = userSnapshot.data;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _biometricPreferenceService.saveRememberedUserProfile(
            user,
            displayNameOverride: userModel?.displayName,
            avatarUrlOverride: userModel?.avatarUrl,
            emailOverride: userModel?.email,
          );
        });

        // Nếu là admin thì vào AdminMainScreen
        if (userModel != null && userModel.isAdmin) {
          return const AdminMainScreen();
        }

        // User thường vào HomeScreen
        return const HomeScreen(initialTabIndex: 0);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          if (_isRestoringSessionAfterBiometric) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!_isRestoringSessionAfterBiometric) {
            _biometricVerified = false;
            _verifiedUserId = null;
            _postLoginBypassGranted = false;
            _postLoginBypassUid = null;
          }

          if (_forceShowLoginFormWhenLoggedOut) {
            return const LoginScreen();
          }

          return FutureBuilder<RememberedUserProfile?>(
            future: _biometricPreferenceService.getRememberedUserProfile(),
            builder: (context, rememberedSnapshot) {
              if (rememberedSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final remembered = rememberedSnapshot.data;
              if (remembered == null) {
                return const LoginScreen();
              }

              return FutureBuilder<bool>(
                future: _biometricPreferenceService.isEnabledForUser(
                  remembered.uid,
                ),
                builder: (context, enabledSnapshot) {
                  if (enabledSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final enabled = enabledSnapshot.data ?? false;
                  if (!enabled) {
                    return const LoginScreen();
                  }

                  return BiometricUnlockScreen(
                    displayName: remembered.displayName,
                    userUid: remembered.uid,
                    avatarUrl: remembered.avatarUrl,
                    email: remembered.email,
                    onVerified: () async {
                      if (mounted) {
                        setState(() {
                          _isRestoringSessionAfterBiometric = true;
                        });
                      }

                      _markBiometricVerified(remembered.uid);
                      try {
                        await _authService.signInWithGoogle(
                          forceAccountSelection: false,
                          silentOnly: true,
                        );
                      } catch (_) {
                        if (mounted) {
                          setState(() {
                            _isRestoringSessionAfterBiometric = false;
                            _biometricVerified = false;
                            _verifiedUserId = null;
                          });
                        }
                        rethrow;
                      }
                    },
                    onUseAnotherAccount: () async {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _forceShowLoginFormWhenLoggedOut = true;
                        _skipBiometricOnceForAccountSwitch = true;
                      });
                    },
                  );
                },
              );
            },
          );
        }

        _forceShowLoginFormWhenLoggedOut = false;

        if (_isRestoringSessionAfterBiometric) {
          _biometricVerified = true;
          _verifiedUserId = user.uid;
          _isRestoringSessionAfterBiometric = false;
        }

        final isVerifiedForCurrentUser =
            _biometricVerified && _verifiedUserId == user.uid;

        if (_skipBiometricOnceForAccountSwitch) {
          _skipBiometricOnceForAccountSwitch = false;
          return _buildAuthorizedArea(user);
        }

        return FutureBuilder<bool>(
          future: _biometricPreferenceService.isEnabledForUser(user.uid),
          builder: (context, biometricSettingSnapshot) {
            if (biometricSettingSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final biometricEnabled = biometricSettingSnapshot.data ?? false;
            if (!biometricEnabled) {
              if (_canBypassBiometricForUser(user)) {
                return _buildAuthorizedArea(user);
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _forceSignOutForDisabledBiometric(user);
              });
              return const LoginScreen();
            }

            if (!isVerifiedForCurrentUser) {
              return FutureBuilder<UserModel?>(
                future: _firebaseService.getUserById(user.uid),
                builder: (context, profileSnapshot) {
                  final profile = profileSnapshot.data;
                  final displayName =
                      profile?.displayName ??
                      user.displayName ??
                      user.email ??
                      'Rentify User';
                  final avatarUrl = profile?.avatarUrl ?? user.photoURL;
                  final email = profile?.email ?? user.email;

                  return BiometricUnlockScreen(
                    displayName: displayName,
                    userUid: user.uid,
                    avatarUrl: avatarUrl,
                    email: email,
                    onVerified: () async {
                      _markBiometricVerified(user.uid);
                    },
                    onUseAnotherAccount: () async {
                      await _authService.signOut();
                    },
                  );
                },
              );
            }

            return _buildAuthorizedArea(user);
          },
        );
      },
    );
  }
}
