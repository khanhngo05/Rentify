import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../models/order_model.dart';
import '../services/firebase_service.dart';

/// Màn hình đặt thuê cho giỏ hàng có nhiều chi nhánh
/// Tự động tách thành nhiều đơn hàng theo chi nhánh
class MultiCartBookingScreen extends StatefulWidget {
  const MultiCartBookingScreen({
    super.key,
    this.directItems,
    this.removeDirectItemsOnSuccess = false,
  });

  final List<CartItemModel>? directItems;
  final bool removeDirectItemsOnSuccess;

  @override
  State<MultiCartBookingScreen> createState() => _MultiCartBookingScreenState();
}

class _MultiCartBookingScreenState extends State<MultiCartBookingScreen> {
  late DateTimeRange _rentalRange;
  String? _receiverName;
  String? _receiverPhone;
  String? _receiverAddress;
  bool _isSubmitting = false;

  bool get _hasReceiverInfo {
    return (_receiverName?.trim().isNotEmpty ?? false) &&
        (_receiverPhone?.trim().isNotEmpty ?? false) &&
        (_receiverAddress?.trim().isNotEmpty ?? false);
  }

  int get _rentalDays =>
      _rentalRange.end.difference(_rentalRange.start).inDays + 1;

  bool get _isDirectCheckout => widget.directItems != null;

  List<CartItemModel> _effectiveItems(CartProvider cartProvider) {
    return _isDirectCheckout ? widget.directItems! : cartProvider.cartItems;
  }

