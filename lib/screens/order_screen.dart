import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({
    super.key,
    this.initialStatusCode = 'pending',
    this.appBarTitle = 'Đơn hàng',
    this.loginRequiredMessage = 'Bạn cần đăng nhập để xem đơn hàng.',
    this.emptyMessage = 'Bạn chưa có đơn hàng nào',
  });

  final String initialStatusCode;
  final String appBarTitle;
  final String loginRequiredMessage;
  final String emptyMessage;

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  static const List<_StatusTab> _tabs = <_StatusTab>[
    _StatusTab('pending', 'Chờ xác nhận'),
    _StatusTab('confirmed', 'Đã xác nhận'),
    _StatusTab('renting', 'Đang thuê'),
    _StatusTab('returned', 'Đã trả'),
    _StatusTab('completed', 'Hoàn thành'),
    _StatusTab('cancelled', 'Đã hủy'),
  ];

  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  late final TabController _tabController;
  Future<List<OrderModel>>? _ordersFuture;
  String? _uid;

  @override
  void initState() {
    super.initState();
    final initialIndex = _tabs.indexWhere(
      (tab) => tab.code == widget.initialStatusCode,
    );
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex == -1 ? 0 : initialIndex,
    );
    _uid = _authService.currentUser?.uid;
    if (_uid != null) {
      _ordersFuture = _firebaseService.getOrdersByUser(_uid!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final uid = _uid;
    if (uid == null) return;
    setState(() {
      _ordersFuture = _firebaseService.getOrdersByUser(uid);
    });
    await _ordersFuture;
  }

  Map<String, List<OrderModel>> _group(List<OrderModel> orders) {
    final map = <String, List<OrderModel>>{
      for (final tab in _tabs) tab.code: <OrderModel>[],
    };
    for (final order in orders) {
      if (map.containsKey(order.status)) {
        map[order.status]!.add(order);
      }
    }
    for (final entry in map.values) {
      entry.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return map;
  }

  bool _canCancel(OrderModel order) => order.status == 'pending';

  Future<bool> _cancelOrder(OrderModel order) async {
    if (!_canCancel(order)) return false;
    try {
      await _firebaseService.updateOrderStatus(order.id, 'cancelled');
      if (!mounted) return true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã hủy đơn hàng.')));
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể hủy đơn: $error')),
      );
      return false;
    }
  }

  Future<void> _showOrderDetail(OrderModel order) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Chi tiết đơn #${_code(order.id)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _detailRow('Trạng thái', AppConstants.getStatusName(order.status)),
                _detailRow('Chi nhánh', order.branchName),
                _detailRow('Địa chỉ', order.branchAddress),
                _detailRow(
                  'Thời gian',
                  '${_date(order.rentalStartDate)} - ${_date(order.rentalEndDate)}',
                ),
                _detailRow('Số ngày', '${order.rentalDays} ngày'),
                _detailRow(
                  'Nơi nhận đồ',
                  order.deliveryAddress.trim().isEmpty
                      ? 'Chưa có thông tin'
                      : order.deliveryAddress,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sản phẩm',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.productName),
                    subtitle: Text(
                      'Size: ${item.selectedSize} • Màu: ${item.selectedColor}',
                    ),
                    trailing: Text(
                      '${AppConstants.formatPrice(item.rentalPricePerDay)}/ngày x ${item.quantity}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const Divider(),
                _detailRow(
                  'Tổng tiền thuê',
                  AppConstants.formatPrice(order.totalRentalFee),
                ),
                _detailRow('Đặt cọc', AppConstants.formatPrice(order.depositPaid)),
                _detailRow(
                  'Tổng cộng',
                  AppConstants.formatPrice(order.totalRentalFee + order.depositPaid),
                ),
                const SizedBox(height: 12),
                if (_canCancel(order))
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Xác nhận hủy đơn'),
                            content: Text('Bạn muốn hủy đơn #${_code(order.id)}?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(false),
                                child: const Text('Không'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                ),
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(true),
                                child: const Text('Hủy đơn'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true) return;
                        final cancelled = await _cancelOrder(order);
                        if (!mounted || !cancelled) return;
                        Navigator.of(context).pop(true);
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy đơn'),
                    ),
                  )
                else
                  const Text(
                    'Đơn đang xử lý hoặc đã hoàn tất, chỉ có thể xem chi tiết.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (updated == true && mounted) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.appBarTitle)),
        body: Center(
          child: Text(widget.loginRequiredMessage),
        ),
      );
    }

    final ordersFuture = _ordersFuture;
    if (ordersFuture == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: FutureBuilder<List<OrderModel>>(
        future: ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error),
                  const SizedBox(height: 8),
                  const Text('Không thể tải đơn hàng'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final grouped = _group(snapshot.data ?? const <OrderModel>[]);
          final hasAnyOrder = grouped.values.any((list) => list.isNotEmpty);
          if (!hasAnyOrder) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 240),
                  Center(child: Text(widget.emptyMessage)),
                ],
              ),
            );
          }

          return Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: _tabs.map((tab) => Tab(text: tab.label)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) {
                    final orders = grouped[tab.code] ?? const <OrderModel>[];
                    if (orders.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 240),
                            Center(child: Text('Chưa có đơn "${tab.label}"')),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Card(
                            child: ListTile(
                              onTap: () => _showOrderDetail(order),
                              title: Text('Đơn #${_code(order.id)}'),
                              subtitle: Text(
                                '${_date(order.rentalStartDate)} - ${_date(order.rentalEndDate)}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(AppConstants.getStatusName(order.status)),
                                  Text(
                                    AppConstants.formatPrice(order.totalRentalFee),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(child: Text(value.trim().isEmpty ? 'Chưa có thông tin' : value)),
        ],
      ),
    );
  }
}

class _StatusTab {
  const _StatusTab(this.code, this.label);
  final String code;
  final String label;
}

String _date(DateTime value) {
  return DateFormat(AppConstants.dateFormat).format(value);
}

String _code(String id) {
  if (id.length > 8) return id.substring(0, 8).toUpperCase();
  return id.toUpperCase();
}
