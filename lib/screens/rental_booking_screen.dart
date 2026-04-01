import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  late DateTimeRange _rentalRange;

  int get _rentalDays {
    return _rentalRange.end.difference(_rentalRange.start).inDays + 1;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _rentalRange = DateTimeRange(start: today, end: today);
  }

  String _formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  Future<void> _pickRentalRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: _rentalRange,
      helpText: 'Chọn ngày thuê',
      confirmText: 'Xác nhận',
      cancelText: 'Hủy',
      saveText: 'Lưu',
    );

    if (picked == null) {
      return;
    }

    final selectedDays = picked.end.difference(picked.start).inDays + 1;
    if (selectedDays < AppConstants.minRentalDays ||
        selectedDays > AppConstants.maxRentalDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng chọn từ ${AppConstants.minRentalDays} đến ${AppConstants.maxRentalDays} ngày.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _rentalRange = picked;
    });
  }

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
            'Thời gian thuê',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDate(_rentalRange.start)} - ${_formatDate(_rentalRange.end)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _pickRentalRange,
                      child: const Text('Chọn lịch'),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Tổng số ngày thuê: $_rentalDays ngày',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
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
