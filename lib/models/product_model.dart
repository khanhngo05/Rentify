import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho sản phẩm trang phục cho thuê
class Product {
  final String id;
  final String name;
  final String description;
  final double rentalPricePerDay;
  final double depositAmount;
  final String thumbnailUrl;
  final List<String> imageUrls;
  final String category;
  final List<String> sizes;
  final List<String> colors;
  final String brand;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.rentalPricePerDay,
    required this.depositAmount,
    required this.thumbnailUrl,
    this.imageUrls = const [],
    required this.category,
    this.sizes = const [],
    this.colors = const [],
    this.brand = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isActive = true,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? 'Không có tên',
      description: data['description'] ?? '',
      rentalPricePerDay: (data['rentalPricePerDay'] ?? 0).toDouble(),
      depositAmount: (data['depositAmount'] ?? 0).toDouble(),
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      category: data['category'] ?? 'phu_kien',
      sizes: List<String>.from(data['sizes'] ?? []),
      colors: List<String>.from(data['colors'] ?? []),
      brand: data['brand'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: (data['reviewCount'] ?? 0).toInt(),
      isActive: data['isActive'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'rentalPricePerDay': rentalPricePerDay,
      'depositAmount': depositAmount,
      'thumbnailUrl': thumbnailUrl,
      'imageUrls': imageUrls,
      'category': category,
      'sizes': sizes,
      'colors': colors,
      'brand': brand,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
