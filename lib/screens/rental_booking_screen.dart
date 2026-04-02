import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/product_model.dart';
import '../controllers/cart_controller.dart';

class RentalBookingScreen extends StatefulWidget {
  final Product product; final String selectedSize, selectedColor;
  final String? initialUserName, initialUserPhone, initialUserAddress;
  const RentalBookingScreen({super.key, required this.product, required this.selectedSize, required this.selectedColor, this.initialUserName, this.initialUserPhone, this.initialUserAddress});

  @override
  State<RentalBookingScreen> createState() => _RentalBookingScreenState();
}

class _RentalBookingScreenState extends State<RentalBookingScreen> {
  late DateTimeRange _range;
  @override
  void initState() {
    super.initState();
    _range = DateTimeRange(start: DateTime.now(), end: DateTime.now());
  }

  void _handleAction() {
    final orderId = 'RTF${Random().nextInt(99999)}';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: Text('Tạo đơn thuê thành công!\nMã đơn: $orderId\nTrạng thái: Chờ xác nhận', textAlign: TextAlign.center),
        actions: [TextButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('Về trang chủ'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cấu hình đơn thuê')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(title: const Text('Người nhận'), subtitle: Text('${widget.initialUserName ?? "Dũng Nguyễn"} - ${widget.initialUserPhone ?? ""}')),
          const Divider(),
          Text(widget.product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _handleAction,
          child: const Text('Thêm vào giỏ hàng'), // ĐÃ KHÔI PHỤC TÊN NÚT
        ),
      ),
    );
  }
}