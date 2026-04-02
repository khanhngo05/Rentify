import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  
  // Dữ liệu giả lập, sau này P1 sẽ cung cấp hàm lấy danh sách chi nhánh
  final List<String> _branches = [
    'Chi nhánh Đống Đa',
    'Chi nhánh Cầu Giấy',
    'Chi nhánh Thanh Xuân'
  ];

  String _formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  void _handleCheckout() {
    if (_selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn chi nhánh thực hiện đơn!'), backgroundColor: Colors.red),
      );
      return;
    }

    // 1. Lấy danh sách sản phẩm trong giỏ
    final items = cartController.items;

    // 2. Map dữ liệu Giỏ hàng thành danh sách Map (JSON) để đẩy lên Firebase
    final List<Map<String, dynamic>> orderItems = items.map((item) {
      return {
        'productId': item.productId,
        'productName': item.productName,
        'size': item.size,
        'color': item.color,
        'quantity': item.quantity, // Đã bổ sung số lượng
        'startDate': item.startDate.toIso8601String(),
        'endDate': item.endDate.toIso8601String(),
        'days': item.days,
        'itemRentalPrice': item.totalItemPrice,
        'itemDeposit': item.totalItemDeposit, // Đã cập nhật tiền cọc theo số lượng
      };
    }).toList();

    // 3. Tạo Object Order tổng
    // Lấy thông tin người nhận từ item đầu tiên (vì cả giỏ dùng chung 1 địa chỉ giao)
    final orderData = {
      'userId': 'USER_ID_HIEN_TAI', // P5 (Auth) hoặc P1 sẽ cung cấp cách lấy ID user đang đăng nhập
      'branchName': _selectedBranch,
      'receiverName': items.first.receiverName,
      'receiverPhone': items.first.receiverPhone,
      'receiverAddress': items.first.receiverAddress,
      'totalRentalFee': cartController.totalRentalPrice,
      'totalDeposit': cartController.totalDeposit,
      'grandTotal': cartController.totalRentalPrice + cartController.totalDeposit,
      'status': 'Chờ xác nhận', // Trạng thái mặc định
      'createdAt': DateTime.now().toIso8601String(),
      'items': orderItems,
    };

    // In ra console để test dữ liệu
    debugPrint('Dữ liệu sẵn sàng đẩy lên Firebase: $orderData');

    // TODO: Khi P1 làm xong, bạn chỉ cần thay dòng debugPrint bằng:
    // await FirebaseService.createOrder(orderData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tạo đơn thuê thành công!'), backgroundColor: Colors.green),
    );
    
    // 4. Dọn dẹp giỏ hàng và quay về trang chủ
    cartController.clearCart();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey.shade50, 
      body: ListenableBuilder(
        listenable: cartController,
        builder: (context, child) {
          final items = cartController.items;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Giỏ hàng đang trống', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- Danh sách sản phẩm ---
              ...List.generate(items.length, (index) {
                final item = items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80, height: 80, color: AppColors.shimmerBase,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text('Size: ${item.size} • Màu: ${item.color}', style: const TextStyle(color: AppColors.textSecondary)),
                                const SizedBox(height: 8),
                                // Hiển thị Giá và Nút Tăng/Giảm số lượng
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppConstants.formatPrice(item.totalItemPrice),
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () => cartController.decrementQuantity(index),
                                            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: Icon(Icons.remove, size: 16)),
                                          ),
                                          Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          InkWell(
                                            onTap: () => cartController.incrementQuantity(index),
                                            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: Icon(Icons.add, size: 16)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => cartController.removeFromCart(index),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text('${_formatDate(item.startDate)} - ${_formatDate(item.endDate)} (${item.days} ngày)', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          // Hiển thị tiền cọc tương ứng với số lượng
                          Text('Cọc: ${AppConstants.formatPrice(item.totalItemDeposit)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 8),
              const Text('Chi nhánh thực hiện', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                hint: const Text('Chọn chi nhánh gần bạn'),
                value: _selectedBranch,
                items: _branches.map((branch) => DropdownMenuItem(value: branch, child: Text(branch))).toList(),
                onChanged: (value) => setState(() => _selectedBranch = value),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
      
      // --- Thanh chốt đơn ---
      bottomNavigationBar: ListenableBuilder(
        listenable: cartController,
        builder: (context, _) {
          if (cartController.items.isEmpty) return const SizedBox.shrink();
          
          final grandTotal = cartController.totalRentalPrice + cartController.totalDeposit;

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền cọc:', style: TextStyle(color: AppColors.textSecondary)),
                      Text(AppConstants.formatPrice(cartController.totalDeposit), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng phí thuê:', style: TextStyle(color: AppColors.textSecondary)),
                      Text(AppConstants.formatPrice(cartController.totalRentalPrice), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        AppConstants.formatPrice(grandTotal),
                        style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: _handleCheckout,
                      child: const Text('Xác nhận đặt thuê', style: TextStyle(fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}