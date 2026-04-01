import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';

enum HomeViewState { loading, success, error }

enum HomeSortOption {
  relevance,
  newest,
  priceLowToHigh,
  priceHighToLow,
  ratingHighToLow,
}

enum HomePriceFilter { all, under200k, from200kTo400k, above400k }

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required FirebaseService firebaseService})
    : _firebaseService = firebaseService;

  final FirebaseService _firebaseService;

  static const String allCategory = 'all';
  List<String> categories = [allCategory];
  HomeViewState state = HomeViewState.loading;
  String errorMessage = '';
  String selectedCategory = allCategory;
  int selectedTabIndex = 0;
  HomeSortOption sortOption = HomeSortOption.relevance;
  HomePriceFilter priceFilter = HomePriceFilter.all;
  String _searchKeyword = '';
  Timer? _debounce;
  List<Product> _allProducts = [];
  List<Product> filteredProducts = [];

  bool get hasActiveQuickFilter =>
      priceFilter != HomePriceFilter.all ||
      sortOption != HomeSortOption.relevance;

  bool get isSearching => _searchKeyword.trim().isNotEmpty;

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

  Future<void> retry() => loadProducts();

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _searchKeyword = value;
    _debounce = Timer(const Duration(milliseconds: 350), _applyFilter);
  }

  void onCategoryChanged(String category) {
    selectedCategory = category;
    _applyFilter();
  }

  void onTabChanged(int index) {
    if (selectedTabIndex == index) return;
    selectedTabIndex = index;
    notifyListeners();
  }

  void onSortChanged(HomeSortOption value) {
    if (sortOption == value) return;
    sortOption = value;
    _applyFilter();
  }

  void onPriceFilterChanged(HomePriceFilter value) {
    if (priceFilter == value) return;
    priceFilter = value;
    _applyFilter();
  }

  void clearQuickFilters() {
    final hadFilter = hasActiveQuickFilter;
    sortOption = HomeSortOption.relevance;
    priceFilter = HomePriceFilter.all;
    if (hadFilter) {
      _applyFilter();
    }
  }

  String sortLabel(HomeSortOption option) {
    return switch (option) {
      HomeSortOption.relevance => 'Liên quan',
      HomeSortOption.newest => 'Mới nhất',
      HomeSortOption.priceLowToHigh => 'Giá thấp đến cao',
      HomeSortOption.priceHighToLow => 'Giá cao đến thấp',
      HomeSortOption.ratingHighToLow => 'Đánh giá cao',
    };
  }

  String priceFilterLabel(HomePriceFilter option) {
    return switch (option) {
      HomePriceFilter.all => 'Tất cả',
      HomePriceFilter.under200k => 'Dưới 200k',
      HomePriceFilter.from200kTo400k => '200k - 400k',
      HomePriceFilter.above400k => 'Trên 400k',
    };
  }

  void _applyFilter() {
    final keyword = _searchKeyword.toLowerCase().trim();
    final products = _allProducts.where((product) {
      final matchesCategory =
          selectedCategory == allCategory ||
          product.category == selectedCategory;
      final matchesSearch =
          keyword.isEmpty ||
          product.name.toLowerCase().contains(keyword) ||
          product.category.toLowerCase().contains(keyword);
      final matchesPrice = switch (priceFilter) {
        HomePriceFilter.all => true,
        HomePriceFilter.under200k => product.rentalPricePerDay < 200000,
        HomePriceFilter.from200kTo400k =>
          product.rentalPricePerDay >= 200000 &&
              product.rentalPricePerDay <= 400000,
        HomePriceFilter.above400k => product.rentalPricePerDay > 400000,
      };

      return matchesCategory && matchesSearch && matchesPrice;
    }).toList();

    products.sort((a, b) {
      switch (sortOption) {
        case HomeSortOption.relevance:
          return 0;
        case HomeSortOption.newest:
          return b.createdAt.compareTo(a.createdAt);
        case HomeSortOption.priceLowToHigh:
          return a.rentalPricePerDay.compareTo(b.rentalPricePerDay);
        case HomeSortOption.priceHighToLow:
          return b.rentalPricePerDay.compareTo(a.rentalPricePerDay);
        case HomeSortOption.ratingHighToLow:
          return b.rating.compareTo(a.rating);
      }
    });

    filteredProducts = products;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
