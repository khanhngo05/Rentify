import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import 'cart_booking_screen.dart'; // Màn hình đặt thuê cho giỏ hàng
import 'multi_cart_booking_screen.dart'; // Màn hình đặt thuê nhiều chi nhánh

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _selectedItemKeys = <String>{};
  bool _didInitSelection = false;

  String _itemKey(CartItemModel item) {
    return '${item.productId}__${item.selectedSize}__${item.selectedColor}__${item.branchId}';
  }

  void _syncSelection(List<CartItemModel> cartItems) {
    final validKeys = cartItems.map(_itemKey).toSet();
    _selectedItemKeys.removeWhere((key) => !validKeys.contains(key));

    if (!_didInitSelection) {
      _selectedItemKeys.addAll(validKeys);
      _didInitSelection = true;
    }
  }

  Map<String, List<CartItemModel>> _groupByBranch(List<CartItemModel> items) {
    final grouped = <String, List<CartItemModel>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.branchId, () => <CartItemModel>[]).add(item);
    }
    return grouped;
  }

  Future<bool> _confirmRemoveItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa sản phẩm này khỏi giỏ hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _goCheckout(
    BuildContext context,
    List<CartItemModel> selectedItems,
  ) async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sản phẩm muốn thuê!')),
      );
      return;
    }

    final selectedItemsByBranch = _groupByBranch(selectedItems);
    final hasMultipleSelectedBranches = selectedItemsByBranch.length > 1;

    if (hasMultipleSelectedBranches) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MultiCartBookingScreen(
            directItems: selectedItems,
            removeDirectItemsOnSuccess: true,
          ),
        ),
      );
      return;
    }

    final first = selectedItems.first;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartBookingScreen(
          branchId: first.branchId,
          branchName: first.branchName,
          branchAddress: first.branchAddress,
          directItems: selectedItems,
          removeDirectItemsOnSuccess: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Giỏ hàng')),
      // Dùng Consumer để lắng nghe sự thay đổi từ CartProvider
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final cartItems = cartProvider.cartItems;
          _syncSelection(cartItems);

          if (cartItems.isEmpty) {
            return const Center(
              child: Text(
                'Giỏ hàng của bạn đang trống!',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final groupedCartItems = _groupByBranch(cartItems);
          final selectedItems = cartItems
              .where((item) => _selectedItemKeys.contains(_itemKey(item)))
              .toList();
          final selectedItemsByBranch = _groupByBranch(selectedItems);
          final selectedRentalPrice = selectedItems.fold<double>(
            0,
            (sum, item) => sum + item.totalItemRental,
          );
          final selectedDepositPrice = selectedItems.fold<double>(
            0,
            (sum, item) => sum + item.totalItemDeposit,
          );
          final selectedGrandTotal = selectedRentalPrice + selectedDepositPrice;
          final isSelectAll =
              selectedItems.isNotEmpty &&
              selectedItems.length == cartItems.length;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  itemCount: groupedCartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = groupedCartItems.entries.elementAt(index);
                    final branchItems = entry.value;
                    final branchKeys = branchItems.map(_itemKey).toList();
                    final selectedInBranch = branchKeys
                        .where(_selectedItemKeys.contains)
                        .length;
                    final isAllInBranch =
                        selectedInBranch == branchItems.length;
                    final isSomeInBranch =
                        selectedInBranch > 0 && !isAllInBranch;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 10, 10, 8),
                            child: Row(
                              children: [
                                Checkbox(
                                  tristate: true,
                                  value: isAllInBranch
                                      ? true
                                      : (isSomeInBranch ? null : false),
                                  onChanged: (_) {
                                    setState(() {
                                      if (isAllInBranch) {
                                        _selectedItemKeys.removeAll(branchKeys);
                                      } else {
                                        _selectedItemKeys.addAll(branchKeys);
                                      }
                                    });
                                  },
                                ),
                                const Icon(
                                  Icons.storefront_outlined,
                                  size: 17,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    branchItems.first.branchName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${selectedInBranch}/${branchItems.length}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ...branchItems.map((item) {
                            final itemKey = _itemKey(item);
                            final isSelected = _selectedItemKeys.contains(
                              itemKey,
                            );

                            return Padding(
                              padding: const EdgeInsets.fromLTRB(6, 10, 10, 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedItemKeys.add(itemKey);
                                        } else {
                                          _selectedItemKeys.remove(itemKey);
                                        }
                                      });
                                    },
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      item.imageUrl,
                                      width: 86,
                                      height: 86,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 86,
                                        height: 86,
                                        color: AppColors.divider,
                                        child: const Icon(
                                          Icons.image_not_supported_rounded,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            height: 1.3,
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
                                        const SizedBox(height: 4),
                                        Text(
                                          AppConstants.formatPrice(
                                            item.rentalPricePerDay,
                                          ),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              onPressed: () async {
                                                if (item.quantity == 1) {
                                                  final confirmed =
                                                      await _confirmRemoveItem();
                                                  if (!confirmed) return;

                                                  await cartProvider
                                                      .removeFromCart(
                                                        item.productId,
                                                        item.selectedSize,
                                                        item.selectedColor,
                                                        item.branchId,
                                                      );
                                                  if (mounted) {
                                                    setState(() {
                                                      _selectedItemKeys.remove(
                                                        itemKey,
                                                      );
                                                    });
                                                  }
                                                  return;
                                                }

                                                await cartProvider
                                                    .updateQuantity(
                                                      item.productId,
                                                      item.selectedSize,
                                                      item.selectedColor,
                                                      item.branchId,
                                                      false,
                                                    );
                                              },
                                            ),
                                            Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.add_circle_outline,
                                                color:
                                                    item.quantity >=
                                                        item.availableStock
                                                    ? Colors.grey
                                                    : null,
                                              ),
                                              onPressed:
                                                  item.quantity >=
                                                      item.availableStock
                                                  ? null
                                                  : () async {
                                                      final success =
                                                          await cartProvider
                                                              .updateQuantity(
                                                                item.productId,
                                                                item.selectedSize,
                                                                item.selectedColor,
                                                                item.branchId,
                                                                true,
                                                              );

                                                      if (!success &&
                                                          context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Đã đạt số lượng tồn kho tối đa!',
                                                            ),
                                                            duration: Duration(
                                                              seconds: 2,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: AppColors.error,
                                              ),
                                              onPressed: () async {
                                                final confirmed =
                                                    await _confirmRemoveItem();
                                                if (!confirmed) return;

                                                await cartProvider
                                                    .removeFromCart(
                                                      item.productId,
                                                      item.selectedSize,
                                                      item.selectedColor,
                                                      item.branchId,
                                                    );
                                                if (mounted) {
                                                  setState(() {
                                                    _selectedItemKeys.remove(
                                                      itemKey,
                                                    );
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (selectedItemsByBranch.length > 1)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đã chọn ${selectedItemsByBranch.length} chi nhánh. Hệ thống sẽ tách thành ${selectedItemsByBranch.length} đơn riêng.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelectAll,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedItemKeys
                              ..clear()
                              ..addAll(cartItems.map(_itemKey));
                          } else {
                            _selectedItemKeys.clear();
                          }
                        });
                      },
                    ),
                    const Text('Tất cả'),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppConstants.formatPrice(selectedGrandTotal),
                              maxLines: 1,
                              softWrap: false,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            'Thuê: ${AppConstants.formatPrice(selectedRentalPrice)} | Cọc: ${AppConstants.formatPrice(selectedDepositPrice)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _goCheckout(context, selectedItems),
                        child: Text('Mua hàng (${selectedItems.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
