import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/product_model.dart';

class RentalBookingScreen extends StatefulWidget {
  const RentalBookingScreen({
    super.key,
    required this.product,
    required this.selectedSize,
    required this.selectedColor,
  });

  final Product product;
  final String selectedSize;
  final String selectedColor;

  @override
  State<RentalBookingScreen> createState() => _RentalBookingScreenState();
}

class _RentalBookingScreenState extends State<RentalBookingScreen> {
  int _rentalDays = 1;

  @override
  Widget build(BuildContext context) {
    final rentalFee = widget.product.rentalPricePerDay * _rentalDays;
    final total = rentalFee + widget.product.depositAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Thuê ngay')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Size: ${widget.selectedSize.isEmpty ? 'Chưa chọn' : widget.selectedSize}',
                ),
                const SizedBox(height: 4),
                Text(
                  'Màu: ${widget.selectedColor.isEmpty ? 'Chưa chọn' : widget.selectedColor}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Số ngày thuê',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Slider(
            min: AppConstants.minRentalDays.toDouble(),
            max: AppConstants.maxRentalDays.toDouble(),
            value: _rentalDays.toDouble(),
            divisions: AppConstants.maxRentalDays - AppConstants.minRentalDays,
            label: '$_rentalDays ngày',
            onChanged: (value) {
              setState(() {
                _rentalDays = value.round();
              });
            },
          ),
          Text('$_rentalDays ngày'),
          const SizedBox(height: 14),
          _PriceRow(
            label: 'Giá thuê',
            value:
                '${AppConstants.formatPrice(widget.product.rentalPricePerDay)}/ngày',
          ),
          _PriceRow(
            label: 'Phí thuê ($_rentalDays ngày)',
            value: AppConstants.formatPrice(rentalFee),
          ),
          _PriceRow(
            label: 'Tiền đặt cọc',
            value: AppConstants.formatPrice(widget.product.depositAmount),
          ),
          const Divider(height: 24),
          _PriceRow(
            label: 'Tổng tạm tính',
            value: AppConstants.formatPrice(total),
            isEmphasized: true,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã chuyển sang màn thuê (P4).')),
              );
            },
            child: const Text('Tiếp tục đặt thuê'),
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  final String label;
  final String value;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w500,
      color: isEmphasized ? AppColors.primary : AppColors.textPrimary,
      fontSize: isEmphasized ? 16 : 14,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: style),
        ],
      ),
    );
  }
}
