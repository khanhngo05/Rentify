import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentify/models/user_model.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('UserModel Tests', () {
    late Map<String, dynamic> mockUserData;

    setUp(() {
      mockUserData = {
        'email': TestData.testEmail,
        'displayName': TestData.testDisplayName,
        'phoneNumber': TestData.testPhoneNumber,
        'avatarUrl': 'https://example.com/avatar.jpg',
        'address': '123 Test Street, Hanoi',
        'role': 'user',
        'createdAt': createMockTimestamp(TestData.now),
      };
    });

    test('fromFirestore should correctly deserialize data', () {
      final user = UserModel.fromFirestore(mockUserData, TestData.testUserId);

      expect(user.uid, TestData.testUserId);
      expect(user.email, TestData.testEmail);
      expect(user.displayName, TestData.testDisplayName);
      expect(user.phoneNumber, TestData.testPhoneNumber);
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.address, '123 Test Street, Hanoi');
      expect(user.role, 'user');
      expect(user.isAdmin, false);
    });

    test('fromFirestore should handle missing optional fields', () {
      final minimalData = {
        'email': 'minimal@test.com',
        'displayName': 'Minimal User',
        'createdAt': createMockTimestamp(),
      };

      final user = UserModel.fromFirestore(minimalData, 'user-123');

      expect(user.uid, 'user-123');
      expect(user.email, 'minimal@test.com');
      expect(user.displayName, 'Minimal User');
      expect(user.phoneNumber, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.address, isNull);
      expect(user.role, 'user');
      expect(user.isAdmin, false);
    });

    test('isAdmin should return true for admin role', () {
      mockUserData['role'] = 'admin';
      final user = UserModel.fromFirestore(mockUserData, 'admin-123');

      expect(user.role, 'admin');
      expect(user.isAdmin, true);
    });

    test('isAdmin should return false for non-admin roles', () {
      final roles = ['user', 'moderator', 'customer', ''];
      
      for (final role in roles) {
        mockUserData['role'] = role;
        final user = UserModel.fromFirestore(mockUserData, 'user-123');
        expect(user.isAdmin, false, reason: 'Role "$role" should not be admin');
      }
    });

    test('toMap should correctly serialize data', () {
      final user = UserModel.fromFirestore(mockUserData, TestData.testUserId);
      final map = user.toMap();

      expect(map['email'], TestData.testEmail);
      expect(map['displayName'], TestData.testDisplayName);
      expect(map['phoneNumber'], TestData.testPhoneNumber);
      expect(map['avatarUrl'], 'https://example.com/avatar.jpg');
      expect(map['address'], '123 Test Street, Hanoi');
      expect(map['role'], 'user');
      expect(map['createdAt'], isA<Timestamp>());
      // uid should NOT be in toMap (it's the document ID)
      expect(map.containsKey('uid'), false);
    });

    test('toMap should include null values for optional fields', () {
      final minimalData = {
        'email': 'test@test.com',
        'displayName': 'Test',
        'createdAt': createMockTimestamp(),
      };

      final user = UserModel.fromFirestore(minimalData, 'user-123');
      final map = user.toMap();

      expect(map['phoneNumber'], isNull);
      expect(map['avatarUrl'], isNull);
      expect(map['address'], isNull);
    });

    test('fromFirestore should use default role when not provided', () {
      mockUserData.remove('role');
      final user = UserModel.fromFirestore(mockUserData, 'user-123');

      expect(user.role, 'user');
      expect(user.isAdmin, false);
    });

    test('fromFirestore should handle empty strings', () {
      final data = {
        'email': '',
        'displayName': '',
        'phoneNumber': '',
        'role': '',
        'createdAt': createMockTimestamp(),
      };

      final user = UserModel.fromFirestore(data, 'user-123');

      expect(user.email, '');
      expect(user.displayName, '');
      expect(user.phoneNumber, '');
      expect(user.role, '');
    });

    test('roundtrip serialization should preserve data', () {
      final originalUser = UserModel.fromFirestore(mockUserData, TestData.testUserId);
      final map = originalUser.toMap();
      final restoredUser = UserModel.fromFirestore(map, TestData.testUserId);

      expect(restoredUser.email, originalUser.email);
      expect(restoredUser.displayName, originalUser.displayName);
      expect(restoredUser.phoneNumber, originalUser.phoneNumber);
      expect(restoredUser.avatarUrl, originalUser.avatarUrl);
      expect(restoredUser.address, originalUser.address);
      expect(restoredUser.role, originalUser.role);
    });
  });
}
