import 'package:flutter_test/flutter_test.dart';
import 'package:rentify/models/cart_item_model.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('CartItemModel Tests', () {
    late Map<String, dynamic> mockCartData;

    setUp(() {
      mockCartData = {
        'productId': TestData.testProductId,
        'productName': 'Áo dài truyền thống',
        'imageUrl': 'https://example.com/image.jpg',
        'selectedSize': 'M',
        'selectedColor': 'Đỏ',
        'rentalPricePerDay': 200000.0,
        'depositPrice': 500000.0,
        'branchId': TestData.testBranchId,
        'branchName': 'Chi nhánh Hà Nội',
        'branchAddress': '123 Đường ABC, Hà Nội',
        'availableStock': 5,
        'quantity': 2,
        'rentalDays': 3,
      };
    });

    test('fromMap should correctly deserialize data', () {
      final cartItem = CartItemModel.fromMap(mockCartData);

      expect(cartItem.productId, TestData.testProductId);
      expect(cartItem.productName, 'Áo dài truyền thống');
      expect(cartItem.imageUrl, 'https://example.com/image.jpg');
      expect(cartItem.selectedSize, 'M');
      expect(cartItem.selectedColor, 'Đỏ');
      expect(cartItem.rentalPricePerDay, 200000.0);
      expect(cartItem.depositPrice, 500000.0);
      expect(cartItem.branchId, TestData.testBranchId);
      expect(cartItem.branchName, 'Chi nhánh Hà Nội');
      expect(cartItem.branchAddress, '123 Đường ABC, Hà Nội');
      expect(cartItem.availableStock, 5);
      expect(cartItem.quantity, 2);
      expect(cartItem.rentalDays, 3);
    });

    test('fromMap should handle missing optional fields with defaults', () {
      final minimalData = {
        'productId': 'prod-123',
        'productName': 'Test Product',
        'imageUrl': '',
        'selectedSize': 'M',
        'selectedColor': 'Red',
        'rentalPricePerDay': 100000,
        'depositPrice': 200000,
        'branchId': 'branch-1',
        'branchName': 'Branch 1',
        'branchAddress': 'Address 1',
      };

      final cartItem = CartItemModel.fromMap(minimalData);

      expect(cartItem.availableStock, 999);
      expect(cartItem.quantity, 1);
      expect(cartItem.rentalDays, 1);
    });

    test('totalItemRental should calculate correctly', () {
      final cartItem = CartItemModel.fromMap(mockCartData);
      
      // 200000 * 2 (quantity) * 3 (days) = 1,200,000
      expect(cartItem.totalItemRental, 1200000.0);
    });

    test('totalItemDeposit should calculate correctly', () {
      final cartItem = CartItemModel.fromMap(mockCartData);
      
      // 500000 * 2 (quantity) = 1,000,000
      expect(cartItem.totalItemDeposit, 1000000.0);
    });

    test('toMap should correctly serialize data', () {
      final cartItem = CartItemModel.fromMap(mockCartData);
      final map = cartItem.toMap();

      expect(map['productId'], TestData.testProductId);
      expect(map['productName'], 'Áo dài truyền thống');
      expect(map['imageUrl'], 'https://example.com/image.jpg');
      expect(map['selectedSize'], 'M');
      expect(map['selectedColor'], 'Đỏ');
      expect(map['rentalPricePerDay'], 200000.0);
      expect(map['depositPrice'], 500000.0);
      expect(map['branchId'], TestData.testBranchId);
      expect(map['branchName'], 'Chi nhánh Hà Nội');
      expect(map['branchAddress'], '123 Đường ABC, Hà Nội');
      expect(map['availableStock'], 5);
      expect(map['quantity'], 2);
      expect(map['rentalDays'], 3);
    });

    test('quantity and rentalDays should be mutable', () {
      final cartItem = CartItemModel.fromMap(mockCartData);
      
      expect(cartItem.quantity, 2);
      expect(cartItem.rentalDays, 3);

      cartItem.quantity = 5;
      cartItem.rentalDays = 7;

      expect(cartItem.quantity, 5);
      expect(cartItem.rentalDays, 7);
      expect(cartItem.totalItemRental, 7000000.0); // 200000 * 5 * 7
      expect(cartItem.totalItemDeposit, 2500000.0); // 500000 * 5
    });

    test('fromMap should handle numeric type conversion', () {
      final data = {
        'productId': 'p1',
        'productName': 'Test',
        'imageUrl': '',
        'selectedSize': 'M',
        'selectedColor': 'Red',
        'rentalPricePerDay': 100000, // int should convert to double
        'depositPrice': 200000, // int should convert to double
        'branchId': 'b1',
        'branchName': 'B1',
        'branchAddress': 'Addr',
        'availableStock': 10,
        'quantity': 2,
        'rentalDays': 5,
      };

      final cartItem = CartItemModel.fromMap(data);

      expect(cartItem.rentalPricePerDay, isA<double>());
      expect(cartItem.rentalPricePerDay, 100000.0);
      expect(cartItem.depositPrice, isA<double>());
      expect(cartItem.depositPrice, 200000.0);
      expect(cartItem.availableStock, isA<int>());
      expect(cartItem.availableStock, 10);
      expect(cartItem.quantity, 2);
      expect(cartItem.rentalDays, 5);
    });

    test('calculation with zero values', () {
      final data = {
        'productId': 'p1',
        'productName': 'Test',
        'imageUrl': '',
        'selectedSize': 'M',
        'selectedColor': 'Red',
        'rentalPricePerDay': 0,
        'depositPrice': 0,
        'branchId': 'b1',
        'branchName': 'B1',
        'branchAddress': 'Addr',
        'quantity': 0,
        'rentalDays': 0,
      };

      final cartItem = CartItemModel.fromMap(data);

      expect(cartItem.totalItemRental, 0.0);
      expect(cartItem.totalItemDeposit, 0.0);
    });
  });
}
