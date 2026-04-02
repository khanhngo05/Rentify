import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn hàng'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [Tab(text: 'Chờ xác nhận'), Tab(text: 'Đã xác nhận'), Tab(text: 'Đang thuê'), Tab(text: 'Đã trả'), Tab(text: 'Hoàn thành'), Tab(text: 'Đã hủy')],
          ),
        ),
        body: TabBarView(
          children: List.generate(6, (i) => Center(child: Text('Danh sách đơn hàng trạng thái $i'))),
        ),
      ),
    );
  }
}