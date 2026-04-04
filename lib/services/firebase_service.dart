import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';
import '../models/product_model.dart';
import '../models/branch_model.dart';
import '../models/order_model.dart';
import '../models/review_model.dart';
import '../models/favorite_model.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

/// Service chính giao tiếp với Firebase Firestore
class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SupabaseService _supabaseService = SupabaseService();

  // ═══════════════════════════════════════════════════════════════
  //  PRODUCTS
  // ═══════════════════════════════════════════════════════════════

  /// Lấy tất cả sản phẩm đang hoạt động
  Future<List<Product>> getProducts() async {
    try {
      final snapshot = await _db
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      // Fallback khi chưa tạo composite index cho query orderBy + where.
      if (e.code != 'failed-precondition') rethrow;

      final snapshot = await _db
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data(), doc.id))
          .toList();

      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    }
  }

  /// Stream sản phẩm đang hoạt động để phục vụ thông báo khuyến mãi realtime.
  Stream<List<Product>> streamActiveProducts({int limit = 30}) {
    return _db
        .collection(AppConstants.productsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final products = snapshot.docs
              .map((doc) => Product.fromFirestore(doc.data(), doc.id))
              .toList();

          products.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          if (products.length > limit) {
            return products.sublist(0, limit);
          }
          return products;
        });
  }

  /// Lấy sản phẩm theo danh mục
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      // Fallback khi thiếu index cho category + isActive + createdAt.
      if (e.code != 'failed-precondition') rethrow;

      final snapshot = await _db
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: category)
          .get();

      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data(), doc.id))
          .toList();

      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    }
  }

  /// Lấy 1 sản phẩm theo ID
  Future<Product?> getProductById(String productId) async {
    final doc = await _db
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .get();

    if (!doc.exists) return null;
    return Product.fromFirestore(doc.data()!, doc.id);
  }

  /// Tìm kiếm sản phẩm theo tên
  Future<List<Product>> searchProducts(String query) async {
    final queryLower = query.toLowerCase();
    final snapshot = await _db
        .collection(AppConstants.productsCollection)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => Product.fromFirestore(doc.data(), doc.id))
        .where(
          (product) =>
              product.name.toLowerCase().contains(queryLower) ||
              product.tags.any((tag) => tag.toLowerCase().contains(queryLower)),
        )
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  //  BRANCHES
  // ═══════════════════════════════════════════════════════════════

  /// Lấy tất cả chi nhánh đang hoạt động
  Future<List<BranchModel>> getBranches() async {
    final snapshot = await _db
        .collection(AppConstants.branchesCollection)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => BranchModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Lấy 1 chi nhánh theo ID
  Future<BranchModel?> getBranchById(String branchId) async {
    final doc = await _db
        .collection(AppConstants.branchesCollection)
        .doc(branchId)
        .get();

    if (!doc.exists) return null;
    return BranchModel.fromFirestore(doc.data()!, doc.id);
  }

  /// Lấy tồn kho của 1 chi nhánh
  Future<List<BranchInventory>> getInventoryByBranch(String branchId) async {
    final snapshot = await _db
        .collection(AppConstants.branchesCollection)
        .doc(branchId)
        .collection(AppConstants.inventorySubcollection)
        .get();

    return snapshot.docs
        .map((doc) => BranchInventory.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Lấy tồn kho của 1 sản phẩm tại 1 chi nhánh
  Future<BranchInventory?> getProductInventory(
    String branchId,
    String productId,
  ) async {
    final doc = await _db
        .collection(AppConstants.branchesCollection)
        .doc(branchId)
        .collection(AppConstants.inventorySubcollection)
        .doc(productId)
        .get();

    if (!doc.exists) return null;
    return BranchInventory.fromFirestore(doc.data()!, doc.id);
  }

  /// Kiểm tra sản phẩm còn hàng ở chi nhánh X không
  Future<bool> checkAvailability(String branchId, String productId) async {
    final doc = await _db
        .collection(AppConstants.branchesCollection)
        .doc(branchId)
        .collection(AppConstants.inventorySubcollection)
        .doc(productId)
        .get();

    if (!doc.exists) return false;
    final inventory = BranchInventory.fromFirestore(doc.data()!, doc.id);
    return inventory.isAvailable;
  }

  // ═══════════════════════════════════════════════════════════════
  //  ORDERS
  // ═══════════════════════════════════════════════════════════════

  /// Tạo đơn thuê mới
  Future<String> createOrder(OrderModel order) async {
    final docRef = await _db
        .collection(AppConstants.ordersCollection)
        .add(order.toMap());

    // Trừ tồn kho tại chi nhánh
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
          if (currentStock >= item.quantity) {
            transaction.update(inventoryRef, {
              'availableStock': currentStock - item.quantity,
              'updatedAt': Timestamp.now(),
            });
          }
        }
      });
    }

    return docRef.id;
  }

  /// Lấy lịch sử đơn thuê của 1 user
  Future<List<OrderModel>> getOrdersByUser(String userId) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.ordersCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      // Fallback khi chua tao index cho userId + createdAt.
      if (e.code != 'failed-precondition') rethrow;

      final snapshot = await _db
          .collection(AppConstants.ordersCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
          .toList();

      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    }
  }

  /// Stream lịch sử đơn thuê realtime của 1 user.
  Stream<List<OrderModel>> streamOrdersByUser(String userId) {
    return _db
        .collection(AppConstants.ordersCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
              .toList();

          orders.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return orders;
        });
  }

  /// Lấy các đơn đã hoàn thành của 1 user.
  Future<List<OrderModel>> getCompletedOrdersByUser(String userId) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.ordersCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      // Fallback khi thiếu index cho userId + status + createdAt.
      if (e.code != 'failed-precondition') rethrow;

      final snapshot = await _db
          .collection(AppConstants.ordersCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      final orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
          .toList();

      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    }
  }

  /// Lấy 1 đơn thuê theo ID
  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _db
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .get();

    if (!doc.exists) return null;
    return OrderModel.fromFirestore(doc.data()!, doc.id);
  }

  /// Cập nhật trạng thái đơn thuê
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection(AppConstants.ordersCollection).doc(orderId).update({
      'status': newStatus,
      'updatedAt': Timestamp.now(),
    });

    // Nếu đơn bị hủy hoặc hoàn thành → hoàn lại tồn kho
    if (newStatus == 'cancelled' || newStatus == 'completed') {
      final order = await getOrderById(orderId);
      if (order != null) {
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
  }

  // ═══════════════════════════════════════════════════════════════
  //  REVIEWS
  // ═══════════════════════════════════════════════════════════════

  /// Lấy đánh giá theo sản phẩm
  Future<List<ReviewModel>> getReviewsByProduct(String productId) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.reviewsCollection)
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      // Fallback khi chưa tạo index cho productId + createdAt.
      if (e.code != 'failed-precondition') rethrow;

      final snapshot = await _db
          .collection(AppConstants.reviewsCollection)
          .where('productId', isEqualTo: productId)
          .get();

      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc.data(), doc.id))
          .toList();

      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    }
  }

  /// Lấy đánh giá của 1 user cho 1 sản phẩm.
  Future<List<ReviewModel>> getReviewsByUserAndProduct(
    String userId,
    String productId,
  ) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.reviewsCollection)
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      // Fallback khi thiếu index cho userId + productId + createdAt.
      if (e.code != 'failed-precondition') rethrow;

      final snapshot = await _db
          .collection(AppConstants.reviewsCollection)
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc.data(), doc.id))
          .toList();

      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    }
  }

  /// Kiểm tra user đã đánh giá 1 sản phẩm trong 1 đơn cụ thể chưa.
  Future<bool> hasReviewForOrderItem({
    required String userId,
    required String orderId,
    required String productId,
  }) async {
    final snapshot = await _db
        .collection(AppConstants.reviewsCollection)
        .where('userId', isEqualTo: userId)
        .where('orderId', isEqualTo: orderId)
        .where('productId', isEqualTo: productId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Tạo đánh giá mới + cập nhật rating trung bình của sản phẩm
  Future<String> createReview(ReviewModel review, {List<XFile>? images}) async {
    if (review.orderId.trim().isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Thiếu orderId cho đánh giá.',
      );
    }

    final orderDoc = await _db
        .collection(AppConstants.ordersCollection)
        .doc(review.orderId)
        .get();
    if (!orderDoc.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'Không tìm thấy đơn hàng để đánh giá.',
      );
    }

    final order = OrderModel.fromFirestore(orderDoc.data()!, orderDoc.id);
    final hasProduct = order.items.any(
      (item) => item.productId.trim() == review.productId,
    );
    if (order.userId != review.userId ||
        order.status != 'completed' ||
        !hasProduct) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Bạn chỉ có thể đánh giá sản phẩm trong đơn đã hoàn thành.',
      );
    }

    final existingByOrder = await _db
        .collection(AppConstants.reviewsCollection)
        .where('orderId', isEqualTo: review.orderId)
        .get();
    final duplicated = existingByOrder.docs.any((doc) {
      final data = doc.data();
      return (data['userId'] ?? '').toString() == review.userId &&
          (data['productId'] ?? '').toString() == review.productId;
    });
    if (duplicated) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: 'Đơn này đã được đánh giá cho sản phẩm này.',
      );
    }

    // Tạo review document trước để có reviewId
    final docRef = await _db
        .collection(AppConstants.reviewsCollection)
        .add(review.toMap());

    // Upload ảnh lên Supabase nếu có
    final List<String> photoUrls = [];
    if (images != null && images.isNotEmpty) {
      for (var i = 0; i < images.length; i++) {
        try {
          final imageFile = File(images[i].path);
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

          final url = await _supabaseService.uploadReviewPhoto(
            reviewId: docRef.id,
            imageFile: imageFile,
            fileName: fileName,
          );

          if (url != null) {
            photoUrls.add(url);
          }
        } catch (e) {
          // Log error nhưng không fail toàn bộ review
          print('Error uploading image $i: $e');
        }
      }

      // Update review document với photoUrls
      if (photoUrls.isNotEmpty) {
        await docRef.update({'photoUrls': photoUrls});
      }
    }

    // Cập nhật rating trung bình và reviewCount của sản phẩm
    final productRef = _db
        .collection(AppConstants.productsCollection)
        .doc(review.productId);

    await _db.runTransaction((transaction) async {
      final productDoc = await transaction.get(productRef);
      if (productDoc.exists) {
        final currentRating = (productDoc.data()?['rating'] ?? 0).toDouble();
        final currentCount = (productDoc.data()?['reviewCount'] ?? 0).toInt();

        final newCount = currentCount + 1;
        final newRating =
            ((currentRating * currentCount) + review.rating) / newCount;

        transaction.update(productRef, {
          'rating': double.parse(newRating.toStringAsFixed(1)),
          'reviewCount': newCount,
          'updatedAt': Timestamp.now(),
        });
      }
    });

    return docRef.id;
  }

  // ═══════════════════════════════════════════════════════════════
  //  FAVORITES
  // ═══════════════════════════════════════════════════════════════

  /// Thêm sản phẩm vào yêu thích
  Future<void> addFavorite(String userId, FavoriteModel favorite) async {
    await _db
        .collection(AppConstants.favoritesCollection)
        .doc(userId)
        .collection(AppConstants.favItemsSubcollection)
        .doc(favorite.productId)
        .set(favorite.toMap());
  }

  /// Xóa sản phẩm khỏi yêu thích
  Future<void> removeFavorite(String userId, String productId) async {
    await _db
        .collection(AppConstants.favoritesCollection)
        .doc(userId)
        .collection(AppConstants.favItemsSubcollection)
        .doc(productId)
        .delete();
  }

  /// Lấy danh sách yêu thích của user
  Future<List<FavoriteModel>> getFavoritesByUser(String userId) async {
    final snapshot = await _db
        .collection(AppConstants.favoritesCollection)
        .doc(userId)
        .collection(AppConstants.favItemsSubcollection)
        .orderBy('addedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FavoriteModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Kiểm tra sản phẩm đã yêu thích chưa
  Future<bool> isFavorite(String userId, String productId) async {
    final doc = await _db
        .collection(AppConstants.favoritesCollection)
        .doc(userId)
        .collection(AppConstants.favItemsSubcollection)
        .doc(productId)
        .get();

    return doc.exists;
  }

  // ═══════════════════════════════════════════════════════════════
  //  USERS
  // ═══════════════════════════════════════════════════════════════

  /// Lấy thông tin user theo UID
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.data()!, doc.id);
  }

  /// Tạo hoặc cập nhật thông tin user
  Future<void> saveUser(UserModel user) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  /// Cập nhật thông tin user
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update(data);
  }

  /// Lưu FCM token để nhận thông báo đẩy theo user.
  Future<void> saveUserFcmToken(String uid, String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) return;

    await _db.collection(AppConstants.usersCollection).doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion(<String>[cleanToken]),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  /// Gỡ FCM token khi đăng xuất hoặc token không còn hợp lệ.
  Future<void> removeUserFcmToken(String uid, String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) return;

    await _db.collection(AppConstants.usersCollection).doc(uid).set({
      'fcmTokens': FieldValue.arrayRemove(<String>[cleanToken]),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }
}
