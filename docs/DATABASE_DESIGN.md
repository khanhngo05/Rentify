# 🗄️ Thiết kế CSDL — Ứng dụng Cho Thuê Trang Phục Đa Chi Nhánh

> **Môn:** Phát Triển Ứng Dụng Thiết Bị Di Động  
> **Đề tài:** Xây dựng ứng dụng cho thuê trang phục trực tuyến trên thiết bị di động  
> **Lớp:** 65CNTT — Trường Đại học Thủy Lợi  
> **Công nghệ:** Flutter · Firebase Firestore · Supabase Storage  
> **Phiên bản:** 2.0 — Hỗ trợ đa chi nhánh + GPS

---

## 1. Tổng quan kiến trúc

### Mô hình nghiệp vụ
```
                        ┌─────────┐
                        │  ADMIN  │ ← Quản lý toàn bộ hệ thống
                        └────┬────┘
                             │ quản lý
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │Chi nhánh │  │Chi nhánh │  │Chi nhánh │
        │  Đống Đa │  │ Cầu Giấy │  │Thanh Xuân│
        └────┬─────┘  └────┬─────┘  └────┬─────┘
             │              │              │
             └──────────────┼──────────────┘
                            │ mỗi chi nhánh có tồn kho riêng
                            ▼
                    ┌──────────────┐
                    │   Products   │ ← Danh mục sản phẩm chung
                    └──────────────┘
                            │
                    ┌───────┴────────┐
                    ▼                ▼
              ┌──────────┐    ┌──────────┐
              │  Orders  │    │ Reviews  │
              └──────────┘    └──────────┘
```

### Kiến trúc lưu trữ
```
┌──────────────────────────────────────────────────────────────────┐
│                        Flutter Mobile App                        │
└─────────────────┬───────────────────────────┬────────────────────┘
                  │                           │
                  ▼                           ▼
   ┌──────────────────────────┐   ┌──────────────────────────────┐
   │    Firebase Firestore    │   │      Supabase Storage        │
   │   (Dữ liệu cấu trúc)    │   │        (Hình ảnh)            │
   │                          │   │                              │
   │  ├── users               │   │  bucket: fashion-images/     │
   │  ├── branches ◄── GPS    │   │  ├── branches/{branchId}/    │
   │  │   └── inventory/      │   │  ├── products/{productId}/   │
   │  ├── products            │   │  ├── reviews/{reviewId}/     │
   │  ├── orders              │   │  └── avatars/{userId}/       │
   │  ├── reviews             │   │                              │
   │  └── favorites           │   └──────────────────────────────┘
   └──────────────────────────┘
```

---

## 2. Sơ đồ ERD

