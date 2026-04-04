import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentify/models/product_model.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('Product Model Tests', () {
    late Map<String, dynamic> mockProductData;
    
    setUp(() {
      mockProductData = {
        'name': 'Áo dài truyền thống',
        'description': 'Áo dài lụa cao cấp, phù hợp dự tiệc',
        'rentalPricePerDay': 200000.0,
        'depositAmount': 500000.0,
        'thumbnailUrl': 'https://example.com/image.jpg',
        'imageUrls': ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
        'category': 'Áo dài',
        'sizes': ['S', 'M', 'L'],
        'colors': ['Đỏ', 'Xanh', 'Trắng'],
        'brand': 'Thương hiệu ABC',
        'rating': 4.5,
        'reviewCount': 10,
        'isActive': true,
        'tags': ['formal', 'traditional'],
        'createdAt': createMockTimestamp(TestData.now),
        'updatedAt': createMockTimestamp(TestData.now),
      };
    });

    test('fromFirestore should correctly deserialize data', () {
      final product = Product.fromFirestore(mockProductData, TestData.testProductId);

      expect(product.id, TestData.testProductId);
      expect(product.name, 'Áo dài truyền thống');
      expect(product.description, 'Áo dài lụa cao cấp, phù hợp dự tiệc');
      expect(product.rentalPricePerDay, 200000.0);
      expect(product.depositAmount, 500000.0);
      expect(product.thumbnailUrl, 'https://example.com/image.jpg');
      expect(product.imageUrls.length, 2);
      expect(product.category, 'Áo dài');
      expect(product.sizes, ['S', 'M', 'L']);
      expect(product.colors, ['Đỏ', 'Xanh', 'Trắng']);
      expect(product.brand, 'Thương hiệu ABC');
      expect(product.rating, 4.5);
      expect(product.reviewCount, 10);
      expect(product.isActive, true);
      expect(product.tags, ['formal', 'traditional']);
    });

    test('fromFirestore should handle missing optional fields', () {
      final minimalData = {
        'name': 'Test Product',
        'description': 'Test Description',
        'rentalPricePerDay': 100000,
        'depositAmount': 200000,
        'thumbnailUrl': 'https://example.com/test.jpg',
        'category': 'Test Category',
        'createdAt': createMockTimestamp(),
        'updatedAt': createMockTimestamp(),
      };

      final product = Product.fromFirestore(minimalData, 'test-id');

      expect(product.imageUrls, isEmpty);
      expect(product.sizes, isEmpty);
      expect(product.colors, isEmpty);
      expect(product.brand, '');
      expect(product.rating, 0.0);
      expect(product.reviewCount, 0);
      expect(product.isActive, true);
      expect(product.tags, isEmpty);
    });

    test('fromFirestore should handle null name with fallback', () {
      mockProductData.remove('name');
      final product = Product.fromFirestore(mockProductData, 'test-id');
      expect(product.name, 'Không có tên');
    });

    test('fromFirestore should convert numeric types correctly', () {
      mockProductData['rentalPricePerDay'] = 150000; // int
      mockProductData['depositAmount'] = 300000; // int
      mockProductData['rating'] = 5; // int

      final product = Product.fromFirestore(mockProductData, 'test-id');

      expect(product.rentalPricePerDay, isA<double>());
      expect(product.rentalPricePerDay, 150000.0);
      expect(product.depositAmount, isA<double>());
      expect(product.depositAmount, 300000.0);
      expect(product.rating, isA<double>());
      expect(product.rating, 5.0);
    });

    test('toMap should correctly serialize data', () {
      final product = Product.fromFirestore(mockProductData, TestData.testProductId);
      final map = product.toMap();

      expect(map['name'], 'Áo dài truyền thống');
      expect(map['description'], 'Áo dài lụa cao cấp, phù hợp dự tiệc');
      expect(map['rentalPricePerDay'], 200000.0);
      expect(map['depositAmount'], 500000.0);
      expect(map['thumbnailUrl'], 'https://example.com/image.jpg');
      expect(map['imageUrls'], isA<List>());
      expect(map['category'], 'Áo dài');
      expect(map['sizes'], ['S', 'M', 'L']);
      expect(map['colors'], ['Đỏ', 'Xanh', 'Trắng']);
      expect(map['brand'], 'Thương hiệu ABC');
      expect(map['rating'], 4.5);
      expect(map['reviewCount'], 10);
      expect(map['isActive'], true);
      expect(map['tags'], ['formal', 'traditional']);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('Product serialization roundtrip should preserve data', () {
      final product = Product.fromFirestore(mockProductData, TestData.testProductId);
      final map = product.toMap();
      
      // Verify serialization preserves key fields
      expect(map['name'], product.name);
      expect(map['rentalPricePerDay'], product.rentalPricePerDay);
      expect(map['depositAmount'], product.depositAmount);
      expect(map['category'], product.category);
      expect(map['brand'], product.brand);
    });

    test('Product should handle empty strings and lists correctly', () {
      mockProductData['description'] = '';
      mockProductData['brand'] = '';
      mockProductData['imageUrls'] = [];
      mockProductData['sizes'] = [];

      final product = Product.fromFirestore(mockProductData, 'test-id');

      expect(product.description, '');
      expect(product.brand, '');
      expect(product.imageUrls, isEmpty);
      expect(product.sizes, isEmpty);
    });
  });
}
