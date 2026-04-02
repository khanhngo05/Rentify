import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';

class RentalBookingScreen extends StatefulWidget {
  final dynamic product; 
  final String? selectedSize;
  final String? selectedColor;

  const RentalBookingScreen({
    Key? key,
    this.product,
    this.selectedSize,
    this.selectedColor,
  }) : super(key: key);

  @override
  State<RentalBookingScreen> createState() => _RentalBookingScreenState();
}

class _RentalBookingScreenState extends State<RentalBookingScreen> {
  final _addressController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  int _rentalDays = 1;
  String _selectedBranch = 'Chi nhánh Đống Đa';
  
  final List<String> _branches = ['Chi nhánh Đống Đa', 'Chi nhánh Cầu Giấy', 'Chi nhánh Thanh Xuân'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()!.containsKey('address')) {
          setState(() {
            _addressController.text = doc['address'] ?? '';
          });
        }
      } catch (e) {
        debugPrint("Lỗi lấy thông tin user: $e");
      }
    }
  }

  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _rentalDays = picked.duration.inDays;
        if (_rentalDays == 0) _rentalDays = 1; 
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn thời gian thuê!')));
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập địa chỉ nhận đồ!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cartProvider = context.read<CartProvider>();
      final user = FirebaseAuth.instance.currentUser;
      List<Map<String, dynamic>> orderItems = [];
      double totalRental = 0;
      double totalDeposit = 0;

      if (widget.product != null) {
        // Đã sửa lại đúng tên biến của P1: rentalPricePerDay và depositAmount
        double price = (widget.product.rentalPricePerDay ?? 0).toDouble();
        double deposit = (widget.product.depositAmount ?? 0).toDouble();
        
        orderItems.add({
          'productId': widget.product.id ?? '',
          'productName': widget.product.name ?? 'Sản phẩm thuê',
          'size': widget.selectedSize ?? 'Free',
          'color': widget.selectedColor ?? 'Mặc định',
          'quantity': 1,
          'pricePerDay': price,
        });
        totalRental = price;
        totalDeposit = deposit;
      } else {
        orderItems = cartProvider.cartItems.map((item) => {
          'productId': item.productId,
          'productName': item.productName,
          'size': item.selectedSize,
          'color': item.selectedColor,
          'quantity': item.quantity,
          'pricePerDay': item.rentalPricePerDay,
        }).toList();
        totalRental = cartProvider.totalRentalPrice;
        totalDeposit = cartProvider.totalDepositPrice;
      }

      final orderData = {
        'userId': user?.uid ?? 'guest',
        'items': orderItems,
        'branch': _selectedBranch,
        'address': _addressController.text.trim(),
        'startDate': Timestamp.fromDate(_selectedDateRange!.start),
        'endDate': Timestamp.fromDate(_selectedDateRange!.end),
        'rentalDays': _rentalDays,
        'totalRentalPrice': totalRental * _rentalDays,
        'totalDepositPrice': totalDeposit,
        'status': 'pending', 
        'createdAt': FieldValue.serverTimestamp(),
      };

      DocumentReference docRef = await FirebaseFirestore.instance.collection('orders').add(orderData);

      if (widget.product == null) {
        cartProvider.clearCart();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo đơn thành công! Mã đơn: ${docRef.id}')),
      );
      
      context.go('/history'); 

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi chốt đơn: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    // Đã sửa lại đúng tên biến của P1 để hiển thị real-time không bị crash
    double displayRental = widget.product != null 
        ? (widget.product.rentalPricePerDay ?? 0).toDouble() * _rentalDays 
        : cartProvider.totalRentalPrice * _rentalDays;
    double displayDeposit = widget.product != null 
        ? (widget.product.depositAmount ?? 0).toDouble()
        : cartProvider.totalDepositPrice;

    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận đặt thuê')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: Text(_selectedDateRange == null 
                    ? 'Chọn ngày thuê và trả' 
                    : '${_selectedDateRange!.start.toString().substring(0,10)} đến ${_selectedDateRange!.end.toString().substring(0,10)}'),
                  subtitle: Text('Số ngày thuê: $_rentalDays ngày'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _pickDateRange,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedBranch,
                decoration: const InputDecoration(labelText: 'Chi nhánh phục vụ', border: OutlineInputBorder()),
                items: _branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) => setState(() => _selectedBranch = val!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ nhận đồ', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const Text('Tổng tiền thuê:'), Text('$displayRental đ', style: const TextStyle(fontWeight: FontWeight.bold))],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const Text('Tiền đặt cọc:'), Text('$displayDeposit đ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitOrder,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
                  child: const Text('Xác nhận thuê', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              )
            ],
          ),
    );
  }
}