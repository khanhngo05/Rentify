import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho sản phẩm yêu thích
class FavoriteModel {
  final String productId;
  final String productName;
  final String thumbnailUrl;
  final double rentalPricePerDay;
  final DateTime addedAt;

  FavoriteModel({
    required this.productId,
    required this.productName,
    required this.thumbnailUrl,
    required this.rentalPricePerDay,
    required this.addedAt,
  });

  factory FavoriteModel.fromFirestore(Map<String, dynamic> data, String id) {
    return FavoriteModel(
      productId: id,
      productName: data['productName'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      rentalPricePerDay: (data['rentalPricePerDay'] ?? 0).toDouble(),
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'thumbnailUrl': thumbnailUrl,
      'rentalPricePerDay': rentalPricePerDay,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}
