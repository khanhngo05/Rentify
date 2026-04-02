import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../controllers/cart_controller.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _selectedBranch;
  final List<String> _branches = ['Đống Đa', 'Cầu Giấy', 'Hai Bà Trưng'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng'), centerTitle: true),
      body: ListenableBuilder(
        listenable: cartController,
        builder: (context, _) {
          final items = cartController.items;
          if (items.isEmpty) return const Center(child: Text('Giỏ hàng trống'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...items.map((item) => Card(
                child: ListTile(
                  leading: Image.network(item.imageUrl, width: 50, fit: BoxFit.cover),
                  title: Text(item.productName),
                  subtitle: Text('Size: ${item.size} | SL: ${item.quantity}'),
                  trailing: Text(AppConstants.formatPrice(item.totalItemPrice)),
                ),
              )),
              const SizedBox(height: 20),
              const Text('Chọn chi nhánh nhận/trả đồ:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _selectedBranch,
                items: _branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => _selectedBranch = v),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    final total = cartController.totalRentalPrice + cartController.totalDeposit;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tổng cộng:'), Text(AppConstants.formatPrice(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary))]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () {
                if (_selectedBranch == null) return;
                cartController.clearCart();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt thuê từ giỏ hàng thành công!')));
              },
              child: const Text('Xác nhận đặt thuê'),
            ),
          ),
        ],
      ),
    );
  }
}