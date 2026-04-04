import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItemModel> _cartItems = [];
  bool _isLoading = false;

  List<CartItemModel> get cartItems => _cartItems;
  bool get isLoading => _isLoading;

  int get totalItemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // Tổng tiền thuê toàn giỏ hàng
  double get totalRentalPrice {
    return _cartItems.fold(0, (sum, item) => sum + item.totalItemRental);
  }

  // Tổng tiền cọc toàn giỏ hàng
  double get totalDepositPrice {
    return _cartItems.fold(0, (sum, item) => sum + item.totalItemDeposit);
  }

  // Lấy thông tin chi nhánh từ item đầu tiên (nếu chỉ có 1 branch)
  String? get branchId {
    if (_cartItems.isEmpty) return null;
    final firstBranch = _cartItems.first.branchId;
    final hasMultiple = _cartItems.any((item) => item.branchId != firstBranch);
    return hasMultiple ? null : firstBranch;
  }

  String? get branchName {
    if (_cartItems.isEmpty) return null;
    final firstBranch = _cartItems.first.branchId;
    final hasMultiple = _cartItems.any((item) => item.branchId != firstBranch);
    return hasMultiple ? null : _cartItems.first.branchName;
  }

  String? get branchAddress {
    if (_cartItems.isEmpty) return null;
    final firstBranch = _cartItems.first.branchId;
    final hasMultiple = _cartItems.any((item) => item.branchId != firstBranch);
    return hasMultiple ? null : _cartItems.first.branchAddress;
  }

  // Kiểm tra xem giỏ có nhiều chi nhánh không
  bool get hasMultipleBranches {
    if (_cartItems.isEmpty) return false;
    final firstBranch = _cartItems.first.branchId;
    return _cartItems.any((item) => item.branchId != firstBranch);
  }

  // Nhóm items theo chi nhánh
  Map<String, List<CartItemModel>> get itemsByBranch {
    final Map<String, List<CartItemModel>> grouped = {};
    for (var item in _cartItems) {
      if (!grouped.containsKey(item.branchId)) {
        grouped[item.branchId] = [];
      }
      grouped[item.branchId]!.add(item);
    }
    return grouped;
  }

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
        final items =
            (data['items'] as List<dynamic>?)
                ?.map(
                  (item) => CartItemModel.fromMap(item as Map<String, dynamic>),
                )
                .toList() ??
            [];

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
  Future<bool> addToCart(CartItemModel newItem) async {
    // Cho phép thêm từ nhiều chi nhánh - sẽ tách đơn khi checkout

    // Kiểm tra xem sản phẩm cùng size và màu đã có chưa
    int index = _cartItems.indexWhere(
      (item) =>
          item.productId == newItem.productId &&
          item.selectedSize == newItem.selectedSize &&
          item.selectedColor == newItem.selectedColor &&
          item.branchId == newItem.branchId, // Thêm điều kiện branch
    );

    if (index >= 0) {
      final item = _cartItems[index];

      // Chặn vượt tồn kho khi thêm lại cùng sản phẩm.
      if (item.quantity >= item.availableStock) {
        return false;
      }

      item.quantity = (item.quantity + newItem.quantity).clamp(
        1,
        item.availableStock,
      );
    } else {
      // Chưa có -> Thêm mới, đồng thời clamp theo tồn kho.
      final safeItem = CartItemModel(
        productId: newItem.productId,
        productName: newItem.productName,
        imageUrl: newItem.imageUrl,
        selectedSize: newItem.selectedSize,
        selectedColor: newItem.selectedColor,
        rentalPricePerDay: newItem.rentalPricePerDay,
        depositPrice: newItem.depositPrice,
        branchId: newItem.branchId,
        branchName: newItem.branchName,
        branchAddress: newItem.branchAddress,
        availableStock: newItem.availableStock,
        quantity: newItem.quantity.clamp(1, newItem.availableStock),
      );
      _cartItems.add(safeItem);
    }

    notifyListeners(); // Cập nhật lại UI
    await _saveCart(); // Lưu vào Firestore
    return true;
  }

  // Hàm thay đổi số lượng
  Future<bool> updateQuantity(
    String productId,
    String size,
    String color,
    String branchId,
    bool isIncrement, {
    Function()? onConfirmRemove, // Callback khi cần confirm xóa
  }) async {
    int index = _cartItems.indexWhere(
      (item) =>
          item.productId == productId &&
          item.selectedSize == size &&
          item.selectedColor == color &&
          item.branchId == branchId,
    );

    if (index >= 0) {
      if (isIncrement) {
        // Kiểm tra xem có vượt quá tồn kho không
        if (_cartItems[index].quantity >= _cartItems[index].availableStock) {
          return false; // Không cho tăng thêm
        }
        _cartItems[index].quantity++;
      } else {
        // Giảm số lượng
        if (_cartItems[index].quantity > 1) {
          _cartItems[index].quantity--;
        } else {
          // Về 0 -> cần confirm xóa
          if (onConfirmRemove != null) {
            onConfirmRemove(); // Gọi callback để hiện dialog
            return false; // Không xóa ngay
          }
          // Nếu không có callback thì xóa luôn
          _cartItems.removeAt(index);
        }
      }
      notifyListeners();
      await _saveCart();
      return true;
    }
    return false;
  }

  // Hàm xóa khỏi giỏ
  Future<void> removeFromCart(
    String productId,
    String size,
    String color,
    String branchId,
  ) async {
    _cartItems.removeWhere(
      (item) =>
          item.productId == productId &&
          item.selectedSize == size &&
          item.selectedColor == color &&
          item.branchId == branchId,
    );
    notifyListeners();
    await _saveCart(); // Lưu vào Firestore
  }

  // Xóa một danh sách item cụ thể (dùng cho checkout theo lựa chọn).
  Future<void> removeItems(List<CartItemModel> items) async {
    if (items.isEmpty) return;

    bool changed = false;
    for (final target in items) {
      final before = _cartItems.length;
      _cartItems.removeWhere(
        (item) =>
            item.productId == target.productId &&
            item.selectedSize == target.selectedSize &&
            item.selectedColor == target.selectedColor &&
            item.branchId == target.branchId,
      );
      if (_cartItems.length != before) {
        changed = true;
      }
    }

    if (!changed) return;
    notifyListeners();
    await _saveCart();
  }

  // Xóa sạch giỏ sau khi đặt đơn thành công
  Future<void> clearCart() async {
    _cartItems.clear();
    notifyListeners();
    await _saveCart(); // Lưu vào Firestore (xóa giỏ)
  }
}
