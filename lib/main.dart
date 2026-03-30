import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'constants/app_theme.dart';
import 'constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo Supabase
  // TODO: Thay bằng URL và anonKey thật từ Supabase Dashboard
  await Supabase.initialize(
    url: 'https://tjydkxdvipovzqnmejrt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqeWRreGR2aXBvdnpxbm1lanJ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4NTIzNzAsImV4cCI6MjA5MDQyODM3MH0.ezOVGMfTuqHX3nwmJjdliw3qBfp6cH72-TqWt6wRO1Y',
  );

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
      home: const Scaffold(
        body: Center(
          child: Text(
            '${AppConstants.appName}\n${AppConstants.appTagline}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
