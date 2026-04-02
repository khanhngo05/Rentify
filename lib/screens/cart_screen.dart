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
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Image.network(item.thumbnailUrl, width: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image)),
                  title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Size: ${item.size} | SL: ${item.quantity}'),
                  trailing: Text(AppConstants.formatPrice(item.totalItemPrice), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              )),
              const SizedBox(height: 20),
              const Text('Chọn chi nhánh nhận đồ:', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return ListenableBuilder(
      listenable: cartController,
      builder: (context, _) {
        if (cartController.items.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () {
              if (_selectedBranch == null) return;
              cartController.clearCart();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt đơn thuê thành công! Chờ xác nhận.')));
            },
            child: const Text('Xác nhận đặt thuê'),
          ),
        );
      }
    );
  }
}