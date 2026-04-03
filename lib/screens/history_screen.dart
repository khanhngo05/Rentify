import 'package:flutter/material.dart';

import 'order_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrderScreen(
      initialStatusCode: 'completed',
      appBarTitle: 'Lịch sử thuê',
      loginRequiredMessage: 'Bạn cần đăng nhập để xem lịch sử thuê.',
      emptyMessage: 'Bạn chưa có lịch sử thuê nào',
    );
  }
}
