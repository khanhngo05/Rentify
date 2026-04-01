import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';

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

  runApp(const RentifyApp());
}

class RentifyApp extends StatelessWidget {
  const RentifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
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
          return _SignedOutView(authService: _authService);
        }

        return _SignedInView(authService: _authService, user: user);
      },
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView({required this.authService});

  final AuthService authService;

  Future<void> _openAuthOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AuthOptionsSheet(authService: authService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appTagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 240,
                  child: ElevatedButton.icon(
                    onPressed: () => _openAuthOptions(context),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Đăng nhập'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignedInView extends StatelessWidget {
  const _SignedInView({required this.authService, required this.user});

  final AuthService authService;
  final User user;

  Future<void> _signOut(BuildContext context) async {
    await authService.signOut();
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã đăng xuất')));
  }

  @override
  Widget build(BuildContext context) {
    final name = (user.displayName ?? '').trim();
    final email = (user.email ?? '').trim();
    final title = name.isNotEmpty ? name : (email.isNotEmpty ? email : 'User');

    return Scaffold(
      appBar: AppBar(title: const Text('Đã đăng nhập')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                child: Text(
                  title.characters.first.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                email.isEmpty ? 'Không có email' : email,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthOptionsSheet extends StatefulWidget {
  const _AuthOptionsSheet({required this.authService});

  final AuthService authService;

  @override
  State<_AuthOptionsSheet> createState() => _AuthOptionsSheetState();
}

class _AuthOptionsSheetState extends State<_AuthOptionsSheet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  bool _showEmailForm = false;
  bool _isRegisterMode = false;
  bool _isSubmitting = false;
  String? _inlineErrorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submitGoogleSignIn() async {
    setState(() {
      _isSubmitting = true;
      _inlineErrorMessage = null;
    });
    try {
      await widget.authService.signInWithGoogle();
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      final message = _messageFromAuthCode(e.code);
      final details = (e.message ?? '').trim();
      _showError(details.isEmpty ? message : '$message\nChi tiết: $details');
    } catch (_) {
      _showError('Đăng nhập Google thất bại.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _showError('Vui lòng nhập email hợp lệ.');
      return;
    }
    if (password.length < 6) {
      _showError('Mật khẩu tối thiểu 6 ký tự.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _inlineErrorMessage = null;
    });
    try {
      if (_isRegisterMode) {
        final displayName = _displayNameController.text.trim().isEmpty
            ? email.split('@').first
            : _displayNameController.text.trim();

        await widget.authService.signUp(
          email: email,
          password: password,
          displayName: displayName,
        );
      } else {
        final user = await widget.authService.signIn(
          email: email,
          password: password,
        );
        if (user == null) {
          _showError('Đăng nhập thất bại. Kiểm tra lại tài khoản.');
          return;
        }
      }

      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      final message = _messageFromAuthCode(e.code);
      final details = (e.message ?? '').trim();
      _showError(details.isEmpty ? message : '$message\nChi tiết: $details');
    } catch (_) {
      _showError('Không thể xử lý đăng nhập lúc này.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _inlineErrorMessage = message;
    });
  }

  String _messageFromAuthCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Sai mật khẩu hoặc thông tin đăng nhập.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'operation-not-allowed':
        return 'Provider này chưa được bật trong Firebase Auth.';
      case 'operation-not-supported':
        return 'Nền tảng hiện tại chưa hỗ trợ cách đăng nhập này.';
      case 'app-not-authorized':
        return 'Ứng dụng chưa được cấp quyền OAuth trong Firebase.';
      case 'unauthorized-domain':
        return 'Domain hiện tại chưa được cho phép trong Firebase Auth.';
      case 'invalid-api-key':
        return 'API key Firebase không hợp lệ.';
      case 'web-context-cancelled':
        return 'Phiên đăng nhập Google đã bị hủy.';
      case 'popup-closed-by-user':
        return 'Bạn đã đóng cửa sổ đăng nhập Google.';
      case 'popup-blocked':
        return 'Trình duyệt đã chặn popup đăng nhập.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng đợi một lúc.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng thử lại.';
      default:
        return 'Đăng nhập thất bại ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Đăng nhập',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _inlineErrorMessage == null
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey<String>(_inlineErrorMessage!),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF4C7C3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFB42318),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _inlineErrorMessage!,
                              style: const TextStyle(
                                color: Color(0xFF7A1B1B),
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            splashRadius: 18,
                            onPressed: () {
                              setState(() => _inlineErrorMessage = null);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFF7A1B1B),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitGoogleSignIn,
              icon: const Icon(Icons.account_circle_rounded),
              label: const Text('Đăng nhập bằng Google'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() {
                      _showEmailForm = !_showEmailForm;
                      _inlineErrorMessage = null;
                    }),
              icon: const Icon(Icons.email_outlined),
              label: Text(
                _showEmailForm ? 'Ẩn đăng nhập Email' : 'Đăng nhập bằng Email',
              ),
            ),
            if (_showEmailForm) ...[
              const SizedBox(height: 12),
              if (_isRegisterMode) ...[
                TextField(
                  controller: _displayNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    hintText: 'Nhập tên của bạn',
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Gmail/Email',
                  hintText: 'example@gmail.com',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                onSubmitted: (_) => _submitEmailAuth(),
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  hintText: 'Tối thiểu 6 ký tự',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEmailAuth,
                child: Text(
                  _isRegisterMode ? 'Tạo tài khoản' : 'Đăng nhập Email',
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() {
                        _isRegisterMode = !_isRegisterMode;
                        _inlineErrorMessage = null;
                      }),
                child: Text(
                  _isRegisterMode
                      ? 'Đã có tài khoản? Đăng nhập'
                      : 'Chưa có tài khoản? Đăng ký nhanh',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
