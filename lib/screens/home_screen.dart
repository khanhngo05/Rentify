import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/firebase_service.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/common/product_card.dart';
import 'branch_screen.dart';
import 'cart_screen.dart';
import 'order_screen.dart'; // Tab mới
import 'product_detail_screen.dart';
import 'home/widgets/category_chips.dart';
import 'home/widgets/home_app_bar.dart';
import 'home/widgets/product_grid_shimmer.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _stickyHeaderHeight = 102;
  late final HomeViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(firebaseService: FirebaseService());
    _viewModel.addListener(() { if (mounted) setState(() {}); });
    _searchController.addListener(() => _viewModel.onSearchChanged(_searchController.text));
    _viewModel.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    // Đã thay HistoryScreen bằng OrderScreen ở vị trí index 2
    final pages = <Widget>[
      _buildHomeTab(context),
      const BranchScreen(),
      const OrderScreen(), 
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _viewModel.selectedTabIndex, children: pages),
      bottomNavigationBar: SafeArea(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BottomNavigationBar(
            currentIndex: _viewModel.selectedTabIndex,
            type: BottomNavigationBarType.fixed,
            onTap: _viewModel.onTabChanged,
            selectedItemColor: AppColors.primary,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Trang chủ'),
              const BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront_rounded), label: 'Chi nhánh'),
              const BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment_rounded), label: 'Đơn hàng'),
              const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person_rounded), label: 'Tôi'),
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
            onCartTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
            onMessageTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessagesScreen())),
            onNotifyTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thông báo'))),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeStickyHeaderDelegate(
                    height: _stickyHeaderHeight,
                    child: Container(
                      color: AppColors.background,
                      child: Column(
                        children: [
                          _buildSearchBar(),
                          CategoryChips(categories: _viewModel.categories, selected: _viewModel.selectedCategory, onSelected: _viewModel.onCategoryChanged),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildProductGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_viewModel.state == HomeViewState.loading) return const ProductGridShimmerSliver();
    if (_viewModel.filteredProducts.isEmpty) return const SliverFillRemaining(child: Center(child: Text('Không tìm thấy sản phẩm')));
    
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = _viewModel.filteredProducts[index];
          return ProductCard(
            product: product,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
            isFavorite: false,
          );
        }, childCount: _viewModel.filteredProducts.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 14, childAspectRatio: 0.58),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.divider)),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: 'Tìm áo dài, vest...', prefixIcon: Icon(Icons.search, color: AppColors.primary), border: InputBorder.none),
        ),
      ),
    );
  }
}

class _HomeStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child; final double height;
  _HomeStickyHeaderDelegate({required this.child, required this.height});
  @override double get minExtent => height; @override double get maxExtent => height;
  @override Widget build(BuildContext context, double offset, bool overlap) => child;
  @override bool shouldRebuild(covariant _HomeStickyHeaderDelegate old) => true;
}