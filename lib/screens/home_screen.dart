import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/product_model.dart';
import 'branch_screen.dart';
import '../services/firebase_service.dart';
import '../widgets/common/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _HomeViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _viewModel = _HomeViewModel(firebaseService: FirebaseService());
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _HomeAppBar(
              searchController: _searchController,
              isExpanded: _isSearchExpanded,
              onToggleExpand: () =>
                  setState(() => _isSearchExpanded = !_isSearchExpanded),
              onCartTap: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Giỏ hàng'))),
              onLocationTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const BranchScreen())),
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

            _CategoryChips(
              categories: _viewModel.categories,
              selected: _viewModel.selectedCategory,
              onSelected: (c) => _viewModel.onCategoryChanged(c),
            ),

            const SizedBox(height: 8),

            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_viewModel.state) {
      case HomeViewState.loading:
        return const _ProductGridShimmer();
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
class _HomeAppBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onCartTap;
  final VoidCallback onLocationTap;
  final VoidCallback onNotifyTap;
  final VoidCallback onClear;

  const _HomeAppBar({
    required this.searchController,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onCartTap,
    required this.onLocationTap,
    required this.onNotifyTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Text(
                        'Rentify',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                // right-side actions: notify, cart, location
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        size: 24,
                        color: AppColors.primary,
                      ),
                      onPressed: onNotifyTap,
                      tooltip: 'Thông báo',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        size: 26,
                        color: AppColors.primary,
                      ),
                      onPressed: onCartTap,
                      tooltip: 'Giỏ hàng',
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(
                        Icons.location_on_outlined,
                        size: 26,
                        color: AppColors.primary,
                      ),
                      onPressed: onLocationTap,
                      tooltip: 'Chi nhánh',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // compact search inside appbar when not expanded; otherwise full search below
          AnimatedCrossFade(
            firstChild: GestureDetector(
              onTap: onToggleExpand,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tìm sản phẩm...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchController.clear();
                          FocusScope.of(context).unfocus();
                          onClear();
                        },
                      ),
                    ),
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// --- Category Filter Chips ---
class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final key = categories[i];
          final isSelected = selected == key;
          final display = key == _HomeViewModel.allCategory
              ? 'Tất cả'
              : AppConstants.getCategoryName(key);
          return ChoiceChip(
            label: Text(
              display,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(key),
            backgroundColor: AppColors.surfaceVariant,
            selectedColor: AppColors.primary,
            shape: const StadiumBorder(),
            elevation: isSelected ? 2 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

// --- Shimmer Loading State ---
class _ProductGridShimmer extends StatelessWidget {
  const _ProductGridShimmer();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
        );
      },
    );
  }
}

// --- ViewModel ---
enum HomeViewState { loading, success, error }

class _HomeViewModel extends ChangeNotifier {
  _HomeViewModel({required FirebaseService firebaseService})
    : _firebaseService = firebaseService;
  final FirebaseService _firebaseService;
  static const String allCategory = 'all';
  List<String> categories = [allCategory];
  HomeViewState state = HomeViewState.loading;
  String errorMessage = '';
  String selectedCategory = allCategory;
  String _searchKeyword = '';
  Timer? _debounce;
  List<Product> _allProducts = [];
  List<Product> filteredProducts = [];

  Future<void> loadProducts() async {
    state = HomeViewState.loading;
    errorMessage = '';
    notifyListeners();
    try {
      _allProducts = await _firebaseService.getProducts();
      final keys = _allProducts.map((p) => p.category).toSet().toList();
      categories = [allCategory, ...keys];
      if (!categories.contains(selectedCategory)) {
        selectedCategory = allCategory;
      }
      _applyFilter();
      state = HomeViewState.success;
      notifyListeners();
    } catch (error) {
      errorMessage = 'Không thể tải sản phẩm. Vui lòng thử lại.';
      state = HomeViewState.error;
      notifyListeners();
    }
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _searchKeyword = value;
    _debounce = Timer(const Duration(milliseconds: 350), _applyFilter);
  }

  void onCategoryChanged(String category) {
    selectedCategory = category;
    _applyFilter();
  }

  void _applyFilter() {
    final keyword = _searchKeyword.toLowerCase().trim();
    filteredProducts = _allProducts.where((product) {
      final matchesCategory =
          selectedCategory == allCategory ||
          product.category == selectedCategory;
      final matchesSearch =
          keyword.isEmpty ||
          product.name.toLowerCase().contains(keyword) ||
          product.category.toLowerCase().contains(keyword);
      return matchesCategory && matchesSearch;
    }).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
