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

  int get _rentalDays =>
      _rentalRange.end.difference(_rentalRange.start).inDays + 1;

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
      helpText: 'Chon ngay thue',
      confirmText: 'Xac nhan',
      cancelText: 'Huy',
      saveText: 'Luu',
    );

    if (picked == null) return;

    final selectedDays = picked.end.difference(picked.start).inDays + 1;
    if (selectedDays < AppConstants.minRentalDays ||
        selectedDays > AppConstants.maxRentalDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui long chon tu ${AppConstants.minRentalDays} den ${AppConstants.maxRentalDays} ngay.',
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
      appBar: AppBar(title: const Text('Thue ngay')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          const _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Dia chi nhan do',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Le Thu Giang  •  0378 122 051',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2),
                Text(
                  'Duong Co Bong, Doi 7 Tho Xuan, Huyen Dan Phuong, Ha Noi',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'San pham thue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.product.thumbnailUrl,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 84,
                          height: 84,
                          color: AppColors.shimmerBase,
                          child: const Icon(Icons.image_not_supported_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Size: ${widget.selectedSize.isEmpty ? 'Chua chon' : widget.selectedSize}',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mau: ${widget.selectedColor.isEmpty ? 'Chua chon' : widget.selectedColor}',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thoi gian thue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatDate(_rentalRange.start)} - ${_formatDate(_rentalRange.end)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: _pickRentalRange,
                      child: const Text('Chon lich'),
                    ),
                  ],
                ),
                Text(
                  'Tong so ngay thue: $_rentalDays ngay',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              children: [
                _PriceRow(
                  label: 'Gia thue',
                  value:
                      '${AppConstants.formatPrice(widget.product.rentalPricePerDay)}/ngay',
                ),
                _PriceRow(
                  label: 'Phi thue ($_rentalDays ngay)',
                  value: AppConstants.formatPrice(rentalFee),
                ),
                _PriceRow(
                  label: 'Tien dat coc',
                  value: AppConstants.formatPrice(widget.product.depositAmount),
                ),
                const Divider(height: 20),
                _PriceRow(
                  label: 'Tong tam tinh',
                  value: AppConstants.formatPrice(total),
                  isEmphasized: true,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tong cong',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      AppConstants.formatPrice(total),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Da chuyen sang man thue (P4).')),
                    );
                  },
                  child: const Text('Dat thue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
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
