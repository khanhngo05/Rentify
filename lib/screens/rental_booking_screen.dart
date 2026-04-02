import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/product_model.dart';
import '../controllers/cart_controller.dart';
import 'cart_screen.dart'; // Thêm dòng import này để chuyển trang
import 'cart_screen.dart';

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
  String? _receiverName;
  String? _receiverPhone;
  String? _receiverAddress;

  bool get _hasReceiverInfo {
    return (_receiverName?.trim().isNotEmpty ?? false) &&
        (_receiverPhone?.trim().isNotEmpty ?? false) &&
        (_receiverAddress?.trim().isNotEmpty ?? false);
  }

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

  @override
  Widget build(BuildContext context) {
    final rentalFee = widget.product.rentalPricePerDay * _rentalDays;
    final total = rentalFee + widget.product.depositAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Thuê ngay')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
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
                      '${_receiverName!}  •  ${_receiverPhone!}',
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
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sản phẩm thuê',
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
                            'Size: ${widget.selectedSize.isEmpty ? 'Chưa chọn' : widget.selectedSize}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Màu: ${widget.selectedColor.isEmpty ? 'Chưa chọn' : widget.selectedColor}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
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
          _SectionCard(
            child: Column(
              children: [
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
                const Divider(height: 20),
                _PriceRow(
                  label: 'Tổng tạm tính',
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
                      'Tổng cộng',
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
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    // 1. Kiểm tra xem người dùng đã nhập thông tin nhận hàng chưa
                    if (!_hasReceiverInfo) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng chọn địa chỉ nhận đồ ở phía trên!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // 2. Map dữ liệu vào CartItem
                    // Lưu ý: Đảm bảo 'id' là tên thuộc tính đúng trong Product model của P1. 
                    // Nếu P1 đặt tên là 'productId' hay gì khác thì bạn sửa lại nhé.
                    final newItem = CartItem(
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
                    );

                    // 3. Đẩy vào Giỏ hàng toàn cục
                    cartController.addToCart(newItem);

                    // 4. Chuyển hướng sang màn hình Giỏ hàng
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  child: const Text('Đặt thuê'),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ nhận hàng',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập địa chỉ nhận hàng';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
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