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

  const AddToCartDialog({
    Key? key,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.rentalPrice,
    required this.depositPrice,
    required this.selectedSize,
    required this.selectedColor,
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
          onPressed: () {
            // 1. Tạo CartItem mới
            final newItem = CartItemModel(
              productId: productId,
              productName: productName,
              imageUrl: imageUrl,
              selectedSize: selectedSize,
              selectedColor: selectedColor,
              rentalPricePerDay: rentalPrice,
              depositPrice: depositPrice,
            );

            // 2. Gọi hàm lưu vào giỏ
            context.read<CartProvider>().addToCart(newItem);

            // 3. Đóng dialog và báo thành công
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã thêm vào giỏ hàng thành công!')),
            );
          },
          child: const Text('Đồng ý'),
        ),
      ],
    );
  }
}