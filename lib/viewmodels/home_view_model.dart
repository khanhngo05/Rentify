import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';

enum HomeViewState { loading, success, error }

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required this.firebaseService})
    : _firebaseService = firebaseService;

  final FirebaseService firebaseService;
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