  Map<String, List<CartItemModel>> _groupItemsByBranch(
    List<CartItemModel> items,
  ) {
    final grouped = <String, List<CartItemModel>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.branchId, () => <CartItemModel>[]).add(item);
    }
    return grouped;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _rentalRange = DateTimeRange(start: today, end: today);
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _receiverName = data['displayName'] ?? '';
            _receiverPhone = data['phoneNumber'] ?? '';
            _receiverAddress = data['address'] ?? '';
          });
        }
      } catch (e) {
        debugPrint("Lỗi lấy thông tin user: $e");
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  Future<void> _showAddressDialog() async {
    final receiverInfo = await showDialog<_ReceiverInfo>(
      context: context,
      builder: (_) => _AddressInputDialog(
        initialName: _receiverName,
        initialPhone: _receiverPhone,
        initialAddress: _receiverAddress,
      ),
    );

    if (!mounted || receiverInfo == null) return;

    setState(() {
      _receiverName = receiverInfo.name;
      _receiverPhone = receiverInfo.phone;
      _receiverAddress = receiverInfo.address;
    });
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

    if (picked == null) return;

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

  Future<void> _submitOrders() async {
    if (!_hasReceiverInfo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin người nhận!'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt thuê!')),
      );
      return;
    }

    final cartProvider = context.read<CartProvider>();
    final bookingItems = _effectiveItems(cartProvider);
    if (bookingItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Giỏ hàng trống!')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final firebaseService = FirebaseService();
      final itemsByBranch = _groupItemsByBranch(bookingItems);
      final List<String> orderIds = [];

      // Tạo nhiều đơn hàng - mỗi chi nhánh 1 đơn
      for (var entry in itemsByBranch.entries) {
        final branchId = entry.key;
        final items = entry.value;

        // Tính tổng tiền cho đơn hàng này
        final branchRentalFee = items.fold<double>(
          0,
          (sum, item) =>
              sum + (item.rentalPricePerDay * item.quantity * _rentalDays),
        );
        final branchDeposit = items.fold<double>(
          0,
          (sum, item) => sum + (item.depositPrice * item.quantity),
        );

        // Chuyển đổi CartItems sang OrderItems
        final orderItems = items.map((cartItem) {
          return OrderItem(
            productId: cartItem.productId,
            productName: cartItem.productName,
            thumbnailUrl: cartItem.imageUrl,
            selectedSize: cartItem.selectedSize,
            selectedColor: cartItem.selectedColor,
            rentalPricePerDay: cartItem.rentalPricePerDay,
            depositAmount: cartItem.depositPrice,
            quantity: cartItem.quantity,
            subtotal: cartItem.rentalPricePerDay * cartItem.quantity,
          );
        }).toList();

        // Tạo OrderModel
        final order = OrderModel(
          id: '',
          userId: user.uid,
          branchId: branchId,
          branchName: items.first.branchName,
          branchAddress: items.first.branchAddress,
          items: orderItems,
          rentalStartDate: _rentalRange.start,
          rentalEndDate: _rentalRange.end,
          rentalDays: _rentalDays,
          totalRentalFee: branchRentalFee,
          depositPaid: branchDeposit,
          status: 'pending',
          deliveryAddress: _receiverAddress!,
          note: 'Người nhận: $_receiverName - SĐT: $_receiverPhone',
          createdAt: now,
          updatedAt: now,
        );

        // Tạo đơn trên Firestore
        final orderId = await firebaseService.createOrder(order);
        orderIds.add(orderId);
      }

      if (!mounted) return;

      // Luồng chọn item từ giỏ: chỉ xóa item đã đặt.
      if (_isDirectCheckout && widget.removeDirectItemsOnSuccess) {
        await cartProvider.removeItems(bookingItems);
      } else {
        await cartProvider.clearCart();
      }

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đặt thuê thành công ${orderIds.length} đơn hàng!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Quay về trang chủ
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đặt thuê: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final itemsByBranch = _groupItemsByBranch(_effectiveItems(cartProvider));

    double totalRentalFee = 0;
    double totalDeposit = 0;

    for (var items in itemsByBranch.values) {
      for (var item in items) {
        totalRentalFee += item.rentalPricePerDay * item.quantity * _rentalDays;
        totalDeposit += item.depositPrice * item.quantity;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận đặt thuê')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          // Địa chỉ nhận hàng
          GestureDetector(
            onTap: _showAddressDialog,
            child: _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Địa chỉ nhận đồ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_hasReceiverInfo) ...[
                    Text(
                      '$_receiverName  •  $_receiverPhone',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _receiverAddress!,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ] else
                    const Text(
                      'Chọn địa chỉ',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Thông tin chi nhánh + sản phẩm
          ...itemsByBranch.entries.map((entry) {
            final items = entry.value;
            final branchName = items.first.branchName;

            return Column(
              children: [
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            branchName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 64,
                                    height: 64,
                                    color: AppColors.shimmerBase,
                                    child: const Icon(
                                      Icons.image_not_supported_rounded,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Size: ${item.selectedSize} | Màu: ${item.selectedColor}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'SL: ${item.quantity} | ${AppConstants.formatPrice(item.rentalPricePerDay)}/ngày',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),

          // Thời gian thuê
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thời gian thuê',
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
                    FilledButton(
                      onPressed: _pickRentalRange,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Chọn lịch'),
                    ),
                  ],
                ),
                Text(
                  'Tổng số ngày thuê: $_rentalDays ngày',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tổng tiền
          _SectionCard(
            child: Column(
              children: [
                _PriceRow(
                  label: 'Tổng phí thuê ($_rentalDays ngày)',
                  value: AppConstants.formatPrice(totalRentalFee),
                ),
                _PriceRow(
                  label: 'Tổng tiền đặt cọc',
                  value: AppConstants.formatPrice(totalDeposit),
                ),
                const Divider(height: 20),
                _PriceRow(
                  label: 'Tổng cộng',
                  value: AppConstants.formatPrice(
                    totalRentalFee + totalDeposit,
                  ),
                  isEmphasized: true,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sẽ tạo ${itemsByBranch.length} đơn hàng riêng từ ${itemsByBranch.length} chi nhánh',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      'Tổng cộng',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      AppConstants.formatPrice(totalRentalFee + totalDeposit),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: _isSubmitting ? null : _submitOrders,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Đặt ${itemsByBranch.length} đơn'),
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

class _ReceiverInfo {
  const _ReceiverInfo({
    required this.name,
    required this.phone,
    required this.address,
  });
  final String name;
  final String phone;
  final String address;
}

class _AddressInputDialog extends StatefulWidget {
  const _AddressInputDialog({
    this.initialName,
    this.initialPhone,
    this.initialAddress,
  });
  final String? initialName;
  final String? initialPhone;
  final String? initialAddress;

  @override
  State<_AddressInputDialog> createState() => _AddressInputDialogState();
}

class _AddressInputDialogState extends State<_AddressInputDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _addressController = TextEditingController(
      text: widget.initialAddress ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      _ReceiverInfo(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thông tin nhận hàng'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập họ và tên'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập số điện thoại'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ nhận hàng',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập địa chỉ nhận hàng'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _save,
          child: const Text('Lưu'),
        ),
      ],
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