```
┌──────────────┐       ┌──────────────────────────┐
│    users     │       │         branches          │
├──────────────┤       ├──────────────────────────┤
│ uid (PK)     │       │ branchId (PK)             │
│ email        │       │ name                      │
│ displayName  │       │ address                   │
│ phoneNumber  │       │ location (GeoPoint) ◄─GPS │
│ avatarUrl    │       │ geohash                   │
│ address      │       │ phone                     │
│ role         │       │ email                     │
│ createdAt    │       │ imageUrl                  │
└──────┬───────┘       │ openingHours              │
       │               │ isActive                  │
       │               │ createdAt                 │
       │               └────────────┬─────────────┘
       │                            │ 1
       │                            │ (subcollection)
       │                            │ N
       │               ┌────────────▼─────────────┐
       │               │      branch_inventory     │
       │               │  (branches/{id}/inventory)│
       │               ├──────────────────────────┤
       │               │ productId (FK)            │
       │               │ totalStock                │
       │               │ availableStock            │
       │               │ updatedAt                 │
       │               └──────────────────────────┘
       │
       │               ┌──────────────────────────┐
       │               │        products           │
       │               ├──────────────────────────┤
       │               │ productId (PK)            │
       │               │ name                      │
       │               │ description               │
       │               │ rentalPricePerDay         │
       │               │ depositAmount             │
       │               │ thumbnailUrl              │
       │               │ imageUrls[]               │
       │               │ category                  │
       │               │ sizes[]                   │
       │               │ colors[]                  │
       │               │ brand                     │
       │               │ rating                    │
       │               │ reviewCount               │
       │               │ isActive                  │
       │               │ tags[]                    │
       │               │ createdAt / updatedAt     │
       │               └────────────┬─────────────┘
       │                            │
       │ 1                          │ 1
       │                            │
       │ N                          │ N
┌──────▼───────────────┐  ┌─────────▼────────────┐
│        orders        │  │       reviews         │
├──────────────────────┤  ├──────────────────────┤
│ orderId (PK)         │  │ reviewId (PK)         │
│ userId (FK)          │  │ productId (FK)        │
│ branchId (FK)   ◄────┘  │ branchId (FK)        │
│ items[]              │  │ userId (FK)           │
│ rentalStartDate      │  │ orderId (FK)          │
│ rentalEndDate        │  │ rating                │
│ rentalDays           │  │ comment               │
│ totalRentalFee       │  │ photoUrls[]           │
│ depositPaid          │  │ createdAt             │
│ status               │  └──────────────────────┘
│ deliveryAddress      │
│ note                 │  ┌──────────────────────┐
│ createdAt/updatedAt  │  │      favorites        │
└──────────────────────┘  ├──────────────────────┤
                          │ userId (FK)           │
                          │ productId (FK)        │
                          │ addedAt               │
                          └──────────────────────┘
```

---

## 3. Chi tiết Collections Firestore

### 3.1. Collection `users`
**Đường dẫn:** `users/{userId}`

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `uid` | `string` | ✅ | Firebase Auth UID |
| `email` | `string` | ✅ | Email đăng nhập |
| `displayName` | `string` | ✅ | Tên hiển thị |
| `phoneNumber` | `string` | ❌ | Số điện thoại liên hệ |
| `avatarUrl` | `string` | ❌ | URL ảnh đại diện (Supabase) |
| `address` | `string` | ❌ | Địa chỉ giao/nhận mặc định |
| `role` | `string` | ✅ | `"user"` hoặc `"admin"` |
| `createdAt` | `timestamp` | ✅ | Thời điểm tạo tài khoản |

```json
{
  "uid": "user_003",
  "email": "khach@example.com",
  "displayName": "Trần Thị Bích",
  "phoneNumber": "0901234567",
  "avatarUrl": "https://<project>.supabase.co/storage/v1/object/public/fashion-images/avatars/user_003.jpg",
  "address": "78 Trường Chinh, Đống Đa, Hà Nội",
  "role": "user",
  "createdAt": "2026-02-01T10:00:00Z"
}
```

---

### 3.2. Collection `branches` ⭐ (Chi nhánh — có GPS)
**Đường dẫn:** `branches/{branchId}`

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `name` | `string` | ✅ | Tên chi nhánh, VD: "Chi nhánh Đống Đa" |
| `address` | `string` | ✅ | Địa chỉ đầy đủ |
| `location` | `GeoPoint` | ✅ | **Tọa độ GPS** (`latitude`, `longitude`) |
| `geohash` | `string` | ✅ | **Geohash** để query vị trí nhanh |
| `phone` | `string` | ✅ | Số điện thoại chi nhánh |
| `email` | `string` | ❌ | Email chi nhánh |
| `imageUrl` | `string` | ❌ | Ảnh cửa hàng (Supabase) |
| `openingHours` | `map` | ✅ | Giờ mở cửa theo ngày trong tuần |
| `isActive` | `boolean` | ✅ | Chi nhánh đang hoạt động hay không |
| `createdAt` | `timestamp` | ✅ | Ngày tạo chi nhánh |

