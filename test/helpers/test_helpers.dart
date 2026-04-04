/// Test utilities and helpers
library test_helpers;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Create a mock Timestamp for testing
Timestamp createMockTimestamp([DateTime? dateTime]) {
  final dt = dateTime ?? DateTime.now();
  return Timestamp.fromDate(dt);
}

/// Common test data
class TestData {
  static final DateTime now = DateTime.now();
  static final DateTime tomorrow = now.add(const Duration(days: 1));
  static final DateTime nextWeek = now.add(const Duration(days: 7));
  
  static const String testUserId = 'test-user-123';
  static const String testProductId = 'test-product-456';
  static const String testBranchId = 'test-branch-789';
  static const String testOrderId = 'test-order-999';
  
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'Test123456';
  static const String testDisplayName = 'Test User';
  static const String testPhoneNumber = '0912345678';
}
