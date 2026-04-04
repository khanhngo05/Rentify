# 🗄️ Database Design - Rentify

> **Firestore NoSQL Database Schema for Rentify Clothing Rental App**

---

## 📋 Table of Contents

- [Overview](#overview)
- [Collections Structure](#collections-structure)
  - [1. Users](#1-users-collection)
  - [2. Products](#2-products-collection)
  - [3. Orders](#3-orders-collection)
  - [4. Reviews](#4-reviews-collection)
  - [5. Branches](#5-branches-collection)
  - [6. Favorites](#6-favorites-collection)
  - [7. Carts](#7-carts-collection)
- [Relationships](#relationships)
- [Indexes](#indexes)
- [Security Rules](#security-rules)
- [Denormalization Strategy](#denormalization-strategy)
- [Query Patterns](#query-patterns)

---

## Overview

Rentify sử dụng **Firebase Firestore** - một NoSQL document database cloud-based với cấu trúc linh hoạt và realtime sync.

### Database Characteristics

| Property | Value |
|----------|-------|
| **Type** | NoSQL Document Database |
| **Provider** | Firebase Firestore |
| **Total Collections** | 7 main collections |
| **Subcollections** | 2 (inventory, favorites/items) |
| **Data Model** | Document-oriented with selective denormalization |
| **Scalability** | Automatic horizontal scaling by Firebase |

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    FIRESTORE DATABASE                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────┐  ┌──────────┐  ┌────────┐  ┌─────────┐        │
│  │  users  │  │ products │  │ orders │  │ reviews │        │
│  └─────────┘  └──────────┘  └────────┘  └─────────┘        │
│                                                              │
│  ┌──────────┐  ┌───────────┐  ┌───────┐                    │
│  │ branches │  │ favorites │  │ carts │                    │
│  │    │     │  └───────────┘  └───────┘                    │
│  │    └─inventory (subcollection)                          │
│  └──────────┘                                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Collections Structure

### 1. Users Collection

**Collection Path**: `users/{userId}`

Lưu trữ thông tin tài khoản người dùng.

#### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `uid` | String | ✅ | Document ID (Firebase Auth UID) |
| `email` | String | ✅ | Email address |
| `displayName` | String | ✅ | Tên hiển thị |
| `phoneNumber` | String | ❌ | Số điện thoại |
| `avatarUrl` | String | ❌ | URL ảnh đại diện |
| `address` | String | ❌ | Địa chỉ giao hàng |
| `role` | String | ✅ | Role: `'user'` hoặc `'admin'` |
| `createdAt` | Timestamp | ✅ | Ngày tạo tài khoản |

#### Example Document

```json
{
  "uid": "abc123xyz",
  "email": "user@example.com",
  "displayName": "Nguyễn Văn A",
  "phoneNumber": "0912345678",
  "avatarUrl": "https://storage.supabase.co/avatars/user123.jpg",
  "address": "123 Đường ABC, Quận 1, TP.HCM",
  "role": "user",
  "createdAt": "2026-01-15T10:30:00Z"
}
```

---

### 2. Products Collection

**Collection Path**: `products/{productId}`

Lưu trữ thông tin sản phẩm cho thuê.

#### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | ✅ | Document ID |
| `name` | String | ✅ | Tên sản phẩm |
| `description` | String | ✅ | Mô tả chi tiết |
| `rentalPricePerDay` | Double | ✅ | Giá thuê/ngày (VNĐ) |
| `depositAmount` | Double | ✅ | Tiền cọc |
| `thumbnailUrl` | String | ✅ | URL ảnh đại diện |
| `imageUrls` | Array | ✅ | Danh sách URL ảnh bổ sung |
| `category` | String | ✅ | ID danh mục |
| `sizes` | Array | ✅ | Sizes có sẵn |
| `colors` | Array | ✅ | Màu có sẵn |
| `brand` | String | ✅ | Thương hiệu |
| `rating` | Double | ✅ | Đánh giá TB (0.0 - 5.0) |
| `reviewCount` | Integer | ✅ | Số lượng đánh giá |
| `isActive` | Boolean | ✅ | Trạng thái hoạt động |
| `tags` | Array | ✅ | Tags tìm kiếm |
| `createdAt` | Timestamp | ✅ | Ngày tạo |
| `updatedAt` | Timestamp | ✅ | Ngày cập nhật |

#### Product Categories

| Category ID | Display Name |
|------------|--------------|
| `ao_dai` | Áo dài |
| `quan` | Quần |
| `vay_cuoi` | Váy cưới |
| `dam_da_hoi` | Đầm dạ hội |
| `vest_suit` | Vest / Suit |
| `hanbok` | Hanbok |
| `trang_phuc_dan_toc` | Trang phục dân tộc |
| `trang_phuc_chup_anh` | Trang phục chụp ảnh |
| `phu_kien` | Phụ kiện |
| `giay` | Giày |

#### Example Document

```json
{
  "id": "prod_001",
  "name": "Áo dài lụa trắng cao cấp",
  "description": "Áo dài lụa trắng tinh khôi...",
  "rentalPricePerDay": 200000,
  "depositAmount": 500000,
  "thumbnailUrl": "https://storage.supabase.co/products/aodai001.jpg",
  "imageUrls": ["url1.jpg", "url2.jpg"],
  "category": "ao_dai",
  "sizes": ["XS", "S", "M", "L"],
  "colors": ["Trắng", "Kem"],
  "brand": "Áo Dài Việt",
  "rating": 4.8,
  "reviewCount": 156,
  "isActive": true,
  "tags": ["áo dài", "lụa", "cao cấp"],
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-04-01T12:00:00Z"
}
```

---

### 3. Orders Collection

**Collection Path**: `orders/{orderId}`

Lưu trữ đơn thuê với timeline và tính toán giá.

#### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | ✅ | Document ID |
| `userId` | String | ✅ | Reference đến users |
| `branchId` | String | ✅ | Reference đến branches |
| `branchName` | String | ✅ | Tên chi nhánh (denormalized) |
| `branchAddress` | String | ✅ | Địa chỉ chi nhánh (denormalized) |
| `items` | Array | ✅ | Danh sách OrderItem |
| `rentalStartDate` | Timestamp | ✅ | Ngày bắt đầu thuê |
| `rentalEndDate` | Timestamp | ✅ | Ngày trả |
| `rentalDays` | Integer | ✅ | Số ngày thuê |
| `totalRentalFee` | Double | ✅ | Tổng tiền thuê |
| `depositPaid` | Double | ✅ | Tổng tiền cọc |
| `status` | String | ✅ | Trạng thái đơn hàng |
| `deliveryAddress` | String | ✅ | Địa chỉ giao hàng |
| `note` | String | ❌ | Ghi chú của khách |
| `createdAt` | Timestamp | ✅ | Ngày tạo đơn |
| `updatedAt` | Timestamp | ✅ | Ngày cập nhật |

#### OrderItem (Nested Object)

| Field | Type | Description |
|-------|------|-------------|
| `productId` | String | Reference đến products |
| `productName` | String | Tên sản phẩm (denormalized) |
| `thumbnailUrl` | String | URL ảnh (denormalized) |
| `selectedSize` | String | Size đã chọn |
| `selectedColor` | String | Màu đã chọn |
| `rentalPricePerDay` | Double | Giá thuê/ngày tại thời điểm đặt |
| `depositAmount` | Double | Tiền cọc tại thời điểm đặt |
| `quantity` | Integer | Số lượng |
| `subtotal` | Double | rentalPricePerDay × quantity × rentalDays |

#### Order Status Flow

```
┌─────────┐    ┌───────────┐    ┌─────────┐    ┌──────────┐    ┌───────────┐
│ pending │───▶│ confirmed │───▶│ renting │───▶│ returned │───▶│ completed │
└─────────┘    └───────────┘    └─────────┘    └──────────┘    └───────────┘
     │
     ▼
┌───────────┐
│ cancelled │
└───────────┘
```

| Status | Display Name | Description |
|--------|--------------|-------------|
| `pending` | Chờ xác nhận | Đơn mới, chờ admin xác nhận |
| `confirmed` | Đã xác nhận | Admin đã xác nhận |
| `renting` | Đang thuê | Khách đang thuê |
| `returned` | Đã trả | Khách đã trả hàng |
| `completed` | Hoàn thành | Đơn hoàn tất |
| `cancelled` | Đã hủy | Đơn bị hủy |

---

### 4. Reviews Collection

**Collection Path**: `reviews/{reviewId}`

Lưu trữ đánh giá sản phẩm từ khách hàng.

#### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | ✅ | Document ID |
| `productId` | String | ✅ | Reference đến products |
| `branchId` | String | ✅ | Reference đến branches |
| `userId` | String | ✅ | Reference đến users |
| `orderId` | String | ✅ | Reference đến orders |
| `rating` | Integer | ✅ | Đánh giá (1-5 sao) |
| `comment` | String | ❌ | Nội dung đánh giá |
| `userDisplayName` | String | ❌ | Tên người review (denormalized) |
| `photoUrls` | Array | ✅ | URLs ảnh review (max 3) |
| `createdAt` | Timestamp | ✅ | Ngày đánh giá |

#### Constraints

- `rating`: Min = 1, Max = 5
- `photoUrls`: Maximum 3 images

---

### 5. Branches Collection

**Collection Path**: `branches/{branchId}`

Lưu trữ thông tin chi nhánh và tồn kho.

#### Main Collection Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | ✅ | Document ID |
| `name` | String | ✅ | Tên chi nhánh |
| `address` | String | ✅ | Địa chỉ đầy đủ |
| `location` | GeoPoint | ✅ | Tọa độ GPS (lat, lng) |
| `geohash` | String | ✅ | Geohash cho location queries |
| `phone` | String | ✅ | Số điện thoại |
| `email` | String | ❌ | Email |
| `imageUrl` | String | ❌ | URL ảnh chi nhánh |
| `openingHours` | Map | ✅ | Giờ mở cửa theo ngày |
| `isActive` | Boolean | ✅ | Trạng thái hoạt động |
| `createdAt` | Timestamp | ✅ | Ngày tạo |

#### Opening Hours Structure

```json
{
  "openingHours": {
    "monday": { "open": "08:00", "close": "21:00", "isOpen": true },
    "tuesday": { "open": "08:00", "close": "21:00", "isOpen": true },
    "sunday": { "open": "09:00", "close": "18:00", "isOpen": true }
  }
}
```

#### Subcollection: Inventory

**Path**: `branches/{branchId}/inventory/{productId}`

| Field | Type | Description |
|-------|------|-------------|
| `productId` | String | Document ID (reference products) |
| `totalStock` | Integer | Tổng tồn kho |
| `availableStock` | Integer | Tồn kho có thể thuê |
| `updatedAt` | Timestamp | Ngày cập nhật |

---

### 6. Favorites Collection

**Collection Path**: `favorites/{userId}/items/{productId}`

Lưu trữ danh sách sản phẩm yêu thích của user.

#### Schema

| Field | Type | Description |
|-------|------|-------------|
| `productId` | String | Document ID (reference products) |
| `productName` | String | Tên sản phẩm (denormalized) |
| `thumbnailUrl` | String | URL ảnh (denormalized) |
| `rentalPricePerDay` | Double | Giá thuê (denormalized) |
| `addedAt` | Timestamp | Ngày thêm vào yêu thích |

---

### 7. Carts Collection

**Collection Path**: `carts/{userId}`

Lưu trữ giỏ hàng của user.

#### Schema

| Field | Type | Description |
|-------|------|-------------|
| `items` | Array | Danh sách CartItem |
| `updatedAt` | Timestamp | Ngày cập nhật |

#### CartItem (Nested Object)

| Field | Type | Description |
|-------|------|-------------|
| `productId` | String | Reference products |
| `productName` | String | Tên sản phẩm |
| `imageUrl` | String | URL ảnh |
| `selectedSize` | String | Size đã chọn |
| `selectedColor` | String | Màu đã chọn |
| `rentalPricePerDay` | Double | Giá thuê/ngày |
| `depositPrice` | Double | Tiền cọc |
| `branchId` | String | Chi nhánh lấy hàng |
| `branchName` | String | Tên chi nhánh |
| `branchAddress` | String | Địa chỉ chi nhánh |
| `availableStock` | Integer | Tồn kho available |
| `quantity` | Integer | Số lượng |
| `rentalDays` | Integer | Số ngày thuê |

> **Note**: Giỏ hàng hỗ trợ nhiều chi nhánh (sẽ tách thành nhiều orders khi checkout)

---

## Relationships

### Entity Relationship Diagram

```
┌──────────┐
│  Users   │
└────┬─────┘
     │
     ├─── orders (userId)
     │    ├─── items[].productId → Products
     │    └─── branchId → Branches
     │
     ├─── reviews (userId)
     │    ├─── productId → Products
     │    ├─── branchId → Branches
     │    └─── orderId → Orders
     │
     ├─── favorites/{userId}/items
     │    └─── productId → Products
     │
     └─── carts/{userId}
          ├─── items[].productId → Products
          └─── items[].branchId → Branches

┌──────────┐
│ Products │
└────┬─────┘
     ├─── reviews (productId)
     └─── branches/{branchId}/inventory (productId)

┌──────────┐
│ Branches │
└────┬─────┘
     ├─── inventory/{productId} (subcollection)
     └─── orders (branchId)
```

### Key Foreign Keys

| From | Field | References |
|------|-------|------------|
| orders | userId | users.uid |
| orders | branchId | branches.id |
| orders.items[] | productId | products.id |
| reviews | userId | users.uid |
| reviews | productId | products.id |
| reviews | branchId | branches.id |
| reviews | orderId | orders.id |
| favorites/items | productId | products.id |
| carts.items[] | productId | products.id |
| carts.items[] | branchId | branches.id |

---

## Indexes

### Products Indexes

```javascript
// Category + Rating (for filtered browsing)
{ category: ASC, rating: DESC }

// Active + Price (for price filtering)
{ isActive: ASC, rentalPricePerDay: ASC }

// Category + Price (for category + price queries)
{ category: ASC, rentalPricePerDay: ASC }
```

### Orders Indexes

```javascript
// User orders by date
{ userId: ASC, createdAt: DESC }

// Branch orders by status
{ branchId: ASC, status: ASC, createdAt: DESC }

// All orders by status
{ status: ASC, createdAt: DESC }
```

### Reviews Indexes

```javascript
// Product reviews
{ productId: ASC, createdAt: DESC }

// Branch reviews
{ branchId: ASC, createdAt: DESC }
```

### Branches Indexes

```javascript
// Active branches by name
{ isActive: ASC, name: ASC }
```

---

## Security Rules

### Summary Table

| Collection | Read | Create | Update | Delete |
|-----------|------|--------|--------|--------|
| users | Auth users | Owner | Owner/Admin | Admin |
| products | Public | Admin | Admin | Admin |
| orders | Owner/Admin | Auth users | Special* | Admin |
| reviews | Public | Auth users | Author | Author |
| favorites | Owner | Owner | Owner | Owner |
| carts | Owner | Owner | Owner | Owner |
| branches | Public | Admin | Admin | Admin |
| inventory | Public | Admin | Admin | Admin |

*Orders: User can only cancel their own pending orders

### Firestore Rules (Summary)

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
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Users
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isAdmin();
    }
    
    // Products (public read, admin write)
    match /products/{productId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Orders
    match /orders/{orderId} {
      allow read: if isOwner(resource.data.userId) || isAdmin();
      allow create: if isAuthenticated();
      allow update: if isAdmin() || 
        (isOwner(resource.data.userId) && 
         resource.data.status == 'pending' && 
         request.resource.data.status == 'cancelled');
      allow delete: if isAdmin();
    }
    
    // Reviews (public read, auth create, author update/delete)
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update, delete: if isOwner(resource.data.userId);
    }
    
    // Branches & Inventory
    match /branches/{branchId} {
      allow read: if true;
      allow write: if isAdmin();
      
      match /inventory/{productId} {
        allow read: if true;
        allow write: if isAdmin();
      }
    }
    
    // Favorites & Carts (owner only)
    match /favorites/{userId}/items/{productId} {
      allow read, write: if isOwner(userId);
    }
    
    match /carts/{userId} {
      allow read, write: if isOwner(userId);
    }
  }
}
```

---

## Denormalization Strategy

### Why Denormalize?

Firestore không hỗ trợ JOIN queries. Để tối ưu performance:

| Trade-off | Benefit | Cost |
|-----------|---------|------|
| Reduce reads | Faster queries | Data duplication |
| Historical accuracy | Preserve order prices | Storage space |
| Offline support | Less data to sync | Update complexity |

### Denormalized Fields

| Collection | Denormalized Fields | Source | Reason |
|-----------|-------------------|--------|--------|
| orders | branchName, branchAddress | branches | Quick display |
| orders.items[] | productName, thumbnailUrl, pricing | products | Historical accuracy |
| reviews | userDisplayName | users | Show reviewer name |
| carts.items[] | productName, imageUrl, branchInfo | products, branches | Quick cart display |
| favorites | productName, thumbnailUrl, price | products | Fast browsing |

### Update Strategy

- **Products change**: Không update orders cũ (preserve history)
- **Users change**: Có thể update reviews mới (optional)
- **Branches change**: Không update orders cũ (preserve history)

---

## Query Patterns

### Common Queries

#### 1. Products by Category + Rating

```dart
FirebaseFirestore.instance
  .collection('products')
  .where('category', isEqualTo: 'ao_dai')
  .where('isActive', isEqualTo: true)
  .orderBy('rating', descending: true)
  .limit(20)
  .get();
```

#### 2. User's Orders

```dart
FirebaseFirestore.instance
  .collection('orders')
  .where('userId', isEqualTo: currentUserId)
  .orderBy('createdAt', descending: true)
  .get();
```

#### 3. Product Reviews

```dart
FirebaseFirestore.instance
  .collection('reviews')
  .where('productId', isEqualTo: productId)
  .orderBy('createdAt', descending: true)
  .limit(10)
  .get();
```

#### 4. Nearby Branches (GeoFlutterFire)

```dart
final geo = GeoFlutterFire();
final center = geo.point(latitude: userLat, longitude: userLng);

geo.collection(collectionRef: FirebaseFirestore.instance.collection('branches'))
  .within(center: center, radius: 10, field: 'location');
```

#### 5. Branch Inventory

```dart
FirebaseFirestore.instance
  .collection('branches')
  .doc(branchId)
  .collection('inventory')
  .doc(productId)
  .get();
```

---

## Constants Reference

Defined in `lib/constants/app_constants.dart`:

```dart
// Collection names
const String usersCollection = 'users';
const String productsCollection = 'products';
const String branchesCollection = 'branches';
const String ordersCollection = 'orders';
const String reviewsCollection = 'reviews';
const String favoritesCollection = 'favorites';
const String cartsCollection = 'carts';

// Subcollection names
const String inventorySubcollection = 'inventory';
const String favItemsSubcollection = 'items';
```

---

## Database Initialization

### Seed Data

**Location**: `lib/utils/seed_data.dart`

**Process**:
1. Clear existing data (inventory subcollections first)
2. Seed branches with GPS locations
3. Seed products across all categories
4. Seed inventory for each branch-product pair
5. Create admin user account

**Usage**:
```dart
// In main.dart (run once, then remove)
await SeedData.seedAll();
```

---

## Performance Best Practices

1. ✅ **Use Indexes**: Always create composite indexes for multi-field queries
2. ✅ **Limit Results**: Use `.limit()` to avoid over-fetching
3. ✅ **Denormalize Smartly**: Only for frequently read data
4. ✅ **Cache Locally**: Use Flutter caching for static data
5. ✅ **Pagination**: Implement cursor-based pagination
6. ✅ **Batch Writes**: Use batches for multi-document updates
7. ✅ **Subcollections**: Use for large nested data (inventory)

---

## References

- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
- [Firestore Indexing](https://firebase.google.com/docs/firestore/query-data/indexing)
- [GeoFlutterFire](https://pub.dev/packages/geoflutterfire_plus)
- [FlutterFire](https://firebase.flutter.dev/)

---

**Last Updated**: 2026-04-04  
**Version**: 2.0  
**Author**: Rentify Team
