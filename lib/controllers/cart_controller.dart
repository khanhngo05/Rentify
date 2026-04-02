import 'package:flutter/material.dart';

class CartItem {
  final String productId, productName, thumbnailUrl, size, color, receiverName, receiverPhone, receiverAddress;
  final DateTime startDate, endDate;
  final int days;
  final double pricePerDay, deposit;
  int quantity;

  CartItem({
    required this.productId, required this.productName, required this.thumbnailUrl,
    required this.size, required this.color, required this.startDate,
    required this.endDate, required this.days, required this.pricePerDay,
    required this.deposit, required this.receiverName, required this.receiverPhone,
    required this.receiverAddress, this.quantity = 1,
  });

  double get totalItemPrice => pricePerDay * days * quantity;
  double get totalItemDeposit => deposit * quantity;
}

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  void addToCart(CartItem item) {
    int index = _items.indexWhere((i) => i.productId == item.productId && i.size == item.size);
    if (index >= 0) { _items[index].quantity += item.quantity; } 
    else { _items.add(item); }
    notifyListeners();
  }

  void clearCart() { _items.clear(); notifyListeners(); }
  double get totalRentalPrice => _items.fold(0, (sum, i) => sum + i.totalItemPrice);
  double get totalDeposit => _items.fold(0, (sum, i) => sum + i.totalItemDeposit);
}

final cartController = CartController();