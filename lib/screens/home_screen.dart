import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
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

  late final HomeViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _lastTabIndex = 0;
  int _orderRefreshSignal = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(firebaseService: FirebaseService());
    _viewModel.selectedTabIndex = widget.initialTabIndex.clamp(0, 3);
    _lastTabIndex = _viewModel.selectedTabIndex;
    _viewModel.addListener(_onModelChanged);
    _searchController.addListener(_onSearchChanged);
    _viewModel.loadProducts();
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
    _viewModel.removeListener(_onModelChanged);
    _viewModel.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
            onNotifyTap: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Thông báo'))),
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
                    onFavoriteTap: () {},
                    isFavorite: false,
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
