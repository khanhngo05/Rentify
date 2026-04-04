import 'package:flutter_test/flutter_test.dart';
import 'package:rentify/models/order_model.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('OrderItem Tests', () {
    test('fromMap should correctly deserialize data', () {
      final data = {
        'productId': 'prod-123',
        'productName': 'Áo dài truyền thống',
        'thumbnailUrl': 'https://example.com/image.jpg',
        'selectedSize': 'M',
        'selectedColor': 'Đỏ',
        'rentalPricePerDay': 200000.0,
        'depositAmount': 500000.0,
        'quantity': 2,
        'subtotal': 400000.0,
      };

      final item = OrderItem.fromMap(data);

      expect(item.productId, 'prod-123');
      expect(item.productName, 'Áo dài truyền thống');
      expect(item.thumbnailUrl, 'https://example.com/image.jpg');
      expect(item.selectedSize, 'M');
      expect(item.selectedColor, 'Đỏ');
      expect(item.rentalPricePerDay, 200000.0);
      expect(item.depositAmount, 500000.0);
      expect(item.quantity, 2);
      expect(item.subtotal, 400000.0);
    });

    test('fromMap should handle alternative field names', () {
      final data = {
        'productId': 'prod-123',
        'name': 'Product Name', // alternative to productName
        'imageUrl': 'https://example.com/image.jpg', // alternative to thumbnailUrl
        'size': 'L', // alternative to selectedSize
        'color': 'Blue', // alternative to selectedColor
        'pricePerDay': 150000, // alternative to rentalPricePerDay
        'depositPrice': 300000, // alternative to depositAmount
        'quantity': 1,
      };

      final item = OrderItem.fromMap(data);

      expect(item.productName, 'Product Name');
      expect(item.thumbnailUrl, 'https://example.com/image.jpg');
      expect(item.selectedSize, 'L');
      expect(item.selectedColor, 'Blue');
      expect(item.rentalPricePerDay, 150000.0);
      expect(item.depositAmount, 300000.0);
    });

    test('fromMap should calculate subtotal when not provided', () {
      final data = {
        'productId': 'prod-123',
        'productName': 'Test Product',
        'thumbnailUrl': '',
        'selectedSize': 'M',
        'selectedColor': 'Red',
        'rentalPricePerDay': 100000,
        'depositAmount': 200000,
        'quantity': 3,
        // No subtotal provided
      };

      final item = OrderItem.fromMap(data);

      expect(item.subtotal, 300000.0); // 100000 * 3
    });

    test('toMap should correctly serialize data', () {
      final item = OrderItem(
        productId: 'prod-123',
        productName: 'Test Product',
        thumbnailUrl: 'https://example.com/image.jpg',
        selectedSize: 'M',
        selectedColor: 'Red',
        rentalPricePerDay: 100000.0,
        depositAmount: 200000.0,
        quantity: 2,
        subtotal: 200000.0,
      );

      final map = item.toMap();

      expect(map['productId'], 'prod-123');
      expect(map['productName'], 'Test Product');
      expect(map['thumbnailUrl'], 'https://example.com/image.jpg');
      expect(map['selectedSize'], 'M');
      expect(map['selectedColor'], 'Red');
      expect(map['rentalPricePerDay'], 100000.0);
      expect(map['depositAmount'], 200000.0);
      expect(map['quantity'], 2);
      expect(map['subtotal'], 200000.0);
    });
  });

  group('OrderModel Tests', () {
    late Map<String, dynamic> mockOrderData;
    
    setUp(() {
      mockOrderData = {
        'userId': 'user-123',
        'branchId': 'branch-456',
        'branchName': 'Chi nhánh Hà Nội',
        'branchAddress': '123 Đường ABC, Hà Nội',
        'items': [
          {
            'productId': 'prod-1',
            'productName': 'Áo dài 1',
            'thumbnailUrl': 'https://example.com/1.jpg',
            'selectedSize': 'M',
            'selectedColor': 'Đỏ',
            'rentalPricePerDay': 200000,
            'depositAmount': 500000,
            'quantity': 1,
            'subtotal': 200000,
          },
          {
            'productId': 'prod-2',
            'productName': 'Áo dài 2',
            'thumbnailUrl': 'https://example.com/2.jpg',
            'selectedSize': 'L',
            'selectedColor': 'Xanh',
            'rentalPricePerDay': 150000,
            'depositAmount': 400000,
            'quantity': 2,
            'subtotal': 300000,
          },
        ],
        'rentalStartDate': createMockTimestamp(TestData.now),
        'rentalEndDate': createMockTimestamp(TestData.nextWeek),
        'rentalDays': 7,
        'totalRentalFee': 500000,
        'depositPaid': 900000,
        'status': 'pending',
        'deliveryAddress': '456 Đường XYZ, Hà Nội',
        'note': 'Giao hàng buổi sáng',
        'createdAt': createMockTimestamp(TestData.now),
        'updatedAt': createMockTimestamp(TestData.now),
      };
    });

    test('fromFirestore should correctly deserialize data', () {
      final order = OrderModel.fromFirestore(mockOrderData, TestData.testOrderId);

      expect(order.id, TestData.testOrderId);
      expect(order.userId, 'user-123');
      expect(order.branchId, 'branch-456');
      expect(order.branchName, 'Chi nhánh Hà Nội');
      expect(order.branchAddress, '123 Đường ABC, Hà Nội');
      expect(order.items.length, 2);
      expect(order.rentalDays, 7);
      expect(order.totalRentalFee, 500000);
      expect(order.depositPaid, 900000);
      expect(order.status, 'pending');
      expect(order.deliveryAddress, '456 Đường XYZ, Hà Nội');
      expect(order.note, 'Giao hàng buổi sáng');
    });

    test('fromFirestore should handle alternative field names', () {
      final data = {
        'userId': 'user-123',
        'branch': 'branch-456', // alternative to branchId and branchName
        'branchAddress': 'Test Address',
        'items': [],
        'startDate': createMockTimestamp(TestData.now), // alternative to rentalStartDate
        'endDate': createMockTimestamp(TestData.tomorrow), // alternative to rentalEndDate
        'rentalDays': 1,
        'totalRentalPrice': 100000, // alternative to totalRentalFee
        'totalDepositPrice': 200000, // alternative to depositPaid
        'address': 'Delivery Address', // alternative to deliveryAddress
        'status': 'confirmed',
        'createdAt': createMockTimestamp(),
        'updatedAt': createMockTimestamp(),
      };

      final order = OrderModel.fromFirestore(data, 'order-123');

      expect(order.branchId, 'branch-456');
      expect(order.branchName, 'branch-456');
      expect(order.totalRentalFee, 100000);
      expect(order.depositPaid, 200000);
      expect(order.deliveryAddress, 'Delivery Address');
    });

    test('totalItemCount should calculate correctly', () {
      final order = OrderModel.fromFirestore(mockOrderData, 'order-123');
      expect(order.totalItemCount, 3); // 1 + 2
    });

    test('fromFirestore should handle empty items list', () {
      mockOrderData['items'] = [];
      final order = OrderModel.fromFirestore(mockOrderData, 'order-123');
      
      expect(order.items, isEmpty);
      expect(order.totalItemCount, 0);
    });

    test('fromFirestore should handle missing note', () {
      mockOrderData.remove('note');
      final order = OrderModel.fromFirestore(mockOrderData, 'order-123');
      
      expect(order.note, isNull);
    });

    test('toMap should correctly serialize data', () {
      final order = OrderModel.fromFirestore(mockOrderData, TestData.testOrderId);
      final map = order.toMap();

      expect(map['userId'], 'user-123');
      expect(map['branchId'], 'branch-456');
      expect(map['branchName'], 'Chi nhánh Hà Nội');
      expect(map['branchAddress'], '123 Đường ABC, Hà Nội');
      expect(map['items'], isA<List>());
      expect((map['items'] as List).length, 2);
      expect(map['rentalDays'], 7);
      expect(map['totalRentalFee'], 500000);
      expect(map['depositPaid'], 900000);
      expect(map['status'], 'pending');
      expect(map['deliveryAddress'], '456 Đường XYZ, Hà Nội');
      expect(map['note'], 'Giao hàng buổi sáng');
      expect(map['rentalStartDate'], isA<dynamic>());
      expect(map['rentalEndDate'], isA<dynamic>());
      expect(map['createdAt'], isA<dynamic>());
      expect(map['updatedAt'], isA<dynamic>());
    });

    test('default status should be pending', () {
      mockOrderData.remove('status');
      final order = OrderModel.fromFirestore(mockOrderData, 'order-123');
      
      expect(order.status, 'pending');
    });
  });

  group('Helper Functions Tests', () {
    test('_asDouble should convert various types correctly', () {
      // This tests the helper function indirectly through OrderItem
      final data1 = {
        'productId': 'p1',
        'productName': 'Test',
        'thumbnailUrl': '',
        'selectedSize': 'M',
        'selectedColor': 'Red',
        'rentalPricePerDay': 100000, // int
        'depositAmount': '200000', // string
        'quantity': 1,
      };
      
      final item = OrderItem.fromMap(data1);
      expect(item.rentalPricePerDay, 100000.0);
      expect(item.depositAmount, 200000.0);
    });

    test('_asInt should convert various types correctly', () {
      final data = {
        'productId': 'p1',
        'productName': 'Test',
        'thumbnailUrl': '',
        'selectedSize': 'M',
        'selectedColor': 'Red',
        'rentalPricePerDay': 100000,
        'depositAmount': 200000,
        'quantity': '3', // string
      };
      
      final item = OrderItem.fromMap(data);
      expect(item.quantity, 3);
    });
  });
}
