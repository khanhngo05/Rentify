import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart_item_model.dart';
import '../../providers/cart_provider.dart';

class AddToCartDialog extends StatelessWidget {
  final String productId;
  final String productName;
  final String imageUrl;
  final double rentalPrice;
  final double depositPrice;
  final String selectedSize; 
  final String selectedColor;
  final String branchId;
  final String branchName;
  final String branchAddress;

  const AddToCartDialog({
    Key? key,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.rentalPrice,
    required this.depositPrice,
    required this.selectedSize,
    required this.selectedColor,
    required this.branchId,
    required this.branchName,
    required this.branchAddress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác nhận thêm vào giỏ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Size: $selectedSize | Màu: $selectedColor'),
          Text('Giá thuê: $rentalPrice đ/ngày'),
          Text('Cọc: $depositPrice đ'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              // 1. Tạo CartItem mới
              final newItem = CartItemModel(
                productId: productId,
                productName: productName,
                imageUrl: imageUrl,
                selectedSize: selectedSize,
                selectedColor: selectedColor,
                rentalPricePerDay: rentalPrice,
                depositPrice: depositPrice,
                branchId: branchId,
                branchName: branchName,
                branchAddress: branchAddress,
              );

              // 2. Gọi hàm lưu vào giỏ
              await context.read<CartProvider>().addToCart(newItem);

              // 3. Đóng dialog và báo thành công
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã thêm vào giỏ hàng thành công!')),
              );
            } catch (e) {
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Đồng ý'),
        ),
      ],
    );
  }
}