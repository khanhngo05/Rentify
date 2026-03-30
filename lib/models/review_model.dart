import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho đánh giá sản phẩm
class ReviewModel {
  final String id;
  final String productId;
  final String branchId;
  final String userId;
  final String orderId;
  final int rating;
  final String? comment;
  final List<String> photoUrls;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.branchId,
    required this.userId,
    required this.orderId,
    required this.rating,
    this.comment,
    this.photoUrls = const [],
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ReviewModel(
      id: id,
      productId: data['productId'] ?? '',
      branchId: data['branchId'] ?? '',
      userId: data['userId'] ?? '',
      orderId: data['orderId'] ?? '',
      rating: (data['rating'] ?? 0).toInt(),
      comment: data['comment'],
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'branchId': branchId,
      'userId': userId,
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
