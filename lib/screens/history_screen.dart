import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'rental_history_page.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const String _loginRequiredMessage =
      'Bạn cần đăng nhập để xem lịch sử thuê.';

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lịch sử thuê')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(_loginRequiredMessage, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return RentalHistoryPage(userId: currentUser.uid);
  }
}
