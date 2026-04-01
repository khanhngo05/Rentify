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
      appBar: AppBar(title: const Text('Thu\u00ea ngay')),
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
                const SizedBox(height: 6),
                Text(
                  'Size: ${widget.selectedSize.isEmpty ? 'Ch\u01b0a ch\u1ecdn' : widget.selectedSize}',
                ),
                const SizedBox(height: 4),
                Text(
                  'M\u00e0u: ${widget.selectedColor.isEmpty ? 'Ch\u01b0a ch\u1ecdn' : widget.selectedColor}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'S\u1ed1 ng\u00e0y thu\u00ea',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Slider(
            min: AppConstants.minRentalDays.toDouble(),
            max: AppConstants.maxRentalDays.toDouble(),
            value: _rentalDays.toDouble(),
            divisions: AppConstants.maxRentalDays - AppConstants.minRentalDays,
            label: '$_rentalDays ng\u00e0y',
            onChanged: (value) {
              setState(() {
                _rentalDays = value.round();
              });
            },
          ),
          Text('$_rentalDays ng\u00e0y'),
          const SizedBox(height: 16),
          _PriceRow(
            label: 'Gi\u00e1 thu\u00ea',
            value:
                '${AppConstants.formatPrice(widget.product.rentalPricePerDay)}/ng\u00e0y',
          ),
          _PriceRow(
            label: 'Ph\u00ed thu\u00ea ($_rentalDays ng\u00e0y)',
            value: AppConstants.formatPrice(rentalFee),
          ),
          _PriceRow(
            label: 'Ti\u1ec1n \u0111\u1eb7t c\u1ecdc',
            value: AppConstants.formatPrice(widget.product.depositAmount),
          ),
          const Divider(height: 24),
          _PriceRow(
            label: 'T\u1ed5ng t\u1ea1m t\u00ednh',
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
                const SnackBar(
                  content: Text(
                    '\u0110\u00e3 chuy\u1ec3n sang flow thu\u00ea (P4).',
                  ),
                ),
              );
            },
            child: const Text('Ti\u1ebfp t\u1ee5c \u0111\u1eb7t thu\u00ea'),
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
