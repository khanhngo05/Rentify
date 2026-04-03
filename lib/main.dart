import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:provider/provider.dart'; // Phần bạn thêm: Import thư viện Provider

import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_main_screen.dart';
import 'services/auth_service.dart';
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
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
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
  final FirebaseService _firebaseService = FirebaseService();

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
          return const LoginScreen();
        }

        // Load giỏ hàng khi user đăng nhập
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
            
            // Nếu là admin thì vào AdminMainScreen
            if (userModel != null && userModel.isAdmin) {
              return const AdminMainScreen();
            }

            // User thường vào HomeScreen
            return const HomeScreen();
          },
        );
      },
    );
  }
}