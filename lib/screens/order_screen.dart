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
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Chờ xác nhận'), Tab(text: 'Đã xác nhận'), Tab(text: 'Đang thuê'),
              Tab(text: 'Đã trả'), Tab(text: 'Hoàn thành'), Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: TabBarView(
          children: List.generate(6, (index) => _buildOrderList(index)),
        ),
      ),
    );
  }

  Widget _buildOrderList(int statusIndex) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mã đơn: RTF8892$index', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              const Text('Sản phẩm: Áo dài truyền thống'),
              const Text('Tổng: 450,000đ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              if (statusIndex == 0) // Chỉ tab "Chờ xác nhận" có nút hủy
                Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Hủy đơn', style: TextStyle(color: Colors.red)))),
            ],
          ),
        ),
      ),
    );
  }
}