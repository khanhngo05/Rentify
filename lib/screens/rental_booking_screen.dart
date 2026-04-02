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
    this.isRentNow = true, // Mặc định là Thuê ngay, nếu false là Thêm vào giỏ
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

  bool get _hasReceiverInfo => (_receiverName?.isNotEmpty ?? false) && (_receiverPhone?.isNotEmpty ?? false);
  int get _rentalDays => _rentalRange.end.difference(_rentalRange.start).inDays + 1;

  @override
  void initState() {
    super.initState();
    _rentalRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());
    _receiverName = widget.initialUserName;
    _receiverPhone = widget.initialUserPhone;
    _receiverAddress = widget.initialUserAddress;
  }

  // Hàm tạo mã đơn và hiện Dialog thành công theo ý Leader
  void _showSuccessOrder(String orderId) {
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
            const Text('Đặt đơn thành công!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Mã đơn: $orderId', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            const Text('Trạng thái: Chờ xác nhận', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
  }

  @override
  Widget build(BuildContext context) {
    final rentalFee = widget.product.rentalPricePerDay * _rentalDays;
    final total = rentalFee + widget.product.depositAmount;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isRentNow ? 'Xác nhận thuê' : 'Cấu hình sản phẩm')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // UI địa chỉ... (giữ nguyên logic card của bạn)
          _buildSectionCard(
            title: 'Địa chỉ nhận đồ',
            child: Text(_hasReceiverInfo ? '$_receiverName - $_receiverPhone\n$_receiverAddress' : 'Chưa có thông tin'),
            onTap: () {}, // Mở dialog nhập địa chỉ
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: 'Thông tin thuê',
            child: Text('Sản phẩm: ${widget.product.name}\nSize: ${widget.selectedSize} | Màu: ${widget.selectedColor}\nNgày: ${_rentalDays} ngày'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16)),
                  Text(AppConstants.formatPrice(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    if (!_hasReceiverInfo) return;

                    if (widget.isRentNow) {
                      // Logic THUÊ NGAY: Tạo đơn Pending
                      _showSuccessOrder('RENT-${Random().nextInt(9999)}');
                    } else {
                      // Logic THÊM VÀO GIỎ
                      cartController.addToCart(CartItem(
                        productId: widget.product.id,
                        productName: widget.product.name,
                        imageUrl: widget.product.thumbnailUrl,
                        size: widget.selectedSize,
                        color: widget.selectedColor,
                        startDate: _rentalRange.start,
                        endDate: _rentalRange.end,
                        days: _rentalDays,
                        pricePerDay: widget.product.rentalPricePerDay,
                        deposit: widget.product.depositAmount,
                        receiverName: _receiverName!,
                        receiverPhone: _receiverPhone!,
                        receiverAddress: _receiverAddress!,
                        quantity: 1,
                      ));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng!')));
                    }
                  },
                  child: Text(widget.isRentNow ? 'Xác nhận thuê' : 'Thêm vào giỏ hàng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}