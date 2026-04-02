import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/firebase_service.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/common/product_card.dart';
import 'cart_screen.dart';
import 'order_screen.dart';
import 'product_detail_screen.dart';
import 'home/widgets/category_chips.dart';
import 'home/widgets/home_app_bar.dart';
import 'home/widgets/product_grid_shimmer.dart';
import 'messages_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tăng chiều cao lên 120.0 để Quỳnh không bị lỗi "Bottom Overflowed"
  static const double _stickyHeaderHeight = 120.0; 
  late final HomeViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(firebaseService: FirebaseService());
    _viewModel.addListener(_onModelChanged);
    _viewModel.loadProducts();
  }

  void _onModelChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _viewModel.removeListener(_onModelChanged);
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildHomeTab(context),
      const Center(child: Text('Chi nhánh')),
      const OrderScreen(), // ĐÃ THAY THẾ HISTORY
      const Center(child: Text('Tôi')),
    ];

    return Scaffold(
      body: IndexedStack(index: _viewModel.selectedTabIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _viewModel.selectedTabIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        onTap: _viewModel.onTabChanged,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront_rounded), label: 'Chi nhánh'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment_rounded), label: 'Đơn hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person_rounded), label: 'Tôi'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          HomeAppBar(
            // FIX LỖI: Thêm các tham số bắt buộc để hết gạch đỏ
            onCartTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
            onMessageTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessagesScreen())),
            onNotifyTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thông báo'))),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeHeaderDelegate(
                    height: _stickyHeaderHeight,
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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 14, childAspectRatio: 0.58,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.divider)),
      child: TextField(
        controller: _searchController,
        onChanged: _viewModel.onSearchChanged,
        decoration: const InputDecoration(hintText: 'Tìm kiếm...', icon: Icon(Icons.search), border: InputBorder.none),
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height; final Widget child;
  _HomeHeaderDelegate({required this.height, required this.child});
  @override double get minExtent => height;
  @override double get maxExtent => height;
  @override Widget build(context, offset, overlap) => child;
  @override bool shouldRebuild(old) => true;
}