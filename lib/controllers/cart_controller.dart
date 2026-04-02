import 'package:flutter/material.dart';

class CartItem {
  final String productId, productName, thumbnailUrl, size, color, receiverName, receiverPhone, receiverAddress;
  final DateTime startDate, endDate;
  final int days; final double pricePerDay, deposit; int quantity;

  CartItem({required this.productId, required this.productName, required this.thumbnailUrl, required this.size, required this.color, required this.startDate, required this.endDate, required this.days, required this.pricePerDay, required this.deposit, required this.receiverName, required this.receiverPhone, required this.receiverAddress, this.quantity = 1});
}

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);
  void addToCart(CartItem i) { _items.add(i); notifyListeners(); }
  void clearCart() { _items.clear(); notifyListeners(); }
}
final cartController = CartController();