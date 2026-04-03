import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'cart_booking_screen.dart'; // Màn hình đặt thuê cho giỏ hàng
import 'multi_cart_booking_screen.dart'; // Màn hình đặt thuê nhiều chi nhánh

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
                                  // Hiển thị tên chi nhánh
                                  Row(
                                    children: [
                                      const Icon(Icons.storefront, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.branchName,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Size: ${item.selectedSize} | Màu: ${item.selectedColor}'),
                                  Text('Giá: ${item.rentalPricePerDay} đ/ngày', style: const TextStyle(color: Colors.blue)),
                                  
                                  // Nút tăng giảm số lượng
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () async {
                                          // Nếu số lượng = 1, hiện dialog xác nhận
                                          if (item.quantity == 1) {
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Xác nhận xóa'),
                                                content: const Text('Bạn có chắc muốn xóa sản phẩm này khỏi giỏ hàng?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: const Text('Hủy'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            
                                            if (confirmed == true) {
                                              await cartProvider.removeFromCart(
                                                item.productId,
                                                item.selectedSize,
                                                item.selectedColor,
                                                item.branchId,
                                              );
                                            }
                                          } else {
                                            await cartProvider.updateQuantity(
                                              item.productId,
                                              item.selectedSize,
                                              item.selectedColor,
                                              item.branchId,
                                              false,
                                            );
                                          }
                                        },
                                      ),
                                      Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: item.quantity >= item.availableStock ? Colors.grey : null,
                                        ),
                                        onPressed: item.quantity >= item.availableStock
                                            ? null // Disable khi đã max
                                            : () async {
                                                final success = await cartProvider.updateQuantity(
                                                  item.productId,
                                                  item.selectedSize,
                                                  item.selectedColor,
                                                  item.branchId,
                                                  true,
                                                );
                                                
                                                if (!success && context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Đã đạt số lượng tồn kho tối đa!'),
                                                      duration: Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              },
                                      ),
                                      const Spacer(),
                                      // Nút xóa
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Xác nhận xóa'),
                                              content: const Text('Bạn có chắc muốn xóa sản phẩm này khỏi giỏ hàng?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Hủy'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                          
                                          if (confirmed == true) {
                                            await cartProvider.removeFromCart(
                                              item.productId,
                                              item.selectedSize,
                                              item.selectedColor,
                                              item.branchId,
                                            );
                                          }
                                        },
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
                    // Hiển thị cảnh báo nếu có nhiều chi nhánh
                    if (cartProvider.hasMultipleBranches) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Giỏ hàng có sản phẩm từ ${cartProvider.itemsByBranch.length} chi nhánh khác nhau. Sẽ tạo ${cartProvider.itemsByBranch.length} đơn hàng riêng.',
                                style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                          
                          // Nếu có nhiều chi nhánh → Chuyển sang màn hình multi-checkout
                          if (cartProvider.hasMultipleBranches) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MultiCartBookingScreen(),
                              ),
                            );
                          } else {
                            // Chỉ 1 chi nhánh → Dùng màn cũ
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
                          }
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