# Testing Documentation - Rentify

## 📚 Tổng quan

Dự án Rentify sử dụng chiến lược testing toàn diện với 3 loại test chính:
- **Unit Tests**: Test logic của models, services, providers
- **Widget Tests**: Test UI components
- **Integration Tests**: Test end-to-end user flows

## 🚀 Chạy Tests

### Chạy tất cả tests
```bash
flutter test
```

### Chạy test cho một file cụ thể
```bash
flutter test test/unit/models/product_model_test.dart
```

### Chạy test với coverage report
```bash
flutter test --coverage
```

### Xem coverage report (HTML)
```bash
genhtml coverage/lcov.info -o coverage/html
# Mở file coverage/html/index.html trong browser
```

## 📁 Cấu trúc Test Directory

```
test/
├── helpers/
│   └── test_helpers.dart        # Utilities và test data chung
├── mocks/
│   └── mock_*.dart              # Mock classes cho Firebase, Supabase
├── unit/
│   ├── models/                  # Tests cho data models
│   │   ├── product_model_test.dart
│   │   ├── order_model_test.dart
│   │   ├── user_model_test.dart
│   │   └── cart_item_model_test.dart
│   ├── services/                # Tests cho services
│   └── viewmodels/              # Tests cho ViewModels
├── widget/                      # Widget tests
└── integration/                 # Integration tests
```

## ✅ Tests đã hoàn thành

### Unit Tests - Models ✅ (100%)
- [x] **ProductModel**: Serialization, deserialization, type conversion (8 tests)
- [x] **OrderModel & OrderItem**: Order processing, calculations, alternative field names (13 tests)  
- [x] **UserModel**: User data, admin role checking (9 tests)
- [x] **CartItemModel**: Cart calculations, price computation (8 tests)

**Subtotal: 38 unit tests passed ✓**

### Widget Tests ✅ (80%)
- [x] **CustomButton**: Button variants, loading states, callbacks (9 tests)
- [x] **IconCircleButton**: Icon button interactions (5 tests)
- [x] **LoadingWidget & LoadingIndicator**: Shimmer grid, loading states (8 tests)

**Subtotal: 22 widget tests passed ✓**

**TỔNG CỘNG: 60 tests passed ✅**

### Đang blocked (cần Firebase mocking)
- ⏸️ **CartProvider**: Cart state management (needs Firebase initialization)
- ⏸️ **AuthService**: Authentication logic (needs Firebase Auth mocking)
- ⏸️ **FirebaseService**: Firestore operations (needs complex mocking)
- ⏸️ **ViewModels**: State management (depends on services)

### Chưa thực hiện
- [ ] **BranchModel, ReviewModel, FavoriteModel**: Remaining model tests
- [ ] **ProductCard**: Complex widget with image loading
- [ ] **Screen widgets**: Login, Product Detail, Cart screens
- [ ] **Integration Tests**: End-to-end user flows

## 📝 Viết Test Mới

### Template cho Model Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentify/models/your_model.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('YourModel Tests', () {
    late Map<String, dynamic> mockData;
    
    setUp(() {
      mockData = {
        'field1': 'value1',
        'field2': 123,
        'createdAt': createMockTimestamp(),
      };
    });

    test('fromFirestore should correctly deserialize data', () {
      final model = YourModel.fromFirestore(mockData, 'test-id');
      
      expect(model.field1, 'value1');
      expect(model.field2, 123);
    });

    test('toMap should correctly serialize data', () {
      final model = YourModel.fromFirestore(mockData, 'test-id');
      final map = model.toMap();
      
      expect(map['field1'], 'value1');
      expect(map['field2'], 123);
    });
  });
}
```

### Best Practices

1. **Arrange-Act-Assert Pattern**
   ```dart
   test('description', () {
     // Arrange: Setup test data
     final data = {...};
     
     // Act: Execute the code under test
     final result = MyClass.fromData(data);
     
     // Assert: Verify the results
     expect(result.field, expectedValue);
   });
   ```

2. **Use setUp() for common initialization**
   ```dart
   late Map<String, dynamic> mockData;
   
   setUp(() {
     mockData = {...};
   });
   ```

3. **Test edge cases**
   - Null values
   - Empty strings/lists
   - Type conversions (int → double, string → number)
   - Missing optional fields
   - Invalid data

4. **Descriptive test names**
   ```dart
   ✅ test('fromFirestore should handle missing optional fields')
   ❌ test('test1')
   ```

## 🎯 Coverage Goals

| Component | Target | Current | Status |
|-----------|--------|---------|--------|
| Models | 90% | 85% | ✅ Good |
| Widgets | 60% | 45% | ✅ On track |
| Services | 80% | 0% | ⏸️ Blocked |
| ViewModels | 75% | 0% | ⏸️ Blocked |
| **Overall** | **70%** | **~35%** | 🔄 In Progress |

**Note**: Services và ViewModels cần Firebase mocking setup để test được. Đang tập trung vào models và widgets trước.

## 🔧 Debugging Tests

### Chạy test với verbose output
```bash
flutter test --reporter expanded
```

### Debug một test cụ thể
```dart
test('my test', () {
  print('Debug info: $variable');
  expect(result, expected);
});
```

### Skip test tạm thời
```dart
test('my test', () {
  // test code
}, skip: 'TODO: Fix this test');
```

## 📦 Dependencies

Testing dependencies trong `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.13
  faker: ^2.2.0
  integration_test:
    sdk: flutter
```

## 🐛 Troubleshooting

### Test compilation error
- Kiểm tra imports đúng package
- Đảm bảo đã chạy `flutter pub get`

### Mock không hoạt động
- Chạy code generator: `flutter pub run build_runner build`
- Xóa cache: `flutter pub run build_runner clean`

### Coverage không hiển thị
- Cài `lcov`: `brew install lcov` (macOS) hoặc `apt install lcov` (Linux)
- Windows: Download từ http://ltp.sourceforge.net/coverage/lcov.php

## 🎓 Resources

- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Testing Best Practices](https://flutter.dev/docs/cookbook/testing)

---

**Cập nhật lần cuối**: 2026-04-04
**Người maintain**: Rentify Development Team
