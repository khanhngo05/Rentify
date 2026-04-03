import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/order_model.dart';
import '../services/firebase_service.dart';

class RentalHistoryPage extends StatefulWidget {
  const RentalHistoryPage({super.key, required this.userId});

  final String userId;

  @override
  State<RentalHistoryPage> createState() => _RentalHistoryPageState();
}

class _RentalHistoryPageState extends State<RentalHistoryPage> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _firebaseService.getOrdersByUser(widget.userId);
  }

  Future<void> _reload() async {
    setState(() {
      _ordersFuture = _firebaseService.getOrdersByUser(widget.userId);
    });
    await _ordersFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử thuê')),
      body: FutureBuilder<List<OrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorView(
              onRetry: _reload,
              errorText: snapshot.error.toString(),
            );
          }

          final orders = snapshot.data ?? <OrderModel>[];
          if (orders.isEmpty) {
            return _EmptyView(onRefresh: _reload);
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                return _OrderHistoryCard(order: orders[index]);
              },
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemCount: orders.length,
            ),
          );
        },
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getStatusColor(order.status);
    final dateFormat = DateFormat(AppConstants.dateFormat);
    final orderCode = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Đơn #$orderCode',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
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
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.storefront_outlined,
              text: order.branchName.isEmpty ? 'Chi nhánh chưa xác định' : order.branchName,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: order.branchAddress.isEmpty ? 'Chưa có địa chỉ chi nhánh' : order.branchAddress,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.calendar_month_outlined,
              text:
                  '${dateFormat.format(order.rentalStartDate)} - ${dateFormat.format(order.rentalEndDate)} (${order.rentalDays} ngày)',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: 'Sản phẩm',
                    value: '${order.totalItemCount}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryTile(
                    label: 'Tổng thuê',
                    value: AppConstants.formatPrice(order.totalRentalFee),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryTile(
                    label: 'Đặt cọc',
                    value: AppConstants.formatPrice(order.depositPaid),
                  ),
                ),
              ],
            ),
            if (order.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                _buildItemPreview(order.items),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if ((order.note ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ghi chú: ${order.note!.trim()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildItemPreview(List<OrderItem> items) {
    const previewLimit = 2;
    final firstNames = items
        .take(previewLimit)
        .map((item) => item.productName)
        .where((name) => name.trim().isNotEmpty)
        .toList();

    if (firstNames.isEmpty) {
      return 'Không có thông tin sản phẩm.';
    }

    if (items.length <= previewLimit) {
      return firstNames.join(', ');
    }

    final remaining = math.max(0, items.length - previewLimit);
    return '${firstNames.join(', ')} và $remaining sản phẩm khác';
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.history_toggle_off_rounded,
                    size: 56,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có đơn thuê nào',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Khi có đơn thuê mới, lịch sử sẽ hiển thị tại đây.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry, required this.errorText});

  final Future<void> Function() onRetry;
  final String errorText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Không thể tải lịch sử thuê',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              errorText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