**Cấu trúc `openingHours`:**
```json
{
  "monday":    { "open": "08:00", "close": "21:00", "isOpen": true },
  "tuesday":   { "open": "08:00", "close": "21:00", "isOpen": true },
  "wednesday": { "open": "08:00", "close": "21:00", "isOpen": true },
  "thursday":  { "open": "08:00", "close": "21:00", "isOpen": true },
  "friday":    { "open": "08:00", "close": "22:00", "isOpen": true },
  "saturday":  { "open": "09:00", "close": "22:00", "isOpen": true },
  "sunday":    { "open": "09:00", "close": "20:00", "isOpen": true }
}
```

**Ví dụ document:**
```json
{
  "name": "Chi nhánh Đống Đa",
  "address": "15 Phố Huế, Hai Bà Trưng, Hà Nội",
  "location": { "latitude": 21.0178, "longitude": 105.8412 },
  "geohash": "w3gv2e",
  "phone": "024.3825.1234",
  "email": "dongda@fashionrental.vn",
  "imageUrl": "https://<project>.supabase.co/storage/v1/object/public/fashion-images/branches/branch_001/store.jpg",
  "openingHours": {
    "monday":  { "open": "08:00", "close": "21:00", "isOpen": true },
    "sunday":  { "open": "09:00", "close": "20:00", "isOpen": true }
  },
  "isActive": true,
  "createdAt": "2026-01-01T00:00:00Z"
}
```

> **📡 Giải thích GPS:**
> - `location` (GeoPoint): Lưu tọa độ thực của chi nhánh
> - `geohash`: Chuỗi mã hóa tọa độ, dùng với thư viện `geoflutterfire_plus` để query "tìm chi nhánh trong bán kính X km" một cách hiệu quả
> - App sẽ lấy vị trí user → tính khoảng cách → sắp xếp danh sách chi nhánh

---

### 3.3. Subcollection `branches/{branchId}/inventory` ⭐ (Tồn kho theo chi nhánh)
**Đường dẫn:** `branches/{branchId}/inventory/{productId}`

Mỗi chi nhánh có tồn kho riêng cho từng sản phẩm.

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `productId` | `string` | ✅ | ID sản phẩm (trùng với document ID) |
| `totalStock` | `number` | ✅ | Tổng số lượng chi nhánh này có |
| `availableStock` | `number` | ✅ | Số lượng đang có thể thuê |
| `updatedAt` | `timestamp` | ✅ | Lần cập nhật tồn kho cuối |

```json
{
  "productId": "prod_001",
  "totalStock": 3,
  "availableStock": 2,
  "updatedAt": "2026-03-25T10:00:00Z"
}
```

---

### 3.4. Collection `products` (Danh mục sản phẩm — dùng chung)
**Đường dẫn:** `products/{productId}`

Admin tạo sản phẩm một lần, tất cả chi nhánh dùng chung catalog. Tồn kho từng chi nhánh lưu ở **subcollection inventory** trên.

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `name` | `string` | ✅ | Tên trang phục |
| `description` | `string` | ✅ | Mô tả chi tiết |
| `rentalPricePerDay` | `number` | ✅ | Giá thuê mỗi ngày (VNĐ) |
| `depositAmount` | `number` | ✅ | Tiền đặt cọc (VNĐ) |
| `thumbnailUrl` | `string` | ✅ | Ảnh đại diện chính (Supabase) |
| `imageUrls` | `array<string>` | ✅ | Danh sách ảnh chi tiết (Supabase) |
| `category` | `string` | ✅ | Danh mục |
| `sizes` | `array<string>` | ✅ | Các size có sẵn |
| `colors` | `array<string>` | ✅ | Màu sắc có sẵn |
| `brand` | `string` | ❌ | Thương hiệu / nhà thiết kế |
| `rating` | `number` | ✅ | Điểm đánh giá trung bình (0.0–5.0) |
| `reviewCount` | `number` | ✅ | Tổng số đánh giá |
| `isActive` | `boolean` | ✅ | Sản phẩm còn hoạt động không |
| `tags` | `array<string>` | ❌ | Tag hỗ trợ tìm kiếm |
| `createdAt` | `timestamp` | ✅ | Ngày thêm |
| `updatedAt` | `timestamp` | ✅ | Ngày cập nhật |

