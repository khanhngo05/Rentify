import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'cart_booking_screen.dart'; // Màn hình đặt thuê cho giỏ hàng

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng của bạn'),
        centerTitle: true,
      ),
      // Dùng Consumer để lắng nghe sự thay đổi từ CartProvider
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final cartItems = cartProvider.cartItems;

          if (cartItems.isEmpty) {
            return const Center(
              child: Text('Giỏ hàng của bạn đang trống!', style: TextStyle(fontSize: 16)),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Ảnh sản phẩm
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.image_not_supported, size: 80),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Thông tin sản phẩm
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Size: ${item.selectedSize} | Màu: ${item.selectedColor}'),
                                  Text('Giá: ${item.rentalPricePerDay} đ/ngày', style: const TextStyle(color: Colors.blue)),
                                  
                                  // Nút tăng giảm số lượng
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () => cartProvider.updateQuantity(
                                            item.productId, item.selectedSize, item.selectedColor, false),
                                      ),
                                      Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () => cartProvider.updateQuantity(
                                            item.productId, item.selectedSize, item.selectedColor, true),
                                      ),
                                      const Spacer(),
                                      // Nút xóa
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => cartProvider.removeFromCart(
                                            item.productId, item.selectedSize, item.selectedColor),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Phần Bottom hiển thị tổng tiền và nút Xác nhận
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tạm tính thuê (1 ngày):'),
                        Text('${cartProvider.totalRentalPrice} đ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng tiền cọc:'),
                        Text('${cartProvider.totalDepositPrice} đ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Kiểm tra nếu giỏ có sản phẩm
                          if (cartProvider.cartItems.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Giỏ hàng trống!')),
                            );
                            return;
                          }
                          
                          // Điều hướng sang trang Đặt thuê cho giỏ hàng
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CartBookingScreen(
                                branchId: cartProvider.branchId!,
                                branchName: cartProvider.branchName!,
                                branchAddress: cartProvider.branchAddress!,
                              ),
                            ),
                          );
                        },
                        child: const Text('Xác nhận đặt thuê', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}