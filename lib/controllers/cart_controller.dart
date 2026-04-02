import 'package:flutter/material.dart';

class CartItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final String size;
  final String color;
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final double pricePerDay;
  final double deposit;
  
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;

  // THÊM MỚI: Biến lưu số lượng (bỏ chữ final để có thể thay đổi được)
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.size,
    required this.color,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.pricePerDay,
    required this.deposit,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress,
    this.quantity = 1, // Mặc định khi thêm vào giỏ là 1 bộ
  });

  // CẬP NHẬT CÔNG THỨC: Tiền thuê và Tiền cọc phải nhân thêm số lượng
  double get totalItemPrice => pricePerDay * days * quantity;
  double get totalItemDeposit => deposit * quantity; 
}

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void addToCart(CartItem item) {
    _items.add(item);
    notifyListeners(); 
  }

  void removeFromCart(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // THÊM MỚI: Hàm Tăng số lượng
  void incrementQuantity(int index) {
    _items[index].quantity++;
    notifyListeners(); // Báo cho giao diện vẽ lại
  }

  // THÊM MỚI: Hàm Giảm số lượng
  void decrementQuantity(int index) {
    if (_items[index].quantity > 1) { // Đảm bảo số lượng tối thiểu là 1
      _items[index].quantity--;
      notifyListeners();
    }
  }

  double get totalRentalPrice {
    return _items.fold(0, (sum, item) => sum + item.totalItemPrice);
  }

  // CẬP NHẬT: Tính tổng cọc cũng dựa vào công thức mới có nhân số lượng
  double get totalDeposit {
    return _items.fold(0, (sum, item) => sum + item.totalItemDeposit);
  }
}

final cartController = CartController();