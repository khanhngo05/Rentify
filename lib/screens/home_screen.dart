import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../services/firebase_service.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/common/product_card.dart';
import 'branch_screen.dart';
import 'order_screen.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'home/widgets/category_chips.dart';
import 'home/widgets/home_app_bar.dart';
import 'home/widgets/product_grid_shimmer.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _stickyHeaderHeight = 102;
  static const double _horizontalInset = 20;
  static const double _gridHorizontalInset = 16;
  static const Color _chipDefaultTextColor = AppColors.textPrimary;
  static const Color _chipSelectedTextColor = Colors.white;

  final FirebaseService _firebaseService = FirebaseService();
  late final HomeViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<List<OrderModel>>? _orderStreamSubscription;
  StreamSubscription<List<Product>>? _promotionStreamSubscription;
  OverlayEntry? _topBannerEntry;
  Timer? _topBannerTimer;
  int _lastTabIndex = 0;
  int _orderRefreshSignal = 0;
  bool _hasOrderSnapshot = false;
  String? _trackingUserId;
  final Map<String, String> _lastKnownOrderStatusById = <String, String>{};
  bool _hasPromotionSnapshot = false;
  final Map<String, String> _lastKnownPromotionUpdatedAtById =
      <String, String>{};
  final List<_OrderStatusNotification> _orderNotifications =
      <_OrderStatusNotification>[];

  static const String _orderStatusCachePrefix = 'order_status_cache_';
  static const String _promotionStatusCachePrefix = 'promotion_status_cache';
  static const String _notificationHistoryPrefix = 'notification_history_';

  int get _unreadNotificationCount {
    return _orderNotifications.where((item) => !item.isRead).length;
  }

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(firebaseService: _firebaseService);
    _viewModel.selectedTabIndex = widget.initialTabIndex.clamp(0, 3);
    _lastTabIndex = _viewModel.selectedTabIndex;
    _viewModel.addListener(_onModelChanged);
    _searchController.addListener(_onSearchChanged);
    _viewModel.loadProducts();
    _bindOrderStatusNotifications();
    _bindStorePromotionNotifications();
  }

  void _onSearchChanged() {
    _viewModel.onSearchChanged(_searchController.text);
  }

  void _onModelChanged() {
    if (!mounted) return;
    final currentTab = _viewModel.selectedTabIndex;
    if (_lastTabIndex != currentTab && currentTab == 2) {
      _orderRefreshSignal++;
    }
    _lastTabIndex = currentTab;
    setState(() {});
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _orderStreamSubscription?.cancel();
    _promotionStreamSubscription?.cancel();
    _topBannerTimer?.cancel();
    _topBannerEntry?.remove();
    _viewModel.removeListener(_onModelChanged);
    _viewModel.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _bindOrderStatusNotifications() {
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthStateChanged,
    );
    _handleAuthStateChanged(FirebaseAuth.instance.currentUser);
  }

  void _bindStorePromotionNotifications() {
    _preparePromotionTracking();
  }

  Future<void> _preparePromotionTracking() async {
    final cachedPromotions = await _loadCachedPromotionStates();
    if (!mounted) return;

    _hasPromotionSnapshot = cachedPromotions.isNotEmpty;
    _lastKnownPromotionUpdatedAtById
      ..clear()
      ..addAll(cachedPromotions);

    _promotionStreamSubscription = _firebaseService
        .streamActiveProducts(limit: 30)
        .listen(_handlePromotionProductsSnapshot);
  }

  void _handleAuthStateChanged(User? user) {
    _orderStreamSubscription?.cancel();
    _orderStreamSubscription = null;

    if (user == null) {
      _trackingUserId = null;
      if (!mounted) return;
      setState(() {
        _hasOrderSnapshot = false;
        _lastKnownOrderStatusById.clear();
        _orderNotifications.clear();
      });
      return;
    }

    _trackingUserId = user.uid;
    _prepareOrderTrackingForUser(user.uid);
  }

  Future<void> _prepareOrderTrackingForUser(String uid) async {
    final cachedStatuses = await _loadCachedOrderStatuses(uid);
    final cachedNotifications = await _loadCachedNotifications(uid);
    if (!mounted || _trackingUserId != uid) return;

    setState(() {
      _hasOrderSnapshot = cachedStatuses.isNotEmpty;
      _lastKnownOrderStatusById
        ..clear()
        ..addAll(cachedStatuses);
      _orderNotifications
        ..clear()
        ..addAll(cachedNotifications);
    });

    _orderStreamSubscription = _firebaseService
        .streamOrdersByUser(uid)
        .listen(_handleOrdersSnapshot);
  }

  void _handleOrdersSnapshot(List<OrderModel> orders) {
    if (!mounted) return;

    if (!_hasOrderSnapshot) {
      _lastKnownOrderStatusById
        ..clear()
        ..addEntries(orders.map((order) => MapEntry(order.id, order.status)));
      _hasOrderSnapshot = true;
      _saveCachedOrderStatuses();
      return;
    }

    final activeOrderIds = <String>{};
    for (final order in orders) {
      activeOrderIds.add(order.id);
      final oldStatus = _lastKnownOrderStatusById[order.id];
      _lastKnownOrderStatusById[order.id] = order.status;

      if (oldStatus != null && oldStatus != order.status) {
        _pushOrderStatusNotification(order);
      }
    }

    _lastKnownOrderStatusById.removeWhere(
      (orderId, _) => !activeOrderIds.contains(orderId),
    );

    _saveCachedOrderStatuses();
  }

  Future<Map<String, String>> _loadCachedOrderStatuses(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_orderStatusCachePrefix$uid');
      if (raw == null || raw.isEmpty) return <String, String>{};

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, String>{};

      final result = <String, String>{};
      decoded.forEach((key, value) {
        final orderId = key.toString();
        final status = value.toString();
        if (orderId.isNotEmpty && status.isNotEmpty) {
          result[orderId] = status;
        }
      });
      return result;
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> _saveCachedOrderStatuses() async {
    final uid = _trackingUserId;
    if (uid == null || uid.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_orderStatusCachePrefix$uid',
        jsonEncode(_lastKnownOrderStatusById),
      );
    } catch (_) {}
  }

  Future<List<_OrderStatusNotification>> _loadCachedNotifications(
    String uid,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_notificationHistoryPrefix$uid');
      if (raw == null || raw.isEmpty) return <_OrderStatusNotification>[];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return <_OrderStatusNotification>[];

      return decoded
          .whereType<Map>()
          .map(
            (entry) => _OrderStatusNotification.fromMap(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList();
    } catch (_) {
      return <_OrderStatusNotification>[];
    }
  }

  Future<void> _saveCachedNotifications() async {
    final uid = _trackingUserId;
    if (uid == null || uid.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = _orderNotifications.map((n) => n.toMap()).toList();
      await prefs.setString(
        '$_notificationHistoryPrefix$uid',
        jsonEncode(payload),
      );
    } catch (_) {}
  }

  Future<Map<String, String>> _loadCachedPromotionStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_promotionStatusCachePrefix);
      if (raw == null || raw.isEmpty) return <String, String>{};

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, String>{};

      final result = <String, String>{};
      decoded.forEach((key, value) {
        final productId = key.toString();
        final updatedAt = value.toString();
        if (productId.isNotEmpty && updatedAt.isNotEmpty) {
          result[productId] = updatedAt;
        }
      });
      return result;
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> _saveCachedPromotionStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _promotionStatusCachePrefix,
        jsonEncode(_lastKnownPromotionUpdatedAtById),
      );
    } catch (_) {}
  }

  void _pushOrderStatusNotification(OrderModel order) {
    final shortId = order.id.length >= 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();
    final statusName = AppConstants.getStatusName(order.status);
    final message = 'Đơn #$shortId đã chuyển sang "$statusName".';

    setState(() {
      _orderNotifications.insert(
        0,
        _OrderStatusNotification(
          orderId: order.id,
          title: 'Cập nhật đơn hàng',
          message: message,
          createdAt: DateTime.now(),
        ),
      );
      if (_orderNotifications.length > 40) {
        _orderNotifications.removeRange(40, _orderNotifications.length);
      }
    });
    _saveCachedNotifications();

    _showTopSlideBanner(
      title: 'Cập nhật đơn hàng',
      message: message,
      icon: Icons.receipt_long_rounded,
    );
  }

  void _handlePromotionProductsSnapshot(List<Product> products) {
    if (!mounted) return;

    final promoProducts = products.where(_isPromotionProduct).toList();
    final activePromoIds = <String>{};

    if (!_hasPromotionSnapshot) {
      _lastKnownPromotionUpdatedAtById
        ..clear()
        ..addEntries(
          promoProducts.map(
            (product) =>
                MapEntry(product.id, product.updatedAt.toIso8601String()),
          ),
        );
      _hasPromotionSnapshot = true;
      _saveCachedPromotionStates();
      return;
    }

    for (final product in promoProducts) {
      activePromoIds.add(product.id);
      final newUpdatedAt = product.updatedAt.toIso8601String();
      final oldUpdatedAt = _lastKnownPromotionUpdatedAtById[product.id];
      _lastKnownPromotionUpdatedAtById[product.id] = newUpdatedAt;

      if (oldUpdatedAt == null || oldUpdatedAt != newUpdatedAt) {
        _pushPromotionNotification(product);
      }
    }

    _lastKnownPromotionUpdatedAtById.removeWhere(
      (productId, _) => !activePromoIds.contains(productId),
    );

    _saveCachedPromotionStates();
  }

  bool _isPromotionProduct(Product product) {
    final tags = product.tags.map((tag) => tag.toLowerCase()).toList();
    const promoKeywords = <String>[
      'sale',
      'promo',
      'khuyen_mai',
      'khuyenmai',
      'uu_dai',
    ];
    final hasPromoTag = tags.any((tag) => promoKeywords.any(tag.contains));
    if (hasPromoTag) return true;

    final recentThreshold = DateTime.now().subtract(const Duration(days: 7));
    return product.updatedAt.isAfter(recentThreshold);
  }

  void _pushPromotionNotification(Product product) {
    final message =
        'Ưu đãi mới: ${product.name} chỉ từ ${AppConstants.formatPrice(product.rentalPricePerDay)}/ngày.';

    setState(() {
      _orderNotifications.insert(
        0,
        _OrderStatusNotification(
          orderId: 'promo_${product.id}',
          title: 'Khuyến mãi cửa hàng',
          message: message,
          createdAt: DateTime.now(),
        ),
      );
      if (_orderNotifications.length > 40) {
        _orderNotifications.removeRange(40, _orderNotifications.length);
      }
    });
    _saveCachedNotifications();

    _showTopSlideBanner(
      title: 'Khuyến mãi cửa hàng',
      message: message,
      icon: Icons.local_offer_rounded,
    );
  }

  void _showTopSlideBanner({
    required String title,
    required String message,
    required IconData icon,
  }) {
    _topBannerTimer?.cancel();
    _topBannerEntry?.remove();

    final overlay = Overlay.of(context);

    _topBannerEntry = OverlayEntry(
      builder: (context) {
        final topInset = MediaQuery.of(context).padding.top;
        return Positioned(
          top: topInset + 10,
          left: 12,
          right: 12,
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(begin: const Offset(0, -1), end: Offset.zero),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            builder: (context, offset, child) {
              return Transform.translate(
                offset: Offset(0, offset.dy * 88),
                child: child,
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        _topBannerTimer?.cancel();
                        _topBannerEntry?.remove();
                        _topBannerEntry = null;
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_topBannerEntry!);

    _topBannerTimer = Timer(const Duration(seconds: 3), () {
      _topBannerEntry?.remove();
      _topBannerEntry = null;
    });
  }

  Future<void> _showNotifications() async {
    if (!mounted) return;

    if (_orderNotifications.isNotEmpty) {
      setState(() {
        for (var i = 0; i < _orderNotifications.length; i++) {
          _orderNotifications[i] = _orderNotifications[i].copyWith(
            isRead: true,
          );
        }
      });
      _saveCachedNotifications();
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        if (_orderNotifications.isEmpty) {
          return const SizedBox(
            height: 220,
            child: Center(child: Text('Chưa có thông báo mới.')),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông báo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (_orderNotifications.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _orderNotifications.clear();
                        });
                        _saveCachedNotifications();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                      label: const Text('Xóa tất cả'),
                    ),
                  ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _orderNotifications.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = _orderNotifications[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          notification.orderId.startsWith('promo_')
                              ? Icons.local_offer_rounded
                              : Icons.receipt_long_rounded,
                          color: notification.orderId.startsWith('promo_')
                              ? AppColors.warning
                              : AppColors.primary,
                        ),
                        title: Text(notification.title),
                        subtitle: Text(
                          '${notification.message}\n${_formatNotificationTime(notification.createdAt)}',
                        ),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.of(context).pop();
                          if (!notification.orderId.startsWith('promo_')) {
                            _viewModel.onTabChanged(2);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatNotificationTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final time = TimeOfDay.fromDateTime(dateTime);
    final timeText = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(time, alwaysUse24HourFormat: true);
    return '$timeText - $day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildHomeTab(context),
      const BranchScreen(),
      OrderScreen(refreshSignal: _orderRefreshSignal),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _viewModel.selectedTabIndex, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(10, 0, 10, 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BottomNavigationBar(
            currentIndex: _viewModel.selectedTabIndex,
            type: BottomNavigationBarType.fixed,
            onTap: _viewModel.onTabChanged,
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.home_outlined, false),
                activeIcon: _buildNavIcon(Icons.home_rounded, true),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.storefront_outlined, false),
                activeIcon: _buildNavIcon(Icons.storefront_rounded, true),
                label: 'Chi nhánh',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.receipt_long_outlined, false),
                activeIcon: _buildNavIcon(Icons.receipt_long_rounded, true),
                label: 'Đơn hàng',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person_outline, false),
                activeIcon: _buildNavIcon(Icons.person_rounded, true),
                label: 'Tôi',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    final cartItemCount = context.select<CartProvider, int>(
      (provider) => provider.totalItemCount,
    );

    return SafeArea(
      child: Column(
        children: [
          HomeAppBar(
            // Giỏ hàng vẫn nằm ở đây (top right)
            onCartTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
            onMessageTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MessagesScreen())),
            onNotifyTap: _showNotifications,
            unreadNotificationCount: _unreadNotificationCount,
            cartItemCount: cartItemCount,
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeStickyHeaderDelegate(
                    child: Container(
                      color: AppColors.background,
                      child: Column(
                        children: [
                          _buildSearchBar(),
                          CategoryChips(
                            categories: _viewModel.categories,
                            selected: _viewModel.selectedCategory,
                            onSelected: _viewModel.onCategoryChanged,
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                    height: _stickyHeaderHeight,
                  ),
                ),
                _buildStateSliver(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateSliver() {
    switch (_viewModel.state) {
      case HomeViewState.loading:
        return const ProductGridShimmerSliver();
      case HomeViewState.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorState(
            message: _viewModel.errorMessage,
            onRetry: _viewModel.retry,
          ),
        );
      case HomeViewState.success:
        if (_viewModel.filteredProducts.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              title: 'Không tìm thấy sản phẩm phù hợp',
              subtitle: _viewModel.isSearching
                  ? 'Thử từ khóa khác hoặc xóa bộ lọc để xem thêm sản phẩm.'
                  : 'Hiện chưa có dữ liệu phù hợp trong danh mục này.',
              canClearFilters: _viewModel.hasActiveQuickFilter,
              onClearFilters: _viewModel.clearQuickFilters,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            _gridHorizontalInset,
            8,
            _gridHorizontalInset,
            20,
          ),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = _viewModel.filteredProducts[index];
              final durationMs = 260 + min(index * 35, 320).toInt();

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: durationMs),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 16),
                      child: child,
                    ),
                  );
                },
                child: Hero(
                  tag: 'product_${product.id}',
                  child: ProductCard(
                    product: product,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: product),
                        ),
                      );
                    },
                    showCategoryBadge: true,
                  ),
                ),
              );
            }, childCount: _viewModel.filteredProducts.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 14,
              childAspectRatio: 0.58,
            ),
          ),
        );
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _horizontalInset,
        0,
        _horizontalInset,
        6,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Tìm áo dài, vest, phụ kiện...',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (_searchController.text.trim().isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                },
              ),
            _FilterButton(
              isActive: _viewModel.hasActiveQuickFilter,
              onTap: _showQuickFilterSheet,
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  void _showQuickFilterSheet() {
    HomeSortOption draftSort = _viewModel.sortOption;
    HomePriceFilter draftPriceFilter = _viewModel.priceFilter;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lọc nhanh',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Sắp xếp',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: HomeSortOption.values.map((option) {
                      final isSelected = option == draftSort;
                      return ChoiceChip(
                        label: Text(
                          _viewModel.sortLabel(option),
                          style: TextStyle(
                            color: isSelected
                                ? _chipSelectedTextColor
                                : _chipDefaultTextColor,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) =>
                            setModalState(() => draftSort = option),
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primary,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? _chipSelectedTextColor
                              : _chipDefaultTextColor,
                        ),
                        showCheckmark: isSelected,
                        checkmarkColor: _chipSelectedTextColor,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Giá thuê / ngày',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: HomePriceFilter.values.map((option) {
                      final isSelected = option == draftPriceFilter;
                      return ChoiceChip(
                        label: Text(
                          _viewModel.priceFilterLabel(option),
                          style: TextStyle(
                            color: isSelected
                                ? _chipSelectedTextColor
                                : _chipDefaultTextColor,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) =>
                            setModalState(() => draftPriceFilter = option),
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primary,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? _chipSelectedTextColor
                              : _chipDefaultTextColor,
                        ),
                        showCheckmark: isSelected,
                        checkmarkColor: _chipSelectedTextColor,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _viewModel.clearQuickFilters();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Xóa lọc'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _viewModel.onSortChanged(draftSort);
                            _viewModel.onPriceFilterChanged(draftPriceFilter);
                            Navigator.of(context).pop();
                          },
                          child: const Text('Áp dụng'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavIcon(IconData icon, bool selected) {
    return Transform.translate(
      offset: Offset(0, selected ? -6 : 0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.6,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: selected ? AppColors.primary : AppColors.textHint,
          size: 22,
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 36,
          width: 36,
          alignment: Alignment.center,
          child: Icon(
            Icons.tune_rounded,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HomeStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HomeStickyHeaderDelegate({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _HomeStickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.canClearFilters,
    required this.onClearFilters,
  });

  final String title;
  final String subtitle;
  final bool canClearFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: AppColors.textHint,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (canClearFilters) ...[
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onClearFilters,
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 36),
          const SizedBox(height: 12),
          Text(
            message.isEmpty ? 'Đã xảy ra lỗi tải dữ liệu.' : message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusNotification {
  const _OrderStatusNotification({
    required this.orderId,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  final String orderId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  factory _OrderStatusNotification.fromMap(Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    DateTime createdAt = DateTime.now();
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    }

    return _OrderStatusNotification(
      orderId: (data['orderId'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      createdAt: createdAt,
      isRead: data['isRead'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'orderId': orderId,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  _OrderStatusNotification copyWith({bool? isRead}) {
    return _OrderStatusNotification(
      orderId: orderId,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
