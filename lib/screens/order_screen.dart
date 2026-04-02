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
          title: const Text('Đơn hàng của tôi'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Chờ xác nhận'), Tab(text: 'Đã xác nhận'), Tab(text: 'Đang thuê'),
              Tab(text: 'Đã trả'), Tab(text: 'Hoàn thành'), Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OrderList(status: 'pending'), OrderList(status: 'confirmed'),
            OrderList(status: 'renting'), OrderList(status: 'returned'),
            OrderList(status: 'completed'), OrderList(status: 'cancelled'),
          ],
        ),
      ),
    );
  }
}

class OrderList extends StatelessWidget {
  final String status;
  const OrderList({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (context, index) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              ListTile(title: Text('Mã đơn: RTF1029$index'), subtitle: const Text('Ngày đặt: 02/04/2026')),
              if (status == 'pending')
                Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Hủy đơn', style: TextStyle(color: Colors.red))))
            ],
          ),
        ),
      ),
    );
  }
}