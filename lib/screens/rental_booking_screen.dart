import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/branch_model.dart';
import '../models/order_model.dart';
import '../providers/cart_provider.dart';
import '../services/firebase_service.dart';

class RentalBookingScreen extends StatefulWidget {
  const RentalBookingScreen({
    super.key,
    this.product,
    this.selectedSize,
    this.selectedColor,
    this.selectedBranchId,
  });

  final dynamic product;
  final String? selectedSize;
  final String? selectedColor;
  final String? selectedBranchId;

  @override
  State<RentalBookingScreen> createState() => _RentalBookingScreenState();
}

class _RentalBookingScreenState extends State<RentalBookingScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  DateTimeRange? _selectedDateRange;
  int _rentalDays = 1;
  List<BranchModel> _branches = <BranchModel>[];
  BranchModel? _selectedBranch;
  bool _isLoading = false;
  bool _isLoadingBranches = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadBranches();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final profile = await _firebaseService.getUserById(user.uid);
      if (!mounted || profile == null) return;

      setState(() {
        _nameController.text = profile.displayName;
        _phoneController.text = profile.phoneNumber ?? '';
        _addressController.text = profile.address ?? '';
      });
    } catch (error) {
      debugPrint('Lỗi lấy thông tin user: $error');
    }
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoadingBranches = true;
    });

    try {
      final branches = await _firebaseService.getBranches();
      if (!mounted) return;

      BranchModel? selected;
      if (branches.isNotEmpty) {
        selected = branches.first;
        final preferredId = widget.selectedBranchId;
        if (preferredId != null && preferredId.trim().isNotEmpty) {
          for (final branch in branches) {
            if (branch.id == preferredId) {
              selected = branch;
              break;
            }
          }
        }
      }

      setState(() {
        _branches = branches;
        _selectedBranch = selected;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải chi nhánh: $error')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingBranches = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );

    if (picked == null) return;
    setState(() {
      _selectedDateRange = picked;
      _rentalDays = picked.duration.inDays;
      if (_rentalDays <= 0) {
        _rentalDays = 1;
      }
    });
  }

  List<OrderItem> _buildOrderItems(CartProvider cartProvider) {
    if (widget.product != null) {
      final rentalPrice = _asDouble(widget.product.rentalPricePerDay);
      final deposit = _asDouble(widget.product.depositAmount);

      return <OrderItem>[
        OrderItem(
          productId: (widget.product.id ?? '').toString(),
          productName: (widget.product.name ?? 'Sản phẩm thuê').toString(),
          thumbnailUrl: (widget.product.thumbnailUrl ?? '').toString(),
          selectedSize: (widget.selectedSize ?? 'Free').trim(),
          selectedColor: (widget.selectedColor ?? 'Mặc định').trim(),
          rentalPricePerDay: rentalPrice,
          depositAmount: deposit,
          quantity: 1,
          subtotal: rentalPrice * _rentalDays,
        ),
      ];
    }

    return cartProvider.cartItems.map((item) {
      return OrderItem(
        productId: item.productId,
        productName: item.productName,
        thumbnailUrl: item.imageUrl,
        selectedSize: item.selectedSize,
        selectedColor: item.selectedColor,
        rentalPricePerDay: item.rentalPricePerDay,
        depositAmount: item.depositPrice,
        quantity: item.quantity,
        subtotal: item.rentalPricePerDay * item.quantity * _rentalDays,
      );
    }).toList();
  }

  Future<void> _submitOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập trước khi đặt thuê.')),
      );
      return;
    }

    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian thuê.')),
      );
      return;
    }

    if (_selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn chi nhánh phục vụ.')),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đủ thông tin người nhận.')),
      );
      return;
    }

    final cartProvider = context.read<CartProvider>();
    if (widget.product == null && cartProvider.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giỏ hàng đang trống.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final items = _buildOrderItems(cartProvider);
      final totalRentalFee =
          items.fold<double>(0, (sum, item) => sum + item.subtotal);
      final totalDeposit = items.fold<double>(
        0,
        (sum, item) => sum + (item.depositAmount * item.quantity),
      );

      final order = OrderModel(
        id: '',
        userId: user.uid,
        branchId: _selectedBranch!.id,
        branchName: _selectedBranch!.name,
        branchAddress: _selectedBranch!.address,
        items: items,
        rentalStartDate: _selectedDateRange!.start,
        rentalEndDate: _selectedDateRange!.end,
        rentalDays: _rentalDays,
        totalRentalFee: totalRentalFee,
        depositPaid: totalDeposit,
        status: 'pending',
        deliveryAddress: _addressController.text.trim(),
        note:
            'Người nhận: ${_nameController.text.trim()} • SĐT: ${_phoneController.text.trim()}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final orderId = await _firebaseService.createOrder(order);

      if (widget.product == null) {
        cartProvider.clearCart();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo đơn thành công! Mã đơn: $orderId')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chốt đơn: $error')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProductList(CartProvider cartProvider) {
    if (widget.product != null) {
      final product = widget.product;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            (product.thumbnailUrl ?? '').toString(),
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, size: 50),
          ),
        ),
        title: Text(
          (product.name ?? 'Sản phẩm').toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Size: ${widget.selectedSize ?? 'Free'} | Màu: ${widget.selectedColor ?? 'Mặc định'}',
        ),
        trailing: Text(
          AppConstants.formatPrice(_asDouble(product.rentalPricePerDay)),
        ),
      );
    }

    return Column(
      children: cartProvider.cartItems.map((item) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported, size: 50),
            ),
          ),
          title: Text(
            item.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'Size: ${item.selectedSize} | Màu: ${item.selectedColor} x${item.quantity}',
          ),
          trailing: Text(
            AppConstants.formatPrice(item.rentalPricePerDay * item.quantity),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final double directRentalPrice = widget.product != null
        ? _asDouble(widget.product.rentalPricePerDay)
        : 0.0;
    final double directDepositPrice = widget.product != null
        ? _asDouble(widget.product.depositAmount)
        : 0.0;
    final double rentalBase = widget.product != null
        ? directRentalPrice
        : cartProvider.totalRentalPrice;
    final double depositBase = widget.product != null
        ? directDepositPrice
        : cartProvider.totalDepositPrice;
    final double displayRental = rentalBase * _rentalDays;

    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận đặt thuê')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Thời gian thuê',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: Text(
                      _selectedDateRange == null
                          ? 'Chọn ngày thuê và trả'
                          : '${_selectedDateRange!.start.toString().substring(0, 10)} đến ${_selectedDateRange!.end.toString().substring(0, 10)}',
                    ),
                    subtitle: Text('Số ngày thuê: $_rentalDays ngày'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _pickDateRange,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Thông tin sản phẩm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildProductList(cartProvider),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Thông tin nhận đồ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_isLoadingBranches)
                  const LinearProgressIndicator(minHeight: 3)
                else if (_branches.isEmpty)
                  const Text(
                    'Chưa có chi nhánh khả dụng.',
                    style: TextStyle(color: Colors.redAccent),
                  )
                else
                  DropdownButtonFormField<BranchModel>(
                    value: _selectedBranch,
                    decoration: const InputDecoration(
                      labelText: 'Chi nhánh phục vụ',
                      border: OutlineInputBorder(),
                    ),
                    items: _branches.map((branch) {
                      return DropdownMenuItem<BranchModel>(
                        value: branch,
                        child: Text(branch.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBranch = value;
                      });
                    },
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên người nhận',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ giao hàng (nếu có)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng tiền thuê:'),
                          Text(
                            AppConstants.formatPrice(displayRental),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tiền đặt cọc:'),
                          Text(
                            AppConstants.formatPrice(depositBase),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                    ),
                    child: const Text(
                      'Xác nhận thuê',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
