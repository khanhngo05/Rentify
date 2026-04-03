import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItemModel> _cartItems = [];
  bool _isLoading = false;

  List<CartItemModel> get cartItems => _cartItems;
  bool get isLoading => _isLoading;

  // Tổng tiền thuê toàn giỏ hàng
  double get totalRentalPrice {
    return _cartItems.fold(0, (sum, item) => sum + item.totalItemRental);
  }

  // Tổng tiền cọc toàn giỏ hàng
  double get totalDepositPrice {
    return _cartItems.fold(0, (sum, item) => sum + item.totalItemDeposit);
  }

  // Lấy thông tin chi nhánh từ item đầu tiên (vì tất cả phải cùng branch)
  String? get branchId => _cartItems.isNotEmpty ? _cartItems.first.branchId : null;
  String? get branchName => _cartItems.isNotEmpty ? _cartItems.first.branchName : null;
  String? get branchAddress => _cartItems.isNotEmpty ? _cartItems.first.branchAddress : null;

  // Load giỏ hàng từ Firestore khi khởi động app
  Future<void> loadCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final items = (data['items'] as List<dynamic>?)
            ?.map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
            .toList() ?? [];
        
        _cartItems.clear();
        _cartItems.addAll(items);
      }
    } catch (e) {
      debugPrint('Lỗi load giỏ hàng: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lưu giỏ hàng vào Firestore
  Future<void> _saveCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final cartData = {
        'items': _cartItems.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .set(cartData);
    } catch (e) {
      debugPrint('Lỗi lưu giỏ hàng: $e');
    }
  }

  // Hàm thêm vào giỏ
  Future<void> addToCart(CartItemModel newItem) async {
    // Kiểm tra nếu giỏ không rỗng và branch khác nhau
    if (_cartItems.isNotEmpty && _cartItems.first.branchId != newItem.branchId) {
      throw Exception('Không thể thêm sản phẩm từ chi nhánh khác vào giỏ hàng!');
    }

    // Kiểm tra xem sản phẩm cùng size và màu đã có chưa
    int index = _cartItems.indexWhere((item) => 
      item.productId == newItem.productId && 
      item.selectedSize == newItem.selectedSize &&
      item.selectedColor == newItem.selectedColor
    );

    if (index >= 0) {
      // Đã có -> Tăng số lượng
      _cartItems[index].quantity += newItem.quantity;
    } else {
      // Chưa có -> Thêm mới
      _cartItems.add(newItem);
    }
    notifyListeners(); // Cập nhật lại UI
    await _saveCart(); // Lưu vào Firestore
  }

  // Hàm thay đổi số lượng
  Future<void> updateQuantity(String productId, String size, String color, bool isIncrement) async {
    int index = _cartItems.indexWhere((item) => 
      item.productId == productId && 
      item.selectedSize == size &&
      item.selectedColor == color
    );

    if (index >= 0) {
      if (isIncrement) {
        _cartItems[index].quantity++;
      } else {
        if (_cartItems[index].quantity > 1) {
          _cartItems[index].quantity--;
        }
      }
      notifyListeners();
      await _saveCart(); // Lưu vào Firestore
    }
  }

  // Hàm xóa khỏi giỏ
  Future<void> removeFromCart(String productId, String size, String color) async {
    _cartItems.removeWhere((item) => 
      item.productId == productId && 
      item.selectedSize == size &&
      item.selectedColor == color
    );
    notifyListeners();
    await _saveCart(); // Lưu vào Firestore
  }

  // Xóa sạch giỏ sau khi đặt đơn thành công
  Future<void> clearCart() async {
    _cartItems.clear();
    notifyListeners();
    await _saveCart(); // Lưu vào Firestore (xóa giỏ)
  }
}