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
  final List<String> _branches = ['Chi nhánh Đống Đa', 'Chi nhánh Cầu Giấy', 'Chi nhánh Hai Bà Trưng'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng'), centerTitle: true),
      body: ListenableBuilder(
        listenable: cartController,
        builder: (context, _) {
          final items = cartController.items;
          if (items.isEmpty) {
            return const Center(child: Text('Giỏ hàng của bạn đang trống'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...items.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Image.network(
                    item.imageUrl, // Đã fix đúng tên biến
                    width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image),
                  ),
                  title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Size: ${item.size} | SL: ${item.quantity}'),
                  trailing: Text(AppConstants.formatPrice(item.totalItemPrice), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              )),
              const SizedBox(height: 24),
              const Text('Chọn chi nhánh nhận/trả đồ:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedBranch,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                hint: const Text('Chọn chi nhánh'),
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
        final total = cartController.totalRentalPrice + cartController.totalDeposit;
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng thanh toán:'),
                    Text(AppConstants.formatPrice(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      if (_selectedBranch == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn chi nhánh!')));
                        return;
                      }
                      // Logic hoàn tất: Clear giỏ và hiện thông báo
                      cartController.clearCart();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt đơn thuê thành công! Đang chờ xác nhận.')));
                    },
                    child: const Text('Xác nhận đặt thuê'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}