import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/branch_model.dart';
import '../../models/product_model.dart';
import '../../services/admin_service.dart';

/// Màn hình quản lý tồn kho của chi nhánh
class AdminBranchInventoryScreen extends StatefulWidget {
  final BranchModel branch;

  const AdminBranchInventoryScreen({super.key, required this.branch});

  @override
  State<AdminBranchInventoryScreen> createState() =>
      _AdminBranchInventoryScreenState();
}

class _AdminBranchInventoryScreenState
    extends State<AdminBranchInventoryScreen> {
  final AdminService _adminService = AdminService();

  List<BranchInventory> _inventory = [];
  List<Product> _allProducts = [];
  Map<String, Product> _productMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final inventory = await _adminService.getBranchInventory(widget.branch.id);
      final products = await _adminService.getAllProducts();

      final productMap = <String, Product>{};
      for (final p in products) {
        productMap[p.id] = p;
      }

      setState(() {
        _inventory = inventory;
        _allProducts = products.where((p) => p.isActive).toList();
        _productMap = productMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tồn kho: ${widget.branch.name}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddInventoryDialog,
            tooltip: 'Thêm sản phẩm vào kho',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _inventory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có sản phẩm trong kho',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddInventoryDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm sản phẩm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _inventory.length,
                    itemBuilder: (context, index) {
                      return _buildInventoryItem(_inventory[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildInventoryItem(BranchInventory item) {
    final product = _productMap[item.productId];
    if (product == null) {
      return const SizedBox.shrink();
    }

    final isLowStock = item.availableStock <= 2 && item.availableStock > 0;
    final isOutOfStock = item.availableStock == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.thumbnailUrl.isNotEmpty
                  ? Image.network(
                      product.thumbnailUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 12),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.getCategoryName(product.category),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Stock info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? AppColors.error.withOpacity(0.1)
                        : isLowStock
                            ? AppColors.warning.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.availableStock}/${item.totalStock}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOutOfStock
                          ? AppColors.error
                          : isLowStock
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOutOfStock
                      ? 'Hết hàng'
                      : isLowStock
                          ? 'Sắp hết'
                          : 'Còn hàng',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOutOfStock
                        ? AppColors.error
                        : isLowStock
                            ? AppColors.warning
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Edit button
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditInventoryDialog(item, product),
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.checkroom, color: Colors.white),
    );
  }

  void _showAddInventoryDialog() {
    // Get products not in inventory
    final existingIds = _inventory.map((i) => i.productId).toSet();
    final availableProducts =
        _allProducts.where((p) => !existingIds.contains(p.id)).toList();

    if (availableProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm tất cả sản phẩm vào kho')),
      );
      return;
    }

    Product? selectedProduct;
    final totalController = TextEditingController(text: '10');
    final availableController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm sản phẩm vào kho'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Product>(
                  value: selectedProduct,
                  decoration: const InputDecoration(
                    labelText: 'Chọn sản phẩm',
                    border: OutlineInputBorder(),
                  ),
                  items: availableProducts.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setDialogState(() => selectedProduct = v);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalController,
                        decoration: const InputDecoration(
                          labelText: 'Tổng kho',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: availableController,
                        decoration: const InputDecoration(
                          labelText: 'Còn trống',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: selectedProduct == null
                  ? null
                  : () async {
                      final total = int.tryParse(totalController.text) ?? 0;
                      final available =
                          int.tryParse(availableController.text) ?? 0;

                      if (total <= 0 || available < 0 || available > total) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Số lượng không hợp lệ')),
                        );
                        return;
                      }

                      Navigator.pop(context);

                      try {
                        await _adminService.updateInventory(
                          widget.branch.id,
                          selectedProduct!.id,
                          total,
                          available,
                        );
                        _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã thêm vào kho')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditInventoryDialog(BranchInventory item, Product product) {
    final totalController =
        TextEditingController(text: item.totalStock.toString());
    final availableController =
        TextEditingController(text: item.availableStock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật: ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: totalController,
              decoration: const InputDecoration(
                labelText: 'Tổng kho',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: availableController,
              decoration: const InputDecoration(
                labelText: 'Còn trống',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final total = int.tryParse(totalController.text) ?? 0;
              final available = int.tryParse(availableController.text) ?? 0;

              if (total <= 0 || available < 0 || available > total) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Số lượng không hợp lệ')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await _adminService.updateInventory(
                  widget.branch.id,
                  item.productId,
                  total,
                  available,
                );
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }
}
