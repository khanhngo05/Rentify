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
            isScrollable: true, labelColor: AppColors.primary,
            tabs: [Tab(text: 'Chờ xác nhận'), Tab(text: 'Đã xác nhận'), Tab(text: 'Đang thuê'), Tab(text: 'Đã trả'), Tab(text: 'Hoàn thành'), Tab(text: 'Đã hủy')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList('pending'), // Chỉ hiện đơn ở đây (giả lập)
            _buildEmptyState(), _buildEmptyState(), _buildEmptyState(), _buildEmptyState(), _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(String status) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (context, i) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mã đơn: RTF8892$i', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            const Text('Sản phẩm: Áo dài truyền thống'),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Hủy đơn', style: TextStyle(color: Colors.red)))),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text('Chưa có đơn hàng nào ở trạng thái này'));
}