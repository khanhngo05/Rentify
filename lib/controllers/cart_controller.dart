import 'package:flutter/material.dart';

class CartItem {
  final String productId;
  final String productName;
  final String imageUrl; // Thống nhất dùng tên này
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
    this.quantity = 1,
  });

  double get totalItemPrice => pricePerDay * days * quantity;
  double get totalItemDeposit => deposit * quantity;
}

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  void addToCart(CartItem item) {
    _items.add(item);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  double get totalRentalPrice => _items.fold(0, (sum, item) => sum + item.totalItemPrice);
  double get totalDeposit => _items.fold(0, (sum, item) => sum + item.totalItemDeposit);
}

final cartController = CartController();