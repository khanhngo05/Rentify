import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/product_model.dart';
import '../models/branch_model.dart';
import '../models/order_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';

/// Service quản trị viên - mở rộng các chức năng CRUD cho admin
class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════
  //  DASHBOARD & THỐNG KÊ
  // ═══════════════════════════════════════════════════════════════

  /// Lấy thống kê tổng quan
  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Đếm tổng số
    final productsSnapshot = await _db
        .collection(AppConstants.productsCollection)
        .count()
        .get();
    final usersSnapshot = await _db
        .collection(AppConstants.usersCollection)
        .count()
        .get();
    final branchesSnapshot = await _db
        .collection(AppConstants.branchesCollection)
        .where('isActive', isEqualTo: true)
        .count()
        .get();

    // Đơn hàng theo trạng thái
    final ordersSnapshot = await _db
        .collection(AppConstants.ordersCollection)
        .get();

    int totalOrders = ordersSnapshot.docs.length;
    int pendingOrders = 0;
    int rentingOrders = 0;
    int completedOrders = 0;
    double totalRevenue = 0;
    double monthlyRevenue = 0;
    double todayRevenue = 0;

    for (final doc in ordersSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] ?? 'pending';
      final fee = (data['totalRentalFee'] ?? 0).toDouble();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

      switch (status) {
        case 'pending':
          pendingOrders++;
          break;
        case 'renting':
          rentingOrders++;
          break;
        case 'completed':
          completedOrders++;
          totalRevenue += fee;
          if (createdAt != null) {
            if (createdAt.isAfter(startOfMonth)) monthlyRevenue += fee;
            if (createdAt.isAfter(startOfToday)) todayRevenue += fee;
          }
          break;
      }
    }

    return {
      'totalProducts': productsSnapshot.count ?? 0,
      'totalUsers': usersSnapshot.count ?? 0,
      'totalBranches': branchesSnapshot.count ?? 0,
      'totalOrders': totalOrders,
      'pendingOrders': pendingOrders,
      'rentingOrders': rentingOrders,
      'completedOrders': completedOrders,
      'totalRevenue': totalRevenue,
      'monthlyRevenue': monthlyRevenue,
      'todayRevenue': todayRevenue,
    };
  }

  /// Lấy top sản phẩm được thuê nhiều nhất
  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 5}) async {
    final ordersSnapshot = await _db
        .collection(AppConstants.ordersCollection)
        .where('status', isEqualTo: 'completed')
        .get();

    // Đếm số lần thuê mỗi sản phẩm
    final productCounts = <String, int>{};
    final productNames = <String, String>{};
    final productImages = <String, String>{};

    for (final doc in ordersSnapshot.docs) {
      final items = doc.data()['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final productId = item['productId'] as String? ?? '';
        final productName = item['productName'] as String? ?? '';
        final thumbnailUrl = item['thumbnailUrl'] as String? ?? '';
        
        productCounts[productId] = (productCounts[productId] ?? 0) + 1;
        productNames[productId] = productName;
        productImages[productId] = thumbnailUrl;
      }
    }

    // Sắp xếp và lấy top
    final sortedProducts = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedProducts.take(limit).map((e) => {
      'productId': e.key,
      'productName': productNames[e.key] ?? '',
      'thumbnailUrl': productImages[e.key] ?? '',
      'rentalCount': e.value,
    }).toList();
  }

  /// Lấy doanh thu theo ngày trong tháng hiện tại
  Future<List<Map<String, dynamic>>> getRevenueByDay() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final ordersSnapshot = await _db
        .collection(AppConstants.ordersCollection)
        .where('status', isEqualTo: 'completed')
        .get();

    final revenueByDay = <int, double>{};
    
    for (final doc in ordersSnapshot.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final fee = (data['totalRentalFee'] ?? 0).toDouble();

      if (createdAt != null && createdAt.isAfter(startOfMonth)) {
        final day = createdAt.day;
        revenueByDay[day] = (revenueByDay[day] ?? 0) + fee;
      }
    }

    return revenueByDay.entries
        .map((e) => {'day': e.key, 'revenue': e.value})
        .toList()
      ..sort((a, b) => (a['day'] as int).compareTo(b['day'] as int));
  }

  // ═══════════════════════════════════════════════════════════════
  //  QUẢN LÝ SẢN PHẨM
  // ═══════════════════════════════════════════════════════════════

  /// Lấy tất cả sản phẩm (bao gồm cả inactive)
  Future<List<Product>> getAllProducts() async {
    final snapshot = await _db
        .collection(AppConstants.productsCollection)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Product.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Thêm sản phẩm mới
  Future<String> createProduct(Product product) async {
    final docRef = await _db
        .collection(AppConstants.productsCollection)
        .add(product.toMap());
    return docRef.id;
  }

  /// Cập nhật sản phẩm
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _db
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .update(data);
  }

  /// Xóa sản phẩm (soft delete - đặt isActive = false)
  Future<void> deleteProduct(String productId) async {
    await _db
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .update({
      'isActive': false,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Khôi phục sản phẩm đã xóa
  Future<void> restoreProduct(String productId) async {
    await _db
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .update({
      'isActive': true,
      'updatedAt': Timestamp.now(),
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  QUẢN LÝ CHI NHÁNH
  // ═══════════════════════════════════════════════════════════════

  /// Lấy tất cả chi nhánh
  Future<List<BranchModel>> getAllBranches() async {
    final snapshot = await _db
        .collection(AppConstants.branchesCollection)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => BranchModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Thêm chi nhánh mới
  Future<String> createBranch(BranchModel branch) async {
    final docRef = await _db
        .collection(AppConstants.branchesCollection)
        .add(branch.toMap());
    return docRef.id;
  }

  /// Cập nhật chi nhánh
  Future<void> updateBranch(String branchId, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.branchesCollection)
        .doc(branchId)
        .update(data);
  }

  /// Xóa chi nhánh (soft delete)
  Future<void> deleteBranch(String branchId) async {
    await _db
        .collection(AppConstants.branchesCollection)
        .doc(branchId)
        .update({'isActive': false});
  }

  /// Cập nhật tồn kho sản phẩm tại chi nhánh
  Future<void> updateInventory(
    String branchId,
    String productId,
    int totalStock,
    int availableStock,
  ) async {
    await _db
        .collection(AppConstants.branchesCollection)
        .doc(branchId)
        .collection(AppConstants.inventorySubcollection)
        .doc(productId)
        .set({
      'productId': productId,
      'totalStock': totalStock,
      'availableStock': availableStock,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  /// Lấy tồn kho của chi nhánh
  Future<List<BranchInventory>> getBranchInventory(String branchId) async {
    final snapshot = await _db
        .collection(AppConstants.branchesCollection)
        .doc(branchId)
        .collection(AppConstants.inventorySubcollection)
        .get();

    return snapshot.docs
        .map((doc) => BranchInventory.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  //  QUẢN LÝ ĐƠN HÀNG
  // ═══════════════════════════════════════════════════════════════

  /// Lấy tất cả đơn hàng
  Future<List<OrderModel>> getAllOrders() async {
    final snapshot = await _db
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Lấy đơn hàng theo trạng thái
  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    final snapshot = await _db
        .collection(AppConstants.ordersCollection)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Lấy đơn hàng theo chi nhánh
  Future<List<OrderModel>> getOrdersByBranch(String branchId) async {
    final snapshot = await _db
        .collection(AppConstants.ordersCollection)
        .where('branchId', isEqualTo: branchId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Cập nhật trạng thái đơn hàng
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final orderDoc = await _db
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .get();

    if (!orderDoc.exists) return;

    final order = OrderModel.fromFirestore(orderDoc.data()!, orderId);
    final oldStatus = order.status;

    // Cập nhật trạng thái
    await _db
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update({
      'status': newStatus,
      'updatedAt': Timestamp.now(),
    });

    // Xử lý tồn kho khi hủy hoặc hoàn thành
    if ((newStatus == 'cancelled' || newStatus == 'completed') &&
        oldStatus != 'cancelled' &&
        oldStatus != 'completed') {
      // Hoàn lại tồn kho
      for (final item in order.items) {
        final inventoryRef = _db
            .collection(AppConstants.branchesCollection)
            .doc(order.branchId)
            .collection(AppConstants.inventorySubcollection)
            .doc(item.productId);

        await _db.runTransaction((transaction) async {
          final inventoryDoc = await transaction.get(inventoryRef);
          if (inventoryDoc.exists) {
            final currentStock =
                (inventoryDoc.data()?['availableStock'] ?? 0) as int;
            transaction.update(inventoryRef, {
              'availableStock': currentStock + item.quantity,
              'updatedAt': Timestamp.now(),
            });
          }
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  QUẢN LÝ NGƯỜI DÙNG
  // ═══════════════════════════════════════════════════════════════

  /// Lấy tất cả người dùng
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _db
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Cập nhật role người dùng
  Future<void> updateUserRole(String userId, String newRole) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'role': newRole});
  }

  /// Khóa/mở khóa tài khoản (thêm field isBlocked)
  Future<void> toggleUserBlock(String userId, bool isBlocked) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'isBlocked': isBlocked});
  }

  /// Lấy số đơn hàng của user
  Future<int> getUserOrderCount(String userId) async {
    final snapshot = await _db
        .collection(AppConstants.ordersCollection)
        .where('userId', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════
  //  QUẢN LÝ ĐÁNH GIÁ
  // ═══════════════════════════════════════════════════════════════

  /// Lấy tất cả đánh giá
  Future<List<ReviewModel>> getAllReviews() async {
    final snapshot = await _db
        .collection(AppConstants.reviewsCollection)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ReviewModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Ẩn/hiện đánh giá
  Future<void> toggleReviewVisibility(String reviewId, bool isHidden) async {
    await _db
        .collection(AppConstants.reviewsCollection)
        .doc(reviewId)
        .update({'isHidden': isHidden});
  }

  /// Xóa đánh giá và cập nhật rating sản phẩm
  Future<void> deleteReview(String reviewId) async {
    final reviewDoc = await _db
        .collection(AppConstants.reviewsCollection)
        .doc(reviewId)
        .get();

    if (!reviewDoc.exists) return;

    final review = ReviewModel.fromFirestore(reviewDoc.data()!, reviewId);

    // Xóa review
    await _db
        .collection(AppConstants.reviewsCollection)
        .doc(reviewId)
        .delete();

    // Cập nhật rating sản phẩm
    final productRef = _db
        .collection(AppConstants.productsCollection)
        .doc(review.productId);

    await _db.runTransaction((transaction) async {
      final productDoc = await transaction.get(productRef);
      if (productDoc.exists) {
        final currentRating = (productDoc.data()?['rating'] ?? 0).toDouble();
        final currentCount = (productDoc.data()?['reviewCount'] ?? 0).toInt();

        if (currentCount > 1) {
          final newCount = currentCount - 1;
          final newRating =
              ((currentRating * currentCount) - review.rating) / newCount;
          transaction.update(productRef, {
            'rating': double.parse(newRating.toStringAsFixed(1)),
            'reviewCount': newCount,
          });
        } else {
          transaction.update(productRef, {
            'rating': 0.0,
            'reviewCount': 0,
          });
        }
      }
    });
  }

  /// Lấy thông tin user cho review
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.data()!, doc.id);
  }

  /// Lấy thông tin product cho review
  Future<Product?> getProductById(String productId) async {
    final doc = await _db
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .get();

    if (!doc.exists) return null;
    return Product.fromFirestore(doc.data()!, doc.id);
  }
}