**Danh sách `category`:**
| Giá trị | Ý nghĩa |
|---------|---------|
| `"ao_dai"` | Áo dài |
| `"vay_cuoi"` | Váy cưới |
| `"dam_da_hoi"` | Đầm dạ hội |
| `"vest_suit"` | Vest / Suit nam |
| `"hanbok"` | Hanbok / Trang phục quốc tế |
| `"trang_phuc_dan_toc"` | Trang phục dân tộc |
| `"trang_phuc_chup_anh"` | Trang phục chụp ảnh du lịch |
| `"phu_kien"` | Phụ kiện đi kèm |

```json
{
  "name": "Áo Dài Gấm Đỏ Thêu Phượng",
  "description": "Áo dài gấm đỏ truyền thống, thêu hoa phượng tinh xảo. Phù hợp Tết, đám hỏi, lễ hội.",
  "rentalPricePerDay": 250000,
  "depositAmount": 1000000,
  "thumbnailUrl": "https://<project>.supabase.co/storage/v1/object/public/fashion-images/products/prod_001/main.jpg",
  "imageUrls": ["...img_1.jpg", "...img_2.jpg"],
  "category": "ao_dai",
  "sizes": ["S", "M", "L"],
  "colors": ["Đỏ", "Vàng gold"],
  "brand": "NTK Minh Hạnh",
  "rating": 4.8,
  "reviewCount": 56,
  "isActive": true,
  "tags": ["áo dài", "lễ hội", "tết", "truyền thống"],
  "createdAt": "2026-01-15T10:00:00Z",
  "updatedAt": "2026-03-20T14:00:00Z"
}
```

---

### 3.5. Collection `orders` (Đơn thuê)
**Đường dẫn:** `orders/{orderId}`

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `userId` | `string` | ✅ | UID người thuê |
| `branchId` | `string` | ✅ | **ID chi nhánh** được chọn |
| `branchName` | `string` | ✅ | Tên chi nhánh (snapshot) |
| `branchAddress` | `string` | ✅ | Địa chỉ chi nhánh (snapshot) |
| `items` | `array<OrderItem>` | ✅ | Danh sách sản phẩm thuê |
| `rentalStartDate` | `timestamp` | ✅ | Ngày bắt đầu thuê |
| `rentalEndDate` | `timestamp` | ✅ | Ngày trả trang phục |
| `rentalDays` | `number` | ✅ | Số ngày thuê |
| `totalRentalFee` | `number` | ✅ | Tổng tiền thuê (VNĐ) |
| `depositPaid` | `number` | ✅ | Tổng tiền cọc (VNĐ) |
| `status` | `string` | ✅ | Trạng thái (xem bên dưới) |
| `deliveryAddress` | `string` | ✅ | Địa chỉ giao nhận |
| `note` | `string` | ❌ | Ghi chú của khách |
| `createdAt` | `timestamp` | ✅ | Thời điểm đặt |
| `updatedAt` | `timestamp` | ✅ | Cập nhật trạng thái |

**Cấu trúc `OrderItem`:**
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `productId` | `string` | ID sản phẩm |
| `productName` | `string` | Tên (snapshot) |
| `thumbnailUrl` | `string` | Ảnh (snapshot) |
| `selectedSize` | `string` | Size đã chọn |
| `selectedColor` | `string` | Màu đã chọn |
| `rentalPricePerDay` | `number` | Giá thuê/ngày tại thời điểm đặt |
| `depositAmount` | `number` | Tiền cọc tại thời điểm đặt |
| `quantity` | `number` | Số lượng |
| `subtotal` | `number` | Thành tiền thuê |

**Vòng đời `status`:**
```
[pending] → [confirmed] → [renting] → [returned] → [completed]
    └──────────────────────────────────────────────→ [cancelled]
```

