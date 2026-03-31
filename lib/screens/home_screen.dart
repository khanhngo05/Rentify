import 'package:flutter/material.dart';
// imports specific to widgets are in their files
import 'branch_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';
import '../constants/app_colors.dart';
import '../services/firebase_service.dart';
import '../widgets/common/product_card.dart';
import '../viewmodels/home_view_model.dart';
import 'home/widgets/home_app_bar.dart';
import 'home/widgets/category_chips.dart';
import 'home/widgets/product_grid_shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(firebaseService: FirebaseService());
    _viewModel.addListener(_onModelChanged);
    _searchController.addListener(
      () => _viewModel.onSearchChanged(_searchController.text),
    );
    _viewModel.loadProducts();
  }

  void _onModelChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onModelChanged);
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      color: AppColors.primary.withOpacity(0.18),
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

    final pages = <Widget>[
      // Home page (original content)
      SafeArea(
        child: Column(
          children: [
            HomeAppBar(
              searchController: _searchController,
              isExpanded: _isSearchExpanded,
              onToggleExpand: () =>
                  setState(() => _isSearchExpanded = !_isSearchExpanded),
              onCartTap: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Giỏ hàng'))),
              onMessageTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MessagesScreen())),
              onNotifyTap: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Thông báo'))),
              onClear: () {
                // collapse and reset search when user taps clear
                _searchController.clear();
                setState(() => _isSearchExpanded = false);
              },
            ),

            const SizedBox(height: 8),

            CategoryChips(
              categories: _viewModel.categories,
              selected: _viewModel.selectedCategory,
              onSelected: (c) => _viewModel.onCategoryChanged(c),
            ),

            const SizedBox(height: 8),

            Expanded(child: _buildBody()),
          ],
        ),
      ),

      // Branches
      const BranchScreen(),

      // History (placeholder)
      const HistoryScreen(),

      // Profile / Me
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _selectedIndex = i),
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
            icon: _buildNavIcon(Icons.history_outlined, false),
            activeIcon: _buildNavIcon(Icons.history_rounded, true),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.person_outline, false),
            activeIcon: _buildNavIcon(Icons.person_rounded, true),
            label: 'Tôi',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_viewModel.state) {
      case HomeViewState.loading:
        return const ProductGridShimmer();
      case HomeViewState.error:
        return Center(
          child: Text(
            _viewModel.errorMessage.isEmpty ? 'Lỗi' : _viewModel.errorMessage,
          ),
        );
      case HomeViewState.success:
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemCount: _viewModel.filteredProducts.length,
          itemBuilder: (context, index) {
            final product = _viewModel.filteredProducts[index];
            return Hero(
              tag: 'product_${product.id}',
              child: ProductCard(
                product: product,
                onTap: () {},
                onFavoriteTap: () {},
                isFavorite: false,
                showCategoryBadge: true,
              ),
            );
          },
        );
    }
  }
}

// --- AppBar ---
// HomeAppBar, CategoryChips and ProductGridShimmer moved to separate files under screens/home/widgets

// Widgets and ViewModel moved to separate files under lib/viewmodels and lib/screens/home/widgets

// ViewModel moved to lib/viewmodels/home_view_model.dart
