import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../services/admin_service.dart';

/// Màn hình quản lý đơn hàng
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  List<OrderModel> _allOrders = [];
  bool _isLoading = true;

  final List<String> _statuses = [
    'all',
    'pending',
    'confirmed',
    'renting',
    'returned',
    'completed',
    'cancelled',
  ];

  final Map<String, String> _statusLabels = {
    'all': 'Tất cả',
    'pending': 'Chờ xác nhận',
    'confirmed': 'Đã xác nhận',
    'renting': 'Đang thuê',
    'returned': 'Đã trả',
    'completed': 'Hoàn thành',
    'cancelled': 'Đã hủy',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _adminService.getAllOrders();
      setState(() {
        _allOrders = orders;
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

  List<OrderModel> _getFilteredOrders(String status) {
    if (status == 'all') return _allOrders;
    return _allOrders.where((o) => o.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: _statuses.map((s) {
              final count = _getFilteredOrders(s).length;
              return Tab(
                child: Row(
                  children: [
                    Text(_statusLabels[s]!),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: s == 'pending'
                              ? AppColors.warning
                              : AppColors.textHint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: _statuses.map((status) {
                    final orders = _getFilteredOrders(status);
                    if (orders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64, color: AppColors.textHint),
                            const SizedBox(height: 16),
                            Text(
                              'Không có đơn hàng',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderItem(orders[index]);
                        },
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(OrderModel order) {
    final statusColor = AppColors.getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetail(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppConstants.getStatusName(order.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Items preview
              Row(
                children: [
                  // Product images
                  SizedBox(
                    width: 80,
                    height: 50,
                    child: Stack(
                      children: order.items.take(3).toList().asMap().entries.map((e) {
                        return Positioned(
                          left: e.key * 20.0,
                          child: Container(
                            width: 40,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: e.value.thumbnailUrl.isNotEmpty
                                  ? Image.network(
                                      e.value.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(color: AppColors.shimmerBase),
                                    )
                                  : Container(color: AppColors.shimmerBase),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.totalItemCount} sản phẩm',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.branchName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppConstants.formatPrice(order.totalRentalFee),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${order.rentalDays} ngày',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(order.rentalStartDate)} - ${_formatDate(order.rentalEndDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (order.status == 'pending' ||
                      order.status == 'confirmed' ||
                      order.status == 'renting' ||
                      order.status == 'returned')
                    TextButton(
                      onPressed: () => _showStatusChangeDialog(order),
                      child: const Text('Cập nhật'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showOrderDetail(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    const Text(
                      'Chi tiết đơn hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.getStatusColor(order.status)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        AppConstants.getStatusName(order.status),
                        style: TextStyle(
                          color: AppColors.getStatusColor(order.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Mã: #${order.id.toUpperCase()}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),

                const Divider(height: 32),

                // Branch info
                _buildDetailRow(Icons.store, 'Chi nhánh', order.branchName),
                _buildDetailRow(
                    Icons.location_on, 'Địa chỉ CN', order.branchAddress),

                const Divider(height: 24),

                // Rental dates
                _buildDetailRow(Icons.date_range, 'Ngày thuê',
                    '${_formatDate(order.rentalStartDate)} - ${_formatDate(order.rentalEndDate)}'),
                _buildDetailRow(
                    Icons.timelapse, 'Số ngày', '${order.rentalDays} ngày'),

                const Divider(height: 24),

                // Delivery address
                _buildDetailRow(
                    Icons.local_shipping, 'Giao đến', order.deliveryAddress),
                if (order.note != null && order.note!.isNotEmpty)
                  _buildDetailRow(Icons.note, 'Ghi chú', order.note!),

                const Divider(height: 24),

                // Items
                const Text(
                  'Sản phẩm',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...order.items.map((item) => _buildOrderItemDetail(item)),

                const Divider(height: 24),

                // Totals
                _buildPriceRow('Phí thuê', order.totalRentalFee),
                _buildPriceRow('Tiền cọc', order.depositPaid),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      AppConstants.formatPrice(
                          order.totalRentalFee + order.depositPaid),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Actions
                if (order.status != 'completed' && order.status != 'cancelled')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showStatusChangeDialog(order);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cập nhật trạng thái'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemDetail(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.thumbnailUrl.isNotEmpty
                ? Image.network(
                    item.thumbnailUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: AppColors.shimmerBase,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: ${item.selectedSize} | Màu: ${item.selectedColor}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppConstants.formatPrice(item.rentalPricePerDay)}/ngày × ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(AppConstants.formatPrice(amount)),
        ],
      ),
    );
  }

  void _showStatusChangeDialog(OrderModel order) {
    String? nextStatus;
    
    switch (order.status) {
      case 'pending':
        nextStatus = 'confirmed';
        break;
      case 'confirmed':
        nextStatus = 'renting';
        break;
      case 'renting':
        nextStatus = 'returned';
        break;
      case 'returned':
        nextStatus = 'completed';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật trạng thái'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Đơn hàng: #${order.id.substring(0, 8).toUpperCase()}'),
            const SizedBox(height: 16),
            if (nextStatus != null)
              ListTile(
                leading: Icon(Icons.arrow_forward,
                    color: AppColors.getStatusColor(nextStatus)),
                title: Text(AppConstants.getStatusName(nextStatus)),
                subtitle: const Text('Chuyển sang trạng thái tiếp theo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateStatus(order.id, nextStatus!);
                },
              ),
            if (order.status != 'cancelled' && order.status != 'completed')
              ListTile(
                leading: const Icon(Icons.cancel, color: AppColors.error),
                title: const Text('Hủy đơn',
                    style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateStatus(order.id, 'cancelled');
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await _adminService.updateOrderStatus(orderId, newStatus);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Đã cập nhật sang "${AppConstants.getStatusName(newStatus)}"'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}
