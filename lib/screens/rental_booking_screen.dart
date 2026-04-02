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
    super.key, required this.product, required this.selectedSize, required this.selectedColor,
    this.initialUserName, this.initialUserPhone, this.initialUserAddress,
    this.isRentNow = true,
  });
  final Product product; final String selectedSize; final String selectedColor;
  final String? initialUserName; final String? initialUserPhone; final String? initialUserAddress;
  final bool isRentNow;

  @override
  State<RentalBookingScreen> createState() => _RentalBookingScreenState();
}

class _RentalBookingScreenState extends State<RentalBookingScreen> {
  late DateTimeRange _rentalRange;
  String? _receiverName; String? _receiverPhone; String? _receiverAddress;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rentalRange = DateTimeRange(start: now, end: now);
    _receiverName = widget.initialUserName;
    _receiverPhone = widget.initialUserPhone;
    _receiverAddress = widget.initialUserAddress;
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: Text('Tạo đơn thuê thành công!\nMã đơn: $orderId\nTrạng thái: Chờ xác nhận', textAlign: TextAlign.center),
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
    final days = _rentalRange.end.difference(_rentalRange.start).inDays + 1;
    final total = (widget.product.rentalPricePerDay * days) + widget.product.depositAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Cấu hình đơn thuê')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard('Địa chỉ nhận đồ', '${_receiverName ?? "Chưa chọn"} - ${_receiverPhone ?? ""}\n${_receiverAddress ?? ""}'),
          const SizedBox(height: 12),
          _buildCard('Sản phẩm', '${widget.product.name}\nSize: ${widget.selectedSize}'),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Tổng cộng:'),
                Text(AppConstants.formatPrice(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary))
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_receiverName == null) return;
                    if (widget.isRentNow) {
                      _showSuccessDialog('RTF${Random().nextInt(99999)}');
                    } else {
                      cartController.addToCart(CartItem(
                        productId: widget.product.id, productName: widget.product.name,
                        thumbnailUrl: widget.product.thumbnailUrl, size: widget.selectedSize,
                        color: widget.selectedColor, startDate: _rentalRange.start,
                        endDate: _rentalRange.end, days: days,
                        pricePerDay: widget.product.rentalPricePerDay, deposit: widget.product.depositAmount,
                        receiverName: _receiverName!, receiverPhone: _receiverPhone!,
                        receiverAddress: _receiverAddress!, quantity: 1,
                      ));
                      Navigator.pop(context);
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

  Widget _buildCard(String t, String c) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), Text(c)]),
  );
}