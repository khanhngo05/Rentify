import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/product_model.dart';
import '../controllers/cart_controller.dart';
import 'cart_screen.dart';

class RentalBookingScreen extends StatefulWidget {
  const RentalBookingScreen({
    super.key,
    required this.product,
    required this.selectedSize,
    required this.selectedColor,
    this.initialUserName,
    this.initialUserPhone,
    this.initialUserAddress,
    required this.isRentNow, // Bắt buộc truyền để phân biệt luồng
  });

  final Product product;
  final String selectedSize;
  final String selectedColor;
  final String? initialUserName;
  final String? initialUserPhone;
  final String? initialUserAddress;
  final bool isRentNow;

  @override
  State<RentalBookingScreen> createState() => _RentalBookingScreenState();
}

class _RentalBookingScreenState extends State<RentalBookingScreen> {
  late DateTimeRange _rentalRange;
  String? _receiverName;
  String? _receiverPhone;
  String? _receiverAddress;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rentalRange = DateTimeRange(start: now, end: now.add(const Duration(days: 1)));
    
    // Lấy thông tin từ Firebase (truyền qua constructor)
    _receiverName = widget.initialUserName;
    _receiverPhone = widget.initialUserPhone;
    _receiverAddress = widget.initialUserAddress;
  }

  void _handleConfirmAction() {
    if (_receiverName == null || _receiverName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng cập nhật thông tin nhận đồ!')));
      return;
    }

    if (widget.isRentNow) {
      // LUỒNG THUÊ NGAY: Tạo mã đơn và hiện Dialog thành công
      final String orderId = 'RTF${Random().nextInt(999999).toString().padLeft(6, '0')}';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text('Đặt thuê thành công!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Mã đơn: $orderId', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const Text('Trạng thái: Chờ xác nhận', style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          actions: [
            Center(
              child: FilledButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Về trang chủ'),
              ),
            )
          ],
        ),
      );
    } else {
      // LUỒNG THÊM GIỎ HÀNG
      final newItem = CartItem(
        productId: widget.product.id,
        productName: widget.product.name,
        imageUrl: widget.product.thumbnailUrl, // Thống nhất dùng imageUrl
        size: widget.selectedSize,
        color: widget.selectedColor,
        startDate: _rentalRange.start,
        endDate: _rentalRange.end,
        days: _rentalRange.end.difference(_rentalRange.start).inDays,
        pricePerDay: widget.product.rentalPricePerDay,
        deposit: widget.product.depositAmount,
        receiverName: _receiverName!,
        receiverPhone: _receiverPhone!,
        receiverAddress: _receiverAddress!,
        quantity: 1,
      );

      cartController.addToCart(newItem);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm vào giỏ hàng!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rentalDays = _rentalRange.end.difference(_rentalRange.start).inDays;
    final total = (widget.product.rentalPricePerDay * rentalDays) + widget.product.depositAmount;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isRentNow ? 'Xác nhận thuê' : 'Cấu hình đơn thuê')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoSection('Địa chỉ nhận đồ', '${_receiverName ?? "Chưa có"} - ${_receiverPhone ?? ""}\n${_receiverAddress ?? ""}'),
          const SizedBox(height: 12),
          _buildInfoSection('Sản phẩm', '${widget.product.name}\nSize: ${widget.selectedSize} | Màu: ${widget.selectedColor}'),
          const SizedBox(height: 12),
          _buildInfoSection('Thời gian', 'Thuê $rentalDays ngày\nTừ ${DateFormat('dd/MM').format(_rentalRange.start)} đến ${DateFormat('dd/MM').format(_rentalRange.end)}'),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng:', style: TextStyle(fontSize: 16)),
                  Text(AppConstants.formatPrice(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _handleConfirmAction,
                  child: Text(widget.isRentNow ? 'Xác nhận thuê' : 'Thêm vào giỏ hàng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}