import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItemModel> _cartItems = [];

  List<CartItemModel> get cartItems => _cartItems;

  // Tổng tiền thuê toàn giỏ hàng
  double get totalRentalPrice {
    return _cartItems.fold(0, (sum, item) => sum + item.totalItemRental);
  }

  // Tổng tiền cọc toàn giỏ hàng
  double get totalDepositPrice {
    return _cartItems.fold(0, (sum, item) => sum + item.totalItemDeposit);
  }

  // Hàm thêm vào giỏ
  void addToCart(CartItemModel newItem) {
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
  }

  // Hàm thay đổi số lượng
  void updateQuantity(String productId, String size, String color, bool isIncrement) {
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
    }
  }

  // Hàm xóa khỏi giỏ
  void removeFromCart(String productId, String size, String color) {
    _cartItems.removeWhere((item) => 
      item.productId == productId && 
      item.selectedSize == size &&
      item.selectedColor == color
    );
    notifyListeners();
  }

  // Xóa sạch giỏ sau khi đặt đơn thành công
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}