| Giá trị | Ý nghĩa |
|---------|---------|
| `"pending"` | Đã đặt, chờ xác nhận từ chi nhánh |
| `"confirmed"` | Chi nhánh đã xác nhận, chuẩn bị giao |
| `"renting"` | Khách đang thuê |
| `"returned"` | Đã trả, chi nhánh đang kiểm tra |
| `"completed"` | Hoàn thành, hoàn cọc |
| `"cancelled"` | Đã hủy |

---

### 3.6. Collection `reviews` (Đánh giá)
**Đường dẫn:** `reviews/{reviewId}`

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `productId` | `string` | ✅ | ID sản phẩm |
| `branchId` | `string` | ✅ | ID chi nhánh đã thuê |
| `userId` | `string` | ✅ | UID người đánh giá |
| `orderId` | `string` | ✅ | ID đơn thuê liên quan |
| `rating` | `number` | ✅ | Điểm 1–5 |
| `comment` | `string` | ❌ | Nội dung đánh giá |
| `photoUrls` | `array<string>` | ❌ | Ảnh thực tế (camera → Supabase) |
| `createdAt` | `timestamp` | ✅ | Thời điểm đánh giá |

---

### 3.7. Collection `favorites` (Yêu thích)
**Đường dẫn:** `favorites/{userId}/items/{productId}`

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `productId` | `string` | ✅ | ID sản phẩm |
| `productName` | `string` | ✅ | Tên (snapshot) |
| `thumbnailUrl` | `string` | ✅ | Ảnh (snapshot) |
| `rentalPricePerDay` | `number` | ✅ | Giá thuê (snapshot) |
| `addedAt` | `timestamp` | ✅ | Thời điểm thêm vào yêu thích |

---

## 4. Supabase Storage

### Bucket: `fashion-images` (Public)

```
fashion-images/
├── branches/
│   └── {branchId}/
│       └── store.jpg           ← Ảnh mặt tiền cửa hàng
├── products/
│   └── {productId}/
│       ├── main.jpg            ← Ảnh đại diện (thumbnailUrl)
│       ├── img_1.jpg
│       └── img_2.jpg
├── reviews/
│   └── {reviewId}/
│       ├── photo_1.jpg         ← Ảnh thực tế chụp từ camera
│       └── photo_2.jpg
└── avatars/
    └── {userId}.jpg            ← Ảnh đại diện người dùng
```

### Policies

| Hành động | Điều kiện |
|-----------|-----------|
| `SELECT` | Public — ai cũng xem được |
| `INSERT` | Authenticated — phải đăng nhập |
| `UPDATE/DELETE` | Chủ sở hữu hoặc Admin |

---

## 5. Tính năng GPS — Gợi ý chi nhánh gần nhất

### Cách hoạt động
```
1. App xin quyền GPS của user
        ↓
2. Lấy tọa độ hiện tại (lat, lng) của user
        ↓
3. Query Firestore: lấy tất cả branches đang isActive = true
        ↓
4. Tính khoảng cách từ user đến từng chi nhánh
   (dùng công thức Haversine hoặc geoflutterfire_plus)
        ↓
5. Sắp xếp danh sách theo khoảng cách tăng dần
        ↓
6. Hiển thị: "Chi nhánh Đống Đa — cách bạn 1.2 km"
```

### Flutter packages cần dùng

| Package | Mục đích |
|---------|---------|
| `geolocator` | Lấy vị trí GPS của user |
| `geoflutterfire_plus` | Query geospatial trên Firestore bằng Geohash |
| `google_maps_flutter` | Hiển thị bản đồ + marker chi nhánh |

### Công thức tính khoảng cách (Haversine) — tham khảo
```dart
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0; // Bán kính Trái Đất (km)
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}
double _toRad(double deg) => deg * pi / 180;
```

### Cách tạo Geohash khi thêm chi nhánh
```dart
// Dùng package: geoflutterfire_plus
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

final geoFirePoint = GeoFirePoint(GeoPoint(latitude, longitude));
final geohash = geoFirePoint.geohash; // Lưu vào Firestore
```

