import 'package:flutter/material.dart';
import 'dart:math';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/product_model.dart';
import '../controllers/cart_controller.dart';
import 'cart_screen.dart';

class RentalBookingScreen extends StatefulWidget {
  final Product product; final String selectedSize, selectedColor;
  final String? initialUserName, initialUserPhone, initialUserAddress;
  const RentalBookingScreen({super.key, required this.product, required this.selectedSize, required this.selectedColor, this.initialUserName, this.initialUserPhone, this.initialUserAddress});

  @override
  State<RentalBookingScreen> createState() => _RentalBookingScreenState();
}

class _RentalBookingScreenState extends State<RentalBookingScreen> {
  late DateTimeRange _rentalRange;
  String? _n, _p, _a;

  @override
  void initState() {
    super.initState();
    _rentalRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());
    _n = widget.initialUserName; _p = widget.initialUserPhone; _a = widget.initialUserAddress;
  }

  @override
  Widget build(BuildContext context) {
    final days = _rentalRange.end.difference(_rentalRange.start).inDays + 1;
    final total = (widget.product.rentalPricePerDay * days) + widget.product.depositAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận thuê')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ListTile(title: const Text('Người nhận'), subtitle: Text('$_n - $_p\n$_a'), tileColor: Colors.grey[100]),
        const SizedBox(height: 12),
        ListTile(title: Text(widget.product.name), subtitle: Text('Size: ${widget.selectedSize} | Ngày: $days'), trailing: Text(AppConstants.formatPrice(total))),
      ]),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () {
            if (_n == null) return;
            // GIẢ LẬP TẠO ĐƠN THÀNH CÔNG (Yêu cầu 6)
            showDialog(context: context, builder: (c) => AlertDialog(
              title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
              content: Text('Tạo đơn thuê thành công!\nMã đơn: RTF${Random().nextInt(99999)}\nTrạng thái: Chờ xác nhận', textAlign: TextAlign.center),
              actions: [TextButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('Về trang chủ'))],
            ));
          },
          child: const Text('Xác nhận thuê ngay'),
        ),
      ),
    );
  }
}