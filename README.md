# Rentify 👗

**Ứng dụng cho thuê trang phục trực tuyến đa chi nhánh**

> Môn: Phát Triển Ứng Dụng Thiết Bị Di Động  
> Lớp: 65CNTT — Trường Đại học Thủy Lợi

---

## 📱 Giới thiệu

**Rentify** là ứng dụng di động giúp người dùng tìm kiếm và thuê trang phục (áo dài, váy cưới, đầm dạ hội, vest...) từ nhiều chi nhánh, với tính năng **gợi ý chi nhánh gần nhất** dựa trên GPS.

## ✨ Tính năng chính

- 🔐 Đăng nhập / Đăng ký (Firebase Auth)
- 🏠 Duyệt danh sách trang phục theo danh mục
- 🔍 Tìm kiếm theo tên, loại, size, giá
- 📍 **GPS** — gợi ý chi nhánh gần nhất
- 🗓️ Đặt thuê với chọn ngày bắt đầu & trả
- 📦 Quản lý đơn thuê, theo dõi trạng thái
- ❤️ Lưu sản phẩm yêu thích
- ⭐ Đánh giá sau khi thuê (có thể đính kèm ảnh từ camera)
- 👤 Hồ sơ cá nhân
- 🛠️ Admin: quản lý chi nhánh, sản phẩm, đơn thuê

## 🛠️ Công nghệ

| Thành phần | Công nghệ |
|-----------|-----------|
| Frontend | Flutter 3.x |
| Backend dữ liệu | Firebase Firestore |
| Hình ảnh | Supabase Storage |
| Xác thực | Firebase Auth |
| GPS | geolocator + geoflutterfire_plus |
| Routing | go_router |

## 📁 Cấu trúc thư mục

```
lib/
├── constants/        # Màu sắc, chuỗi, theme
├── models/           # Data models (Product, Order, Branch, User...)
├── services/         # Firebase, Supabase, Auth, GPS services
├── screens/
│   ├── auth/         # Đăng nhập, đăng ký
│   ├── home/         # Màn hình chính
│   ├── product/      # Chi tiết sản phẩm
│   ├── order/        # Đặt thuê, lịch sử đơn
│   ├── profile/      # Hồ sơ, yêu thích
│   └── admin/        # Quản trị viên
└── widgets/
    └── common/       # Widget dùng chung
```

## 👥 Thành viên nhóm

| STT | Họ và tên | MSSV |
|-----|-----------|------|
| 1 | Lê Thị Như Quỳnh (Nhóm trưởng) | 2351060484 |
| 2 | Lê Thu Giang | 2351060438 |
| 3 | Ngô Xuân Khánh | 2351060453 |
| 4 | Trần Vĩnh Bảo | |
| 5 | Nguyễn Quang Dũng | |

**Giáo viên hướng dẫn:** TS. Đỗ Oanh Cường

## 🚀 Chạy ứng dụng

```bash
# Cài dependencies
flutter pub get

# Chạy app
flutter run
```

## 🧪 Testing

**Status**: ✅ 59 tests passing

```bash
# Chạy tất cả tests
flutter test

# Chạy tests với coverage
flutter test --coverage
```

Xem chi tiết trong [TESTING.md](TESTING.md) hoặc [docs/TEST_SUMMARY.md](docs/TEST_SUMMARY.md)

**Test Coverage**:
- ✅ Models: 38 tests (ProductModel, OrderModel, UserModel, CartItemModel)
- ✅ Widgets: 21 tests (CustomButton, LoadingWidget, IconCircleButton)  
- 📊 Overall: ~35% code coverage

---

Project này cấu hình Android debug dùng chung `android/app/debug.keystore`, nên các máy trong team sẽ có cùng SHA khi chạy debug.

Checklist khi clone lần đầu:

1. Đảm bảo file `android/app/debug.keystore` có trong working tree.
2. Vào Firebase Console, kiểm tra app Android `com.rentify.rentify` đã có SHA-1/SHA-256 của keystore này.
3. Nếu Firebase thay đổi SHA hoặc OAuth, tải lại `android/app/google-services.json` mới nhất.

Lưu ý:

- Keystore này chỉ dùng cho môi trường debug nội bộ.
- Bản release phải dùng release keystore riêng, không dùng debug keystore.

## 🗄️ Thiết kế CSDL

Xem chi tiết tại thư mục `docs/DATABASE_DESIGN.md`