---

## 6. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    function isAdmin() {
      return isAuthenticated() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // ── users ───────────────────────────────────────────────────────
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isAdmin();
    }

    // ── branches ────────────────────────────────────────────────────
    // Công khai: ai cũng xem được (để hiển thị bản đồ)
    // Chỉ admin mới quản lý chi nhánh
    match /branches/{branchId} {
      allow read: if true;
      allow create, update, delete: if isAdmin();

      // Tồn kho: admin quản lý, user chỉ đọc
      match /inventory/{productId} {
        allow read: if true;
        allow write: if isAdmin();
      }
    }

    // ── products ────────────────────────────────────────────────────
    match /products/{productId} {
      allow read: if true;
      allow create, update, delete: if isAdmin();
    }

    // ── orders ──────────────────────────────────────────────────────
    match /orders/{orderId} {
      allow read: if isAuthenticated() &&
        (resource.data.userId == request.auth.uid || isAdmin());
      allow create: if isAuthenticated();
      allow update: if isAdmin() ||
        (isAuthenticated() &&
         resource.data.userId == request.auth.uid &&
         request.resource.data.status == 'cancelled' &&
         resource.data.status == 'pending');
      allow delete: if isAdmin();
    }

    // ── reviews ─────────────────────────────────────────────────────
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() &&
        resource.data.userId == request.auth.uid;
    }

    // ── favorites ───────────────────────────────────────────────────
    match /favorites/{userId}/items/{productId} {
      allow read, write: if isOwner(userId);
    }
  }
}
```

---

## 7. Firestore Indexes

| Collection | Fields | Dùng cho |
|-----------|--------|---------|
| `products` | `category` ↑, `rating` ↓ | Lọc danh mục + sort rating |
| `products` | `isActive` ↑, `rentalPricePerDay` ↑ | Lọc sản phẩm active + sort giá |
| `products` | `category` ↑, `rentalPricePerDay` ↑ | Lọc danh mục + sort giá |
| `branches` | `isActive` ↑, `name` ↑ | Danh sách chi nhánh đang hoạt động |
| `orders` | `userId` ↑, `createdAt` ↓ | Lịch sử đơn của user |
| `orders` | `branchId` ↑, `status` ↑, `createdAt` ↓ | Quản lý đơn theo chi nhánh |
| `orders` | `status` ↑, `createdAt` ↓ | Admin quản lý tất cả đơn |
| `reviews` | `productId` ↑, `createdAt` ↓ | Đánh giá theo sản phẩm |
| `reviews` | `branchId` ↑, `createdAt` ↓ | Đánh giá theo chi nhánh |

---

## 8. Tóm tắt

| Thành phần | Công nghệ | Nội dung |
|-----------|-----------|---------|
| Người dùng | Firestore `users` | Hồ sơ, địa chỉ, vai trò admin/user |
| **Chi nhánh + GPS** | Firestore `branches` | Tên, địa chỉ, **GeoPoint**, **Geohash**, giờ mở cửa |
| **Tồn kho chi nhánh** | Firestore `branches/{id}/inventory` | Stock riêng mỗi chi nhánh theo từng sản phẩm |
| Sản phẩm (catalog chung) | Firestore `products` | Thông tin, giá thuê, tiền cọc |
| Đơn thuê | Firestore `orders` | Liên kết user + **chi nhánh** + sản phẩm |
| Đánh giá | Firestore `reviews` | Điểm, nhận xét, ảnh camera |
| Yêu thích | Firestore `favorites/{uid}/items` | Danh sách riêng từng user |
| Ảnh cửa hàng | Supabase `fashion-images/branches/` | Hình chi nhánh |
| Ảnh sản phẩm | Supabase `fashion-images/products/` | Nhiều ảnh/sản phẩm |
| Ảnh đánh giá | Supabase `fashion-images/reviews/` | Ảnh thực tế chụp từ camera |
| Ảnh đại diện | Supabase `fashion-images/avatars/` | Avatar người dùng |
