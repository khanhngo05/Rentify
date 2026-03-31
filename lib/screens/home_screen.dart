import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/product_model.dart';
import 'branch_screen.dart';
import '../services/firebase_service.dart';
import '../widgets/common/product_card.dart';

/// HomeScreen hiển thị danh sách sản phẩm với tìm kiếm + lọc danh mục.
///
/// Áp dụng MVVM đơn giản:
/// - View: `HomeScreen`
/// - ViewModel: `_HomeViewModel`
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = _HomeViewModel(firebaseService: FirebaseService())
      ..loadProducts();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.checkroom_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Rentify'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to cart screen.
            },
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Giỏ hàng',
          ),
          IconButton(
            onPressed: _openQuickMenu,
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Menu',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Column(
            children: [
              _SearchSection(viewModel: _viewModel),
              const SizedBox(height: 8),
              Expanded(child: _buildBodyByState()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBodyByState() {
    if (_viewModel.state == HomeViewState.loading) {
      return const _ProductGridShimmer();
    }

    if (_viewModel.state == HomeViewState.error) {
      return _ErrorState(
        message: _viewModel.errorMessage,
        onRetry: _viewModel.loadProducts,
      );
    }

    if (_viewModel.filteredProducts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _viewModel.loadProducts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'Không tìm thấy sản phẩm phù hợp',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _viewModel.loadProducts,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final aspectRatio = width > 700 ? 0.78 : 0.7;

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _viewModel.filteredProducts.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: aspectRatio,
            ),
            itemBuilder: (context, index) {
              final product = _viewModel.filteredProducts[index];
              return ProductCard(
                product: product,
                onTap: () {
                  // TODO: Navigate to product detail screen.
                },
                onFavoriteTap: () {
                  // TODO: Add/remove favorite.
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openQuickMenu() async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'QuickMenu',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerRight,
          child: SafeArea(
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                bottomLeft: Radius.circular(22),
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.84,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.menu_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Tùy chọn nhanh',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.tune_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Bộ lọc danh mục',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _HomeViewModel.categories.map((
                                  category,
                                ) {
                                  final isSelected =
                                      _viewModel.selectedCategory == category;
                                  return ChoiceChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      _viewModel.onCategoryChanged(category);
                                      Navigator.of(context).pop();
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.location_on_outlined),
                          title: const Text('Vị trí chi nhánh gần bạn'),
                          subtitle: const Text(
                            'Xem danh sách chi nhánh theo GPS',
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const BranchScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}

enum HomeViewState { loading, success, error }

class _HomeViewModel extends ChangeNotifier {
  _HomeViewModel({required FirebaseService firebaseService})
    : _firebaseService = firebaseService;

  final FirebaseService _firebaseService;

  static const String allCategory = 'Tất cả';
  static const List<String> categories = [
    allCategory,
    'Quần',
    'Áo',
    'Váy',
    'Giày',
    'Phụ kiện',
  ];

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
      _applySearchAndFilter();
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

    // Debounce cơ bản để giảm số lần filter khi user gõ liên tục.
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchKeyword = value.trim().toLowerCase();
      _applySearchAndFilter();
      if (state != HomeViewState.loading) {
        notifyListeners();
      }
    });
  }

  void onCategoryChanged(String category) {
    if (selectedCategory == category) {
      return;
    }

    selectedCategory = category;
    _applySearchAndFilter();
    if (state != HomeViewState.loading) {
      notifyListeners();
    }
  }

  void _applySearchAndFilter() {
    filteredProducts = _allProducts.where((product) {
      final normalizedCategoryLabel = AppConstants.getCategoryName(
        product.category,
      ).toLowerCase();
      final normalizedRawCategory = product.category.toLowerCase();

      final matchSearch =
          _searchKeyword.isEmpty ||
          product.name.toLowerCase().contains(_searchKeyword) ||
          normalizedCategoryLabel.contains(_searchKeyword) ||
          normalizedRawCategory.contains(_searchKeyword);

      final matchCategory =
          selectedCategory == allCategory ||
          _isProductInCategory(product.category, selectedCategory);

      return matchSearch && matchCategory;
    }).toList();
  }

  bool _isProductInCategory(String productCategory, String selected) {
    final value = productCategory.toLowerCase();

    switch (selected) {
      case 'Quần':
        return value.contains('quan') || value.contains('pant');
      case 'Áo':
        return value.contains('ao') ||
            value.contains('shirt') ||
            value.contains('top');
      case 'Váy':
        return value.contains('vay') ||
            value.contains('dam') ||
            value.contains('dress');
      case 'Giày':
        return value.contains('giay') || value.contains('shoe');
      case 'Phụ kiện':
        return value.contains('phu_kien') ||
            value.contains('phukien') ||
            value.contains('accessory') ||
            value.contains('phụ kiện');
      default:
        return true;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

class _SearchSection extends StatelessWidget {
  const _SearchSection({required this.viewModel});

  final _HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: viewModel.onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc danh mục',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _HomeViewModel.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _HomeViewModel.categories[index];
                final isSelected = viewModel.selectedCategory == category;

                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => viewModel.onCategoryChanged(category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductGridShimmer extends StatelessWidget {
  const _ProductGridShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
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
