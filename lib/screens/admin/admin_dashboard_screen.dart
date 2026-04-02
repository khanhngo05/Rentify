import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../services/admin_service.dart';

/// Màn hình Dashboard thống kê tổng quan cho Admin
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _topProducts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _adminService.getDashboardStats();
      final topProducts = await _adminService.getTopProducts(limit: 5);
      
      setState(() {
        _stats = stats;
        _topProducts = topProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thống kê doanh thu
            _buildSectionTitle('💰 Doanh thu'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Hôm nay',
                    AppConstants.formatPrice(_stats['todayRevenue'] ?? 0),
                    Icons.today,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Tháng này',
                    AppConstants.formatPrice(_stats['monthlyRevenue'] ?? 0),
                    Icons.calendar_month,
                    AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Tổng doanh thu',
              AppConstants.formatPrice(_stats['totalRevenue'] ?? 0),
              Icons.account_balance_wallet,
              AppColors.primary,
              fullWidth: true,
            ),

            const SizedBox(height: 24),

            // Thống kê đơn hàng
            _buildSectionTitle('📦 Đơn hàng'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tổng đơn',
                    '${_stats['totalOrders'] ?? 0}',
                    Icons.receipt,
                    AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Chờ xác nhận',
                    '${_stats['pendingOrders'] ?? 0}',
                    Icons.pending_actions,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Đang thuê',
                    '${_stats['rentingOrders'] ?? 0}',
                    Icons.shopping_bag,
                    AppColors.statusRenting,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Hoàn thành',
                    '${_stats['completedOrders'] ?? 0}',
                    Icons.check_circle,
                    AppColors.statusCompleted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Thống kê tổng quan
            _buildSectionTitle('📊 Tổng quan'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Sản phẩm',
                    '${_stats['totalProducts'] ?? 0}',
                    Icons.checkroom,
                    AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Chi nhánh',
                    '${_stats['totalBranches'] ?? 0}',
                    Icons.store,
                    AppColors.primaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Người dùng',
                    '${_stats['totalUsers'] ?? 0}',
                    Icons.people,
                    AppColors.info,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Top sản phẩm
            _buildSectionTitle('🔥 Top sản phẩm được thuê'),
            const SizedBox(height: 12),
            if (_topProducts.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có dữ liệu'),
                ),
              )
            else
              ..._topProducts.asMap().entries.map((entry) {
                final index = entry.key;
                final product = entry.value;
                return _buildTopProductItem(
                  index + 1,
                  product['productName'] ?? '',
                  product['thumbnailUrl'] ?? '',
                  product['rentalCount'] ?? 0,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: fullWidth ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductItem(
    int rank,
    String name,
    String imageUrl,
    int rentalCount,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: rank <= 3 ? AppColors.star : AppColors.textHint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: AppColors.shimmerBase,
                        child: const Icon(Icons.image, color: Colors.white),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: AppColors.shimmerBase,
                      child: const Icon(Icons.checkroom, color: Colors.white),
                    ),
            ),
          ],
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$rentalCount lượt',
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
