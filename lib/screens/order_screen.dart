import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/order_model.dart';
import '../models/review_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({
    super.key,
    this.initialStatusCode = 'pending',
    this.appBarTitle = 'Đơn hàng',
    this.loginRequiredMessage = 'Bạn cần đăng nhập để xem đơn hàng.',
    this.emptyMessage = 'Bạn chưa có đơn hàng nào',
    this.refreshSignal = 0,
  });

  final String initialStatusCode;
  final String appBarTitle;
  final String loginRequiredMessage;
  final String emptyMessage;
  final int refreshSignal;

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
  StreamSubscription<User?>? _authSubscription;
  Future<List<OrderModel>>? _ordersFuture;
  String? _uid;

  final Map<String, bool> _reviewedByOrderItem = <String, bool>{};
  final Set<String> _reviewCheckingKeys = <String>{};
  final Set<String> _reviewSubmittingKeys = <String>{};
  final Set<String> _reviewCheckQueuedKeys = <String>{};

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

    _syncUserAndLoad(_authService.currentUser?.uid);
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (!mounted) return;
      _syncUserAndLoad(user?.uid);
    });
  }

  @override
  void didUpdateWidget(covariant OrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshSignal == oldWidget.refreshSignal) return;
    _reload();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _syncUserAndLoad(String? uid) {
    final shouldResetCaches = _uid != uid;
    setState(() {
      _uid = uid;
      _ordersFuture = uid == null ? null : _firebaseService.getOrdersByUser(uid);
      if (shouldResetCaches) {
        _reviewedByOrderItem.clear();
        _reviewCheckingKeys.clear();
        _reviewSubmittingKeys.clear();
        _reviewCheckQueuedKeys.clear();
      }
    });
  }

  Future<void> _reload() async {
    final uid = _authService.currentUser?.uid ?? _uid;
    if (uid == null) return;
    setState(() {
      _uid = uid;
      _ordersFuture = _firebaseService.getOrdersByUser(uid);
      _reviewCheckingKeys.clear();
      _reviewSubmittingKeys.clear();
      _reviewCheckQueuedKeys.clear();
    });
    await _ordersFuture;
  }

  String _reviewKey(String orderId, String productId) {
    return '$orderId::$productId';
  }

  Future<String> _resolveCurrentUserName(String uid) async {
    final authName = _authService.currentUser?.displayName?.trim() ?? '';
    if (authName.isNotEmpty) return authName;

    try {
      final user = await _firebaseService.getUserById(uid);
      final profileName = user?.displayName.trim() ?? '';
      if (profileName.isNotEmpty) return profileName;
    } catch (_) {}

    return 'Người dùng';
  }

  void _ensureReviewState(OrderModel order, OrderItem item) {
    if (order.status != 'completed') return;
    final uid = _uid;
    if (uid == null) return;

    final key = _reviewKey(order.id, item.productId);
    if (_reviewedByOrderItem.containsKey(key) ||
        _reviewCheckingKeys.contains(key) ||
        _reviewCheckQueuedKeys.contains(key)) {
      return;
    }

    _reviewCheckQueuedKeys.add(key);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _reviewCheckQueuedKeys.remove(key);
        return;
      }

      if (_reviewedByOrderItem.containsKey(key) || _reviewCheckingKeys.contains(key)) {
        _reviewCheckQueuedKeys.remove(key);
        return;
      }

      setState(() {
        _reviewCheckingKeys.add(key);
      });

      _firebaseService
          .hasReviewForOrderItem(
            userId: uid,
            orderId: order.id,
            productId: item.productId,
          )
          .timeout(const Duration(seconds: 12))
          .then((hasReviewed) {
            if (!mounted) return;
            setState(() {
              _reviewedByOrderItem[key] = hasReviewed;
              _reviewCheckingKeys.remove(key);
            });
          })
          .catchError((_) {
            if (!mounted) return;
            setState(() {
              _reviewCheckingKeys.remove(key);
            });
          })
          .whenComplete(() {
            _reviewCheckQueuedKeys.remove(key);
          });
    });
  }

  Future<void> _showReviewDialogForItem(OrderModel order, OrderItem item) async {
    if (order.status != 'completed') return;
    final uid = _uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá.')),
      );
      return;
    }

    final key = _reviewKey(order.id, item.productId);
    if (_reviewedByOrderItem[key] == true || _reviewSubmittingKeys.contains(key)) {
      return;
    }

    final draft = await showDialog<_ReviewDraft>(
      context: context,
      builder: (_) => _ReviewInputDialog(productName: item.productName),
    );
    if (draft == null) return;

    setState(() {
      _reviewSubmittingKeys.add(key);
    });

    try {
      final displayName = await _resolveCurrentUserName(uid);
      final review = ReviewModel(
        id: '',
        productId: item.productId,
        branchId: order.branchId,
        userId: uid,
        orderId: order.id,
        rating: draft.rating,
        comment: draft.comment?.trim().isEmpty == true
            ? null
            : draft.comment?.trim(),
        userDisplayName: displayName,
        photoUrls: const <String>[],
        createdAt: DateTime.now(),
      );

      await _firebaseService.createReview(review);
      if (!mounted) return;
      setState(() {
        _reviewedByOrderItem[key] = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi đánh giá cho "${item.productName}".')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      if (error.code == 'already-exists') {
        setState(() {
          _reviewedByOrderItem[key] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sản phẩm này đã được đánh giá rồi.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Không thể gửi đánh giá.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi đánh giá lúc này.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _reviewSubmittingKeys.remove(key);
      });
    }
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
    for (final list in map.values) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể hủy đơn: $error')));
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
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.thumbnailUrl.trim().isEmpty
                          ? Container(
                              width: 48,
                              height: 48,
                              color: AppColors.surfaceVariant,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_rounded,
                                size: 16,
                              ),
                            )
                          : Image.network(
                              item.thumbnailUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: AppColors.surfaceVariant,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 16,
                                ),
                              ),
                            ),
                    ),
                    title: Text(item.productName),
                    subtitle: Text(
                      'Size: ${item.selectedSize} • Màu: ${item.selectedColor} • x${item.quantity}',
                    ),
                    trailing: Text(
                      '${AppConstants.formatPrice(item.rentalPricePerDay)}/ngày',
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

  Widget _buildReviewAction(OrderModel order, OrderItem item) {
    if (order.status != 'completed') return const SizedBox.shrink();
    final key = _reviewKey(order.id, item.productId);
    _ensureReviewState(order, item);

    if (_reviewSubmittingKeys.contains(key)) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('Đang gửi...'),
      );
    }

    if (_reviewCheckingKeys.contains(key)) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('Đang kiểm tra...'),
      );
    }

    if (_reviewedByOrderItem[key] == true) {
      return FilledButton.tonalIcon(
        onPressed: null,
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: const Text('Đã đánh giá'),
      );
    }

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary),
      ),
      onPressed: () => _showReviewDialogForItem(order, item),
      icon: const Icon(Icons.rate_review_outlined, color: AppColors.primary),
      label: const Text('Đánh giá'),
    );
  }

  Widget _buildProductRow(OrderModel order, OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.thumbnailUrl.trim().isEmpty
                    ? Container(
                        width: 58,
                        height: 58,
                        color: AppColors.surfaceVariant,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_rounded,
                          size: 18,
                        ),
                      )
                    : Image.network(
                        item.thumbnailUrl,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 58,
                          height: 58,
                          color: AppColors.surfaceVariant,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            size: 18,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Phân loại: ${item.selectedSize} • ${item.selectedColor}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Số lượng: ${item.quantity}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${AppConstants.formatPrice(item.rentalPricePerDay)}/ngày',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (order.status == 'completed') ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _buildReviewAction(order, item),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusColor = AppColors.getStatusColor(order.status);
    final previewItems = order.items.take(3).toList();

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showOrderDetail(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đơn #${_code(order.id)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
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
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      AppConstants.getStatusName(order.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_date(order.rentalStartDate)} - ${_date(order.rentalEndDate)} • ${order.rentalDays} ngày',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                order.branchName.trim().isEmpty ? 'Chi nhánh chưa xác định' : order.branchName,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const Divider(height: 18),
              ...previewItems.map((item) => _buildProductRow(order, item)),
              if (order.items.length > previewItems.length)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${order.items.length - previewItems.length} sản phẩm khác',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Tổng ${order.totalItemCount} sản phẩm',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    'Tổng thuê: ${AppConstants.formatPrice(order.totalRentalFee)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.appBarTitle)),
        body: Center(child: Text(widget.loginRequiredMessage)),
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
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _buildOrderCard(orders[index]),
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
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value.trim().isEmpty ? 'Chưa có thông tin' : value),
          ),
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

class _ReviewDraft {
  const _ReviewDraft({required this.rating, this.comment});

  final int rating;
  final String? comment;
}

class _ReviewInputDialog extends StatefulWidget {
  const _ReviewInputDialog({required this.productName});

  final String productName;

  @override
  State<_ReviewInputDialog> createState() => _ReviewInputDialogState();
}

class _ReviewInputDialogState extends State<_ReviewInputDialog> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _ReviewDraft(rating: _rating, comment: _commentController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đánh giá sản phẩm'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.productName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text('Mức độ hài lòng'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = star;
                    });
                  },
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    star <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.star,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nhận xét (không bắt buộc)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _submit,
          child: const Text('Gửi đánh giá'),
        ),
      ],
    );
  }
}

String _date(DateTime value) {
  return DateFormat(AppConstants.dateFormat).format(value);
}

String _code(String id) {
  if (id.length > 8) return id.substring(0, 8).toUpperCase();
  return id.toUpperCase();
}
