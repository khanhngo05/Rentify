# API Documentation - Rentify

## 📚 Overview

This document provides comprehensive API documentation for Rentify's services, models, and data structures.

---

## 🔐 Authentication Service

### AuthService

Location: `lib/services/auth_service.dart`

Authentication service handling user sign up, sign in, and sign out operations.

#### Properties

```dart
User? currentUser           // Currently logged in Firebase user
bool isLoggedIn            // Check if user is logged in
Stream<User?> authStateChanges  // Stream of auth state changes
```

#### Methods

##### signUp()
Create a new user account with email and password.

```dart
Future<UserModel> signUp({
  required String email,
  required String password,
  required String displayName,
  String? phoneNumber,
})
```

**Parameters:**
- `email`: User email address
- `password`: User password (min 6 characters)
- `displayName`: User's display name
- `phoneNumber`: Optional phone number

**Returns:** `UserModel` - Created user data

**Throws:** `FirebaseAuthException` on error

**Example:**
```dart
final user = await authService.signUp(
  email: 'user@example.com',
  password: 'password123',
  displayName: 'John Doe',
  phoneNumber: '0912345678',
);
```

---

##### signIn()
Sign in with email and password.

```dart
Future<UserModel?> signIn({
  required String email,
  required String password,
})
```

**Returns:** `UserModel?` - User data or null if failed

**Example:**
```dart
final user = await authService.signIn(
  email: 'user@example.com',
  password: 'password123',
);
```

---

##### signInWithGoogle()
Sign in using Google account.

```dart
Future<UserModel> signInWithGoogle({
  bool forceAccountSelection = true,
  bool silentOnly = false,
})
```

**Parameters:**
- `forceAccountSelection`: Show account picker even if only one account
- `silentOnly`: Try silent sign-in only (no UI)

**Returns:** `UserModel` - User data

**Example:**
```dart
final user = await authService.signInWithGoogle();
```

---

##### signOut()
Sign out current user.

```dart
Future<void> signOut()
```

---

## 🗄️ Firebase Service

### FirebaseService

Location: `lib/services/firebase_service.dart`

Main service for Firestore CRUD operations.

---

### Products

#### getProducts()
Get all active products.

```dart
Future<List<Product>> getProducts()
```

**Returns:** List of all active products, sorted by creation date (newest first)

**Example:**
```dart
final products = await firebaseService.getProducts();
```

---

#### getProductsByCategory()
Get products by category.

```dart
Future<List<Product>> getProductsByCategory(String category)
```

**Parameters:**
- `category`: Category ID (e.g., 'ao_dai', 'vay_cuoi')

**Returns:** Filtered list of products

**Example:**
```dart
final aoDaiProducts = await firebaseService.getProductsByCategory('ao_dai');
```

---

#### getProductById()
Get single product by ID.

```dart
Future<Product?> getProductById(String productId)
```

**Returns:** `Product?` - Product or null if not found

---

#### searchProducts()
Search products by keyword.

```dart
Future<List<Product>> searchProducts(String keyword)
```

**Parameters:**
- `keyword`: Search term (searches in name, description, tags)

**Returns:** Matching products

---

### Orders

#### createOrder()
Create a new rental order.

```dart
Future<String> createOrder(OrderModel order)
```

**Parameters:**
- `order`: OrderModel with order details

**Returns:** `String` - Created order ID

**Example:**
```dart
final order = OrderModel(
  userId: currentUserId,
  branchId: selectedBranch.id,
  items: cartItems,
  rentalStartDate: startDate,
  rentalEndDate: endDate,
  // ... other fields
);

final orderId = await firebaseService.createOrder(order);
```

---

#### getOrdersByUser()
Get all orders for a user.

```dart
Future<List<OrderModel>> getOrdersByUser(String userId)
```

**Returns:** List of user's orders, sorted by creation date

---

#### updateOrderStatus()
Update order status (admin only).

```dart
Future<void> updateOrderStatus(String orderId, String newStatus)
```

**Parameters:**
- `orderId`: Order ID
- `newStatus`: New status ('pending', 'confirmed', 'renting', 'completed', 'cancelled')

---

### Branches

#### getBranches()
Get all active branches.

```dart
Future<List<BranchModel>> getBranches()
```

**Returns:** List of branches

---

#### getNearbyBranches()
Get branches near a location (uses GPS).

```dart
Future<List<BranchModel>> getNearbyBranches({
  required double latitude,
  required double longitude,
  double radiusInKm = 10.0,
})
```

**Parameters:**
- `latitude`: User's latitude
- `longitude`: User's longitude
- `radiusInKm`: Search radius (default: 10km)

**Returns:** Branches sorted by distance

---

#### getBranchInventory()
Get product inventory for a branch.

```dart
Future<List<BranchInventory>> getBranchInventory(String branchId)
```

**Returns:** Stock information for all products at branch

---

### Reviews

#### addReview()
Add a product review.

```dart
Future<void> addReview(ReviewModel review)
```

**Parameters:**
- `review`: ReviewModel with review details

**Example:**
```dart
final review = ReviewModel(
  userId: currentUserId,
  productId: productId,
  orderId: orderId,
  rating: 5,
  comment: 'Excellent product!',
  imageUrls: uploadedImageUrls,
);

await firebaseService.addReview(review);
```

---

#### getProductReviews()
Get reviews for a product.

```dart
Future<List<ReviewModel>> getProductReviews(String productId)
```

**Returns:** List of reviews, sorted by date

---

### Favorites

#### addFavorite()
Add product to favorites.

```dart
Future<void> addFavorite(String userId, String productId)
```

---

#### removeFavorite()
Remove from favorites.

```dart
Future<void> removeFavorite(String userId, String productId)
```

---

#### getFavorites()
Get user's favorite products.

```dart
Future<List<Product>> getFavorites(String userId)
```

**Returns:** List of favorite products

---

#### isFavorite()
Check if product is favorited.

```dart
Future<bool> isFavorite(String userId, String productId)
```

---

## 📸 Supabase Service

### SupabaseService

Location: `lib/services/supabase_service.dart`

Image upload and storage service.

#### uploadImage()
Upload image to Supabase storage.

```dart
Future<String> uploadImage({
  required File imageFile,
  required String bucket,
  String? folder,
})
```

**Parameters:**
- `imageFile`: Image file to upload
- `bucket`: Supabase bucket name ('products', 'reviews', etc.)
- `folder`: Optional subfolder

**Returns:** `String` - Public URL of uploaded image

**Example:**
```dart
final imageUrl = await supabaseService.uploadImage(
  imageFile: selectedImage,
  bucket: 'products',
  folder: 'ao-dai',
);
```

---

#### uploadMultipleImages()
Upload multiple images.

```dart
Future<List<String>> uploadMultipleImages({
  required List<File> imageFiles,
  required String bucket,
  String? folder,
})
```

**Returns:** List of image URLs

---

## 🛒 Cart Provider

### CartProvider

Location: `lib/providers/cart_provider.dart`

Shopping cart state management.

#### Properties

```dart
List<CartItemModel> cartItems      // All items in cart
bool isLoading                     // Loading state
double totalRentalPrice           // Total rental fee
double totalDepositPrice          // Total deposit
String? branchId                  // Branch ID (null if multiple)
bool hasMultipleBranches          // Multiple branches flag
Map<String, List<CartItemModel>> itemsByBranch  // Grouped by branch
```

#### Methods

##### addToCart()
Add item to cart.

```dart
Future<bool> addToCart(CartItemModel newItem)
```

**Returns:** `bool` - true if added successfully, false if stock limit

**Example:**
```dart
final item = CartItemModel(
  productId: product.id,
  productName: product.name,
  selectedSize: 'M',
  selectedColor: 'Đỏ',
  rentalPricePerDay: product.rentalPricePerDay,
  depositPrice: product.depositAmount,
  branchId: branch.id,
  branchName: branch.name,
  quantity: 1,
  rentalDays: 3,
);

final success = await cartProvider.addToCart(item);
```

---

##### updateQuantity()
Update item quantity.

```dart
Future<bool> updateQuantity(
  String productId,
  String size,
  String color,
  String branchId,
  bool isIncrement,
  {Function()? onConfirmRemove}
)
```

**Parameters:**
- `productId`: Product ID
- `size`: Selected size
- `color`: Selected color
- `branchId`: Branch ID
- `isIncrement`: true to increase, false to decrease
- `onConfirmRemove`: Optional callback when quantity reaches 0

---

##### removeFromCart()
Remove item from cart.

```dart
Future<void> removeFromCart(
  String productId,
  String size,
  String color,
  String branchId,
)
```

---

##### clearCart()
Clear all items from cart.

```dart
Future<void> clearCart()
```

---

## 📦 Data Models

### Product Model

```dart
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
  
  factory Product.fromFirestore(Map<String, dynamic> data, String id);
  Map<String, dynamic> toMap();
}
```

---

### Order Model

```dart
class OrderModel {
  final String id;
  final String userId;
  final String branchId;
  final String branchName;
  final String branchAddress;
  final List<OrderItem> items;
  final DateTime rentalStartDate;
  final DateTime rentalEndDate;
  final int rentalDays;
  final double totalRentalFee;
  final double depositPaid;
  final String status;  // pending, confirmed, renting, completed, cancelled
  final String deliveryAddress;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  int get totalItemCount;  // Total quantity across all items
  
  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id);
  Map<String, dynamic> toMap();
}
```

---

### User Model

```dart
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? address;
  final String role;  // 'user' or 'admin'
  final DateTime createdAt;
  
  bool get isAdmin => role == 'admin';
  
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id);
  Map<String, dynamic> toMap();
}
```

---

### Branch Model

```dart
class BranchModel {
  final String id;
  final String name;
  final String address;
  final GeoPoint location;
  final String geohash;
  final String phone;
  final String? email;
  final String? imageUrl;
  final Map<String, DayHours> openingHours;
  final bool isActive;
  final DateTime createdAt;
  
  double get latitude => location.latitude;
  double get longitude => location.longitude;
  
  factory BranchModel.fromFirestore(Map<String, dynamic> data, String id);
  Map<String, dynamic> toMap();
}
```

---

## 🔍 Error Handling

All service methods may throw exceptions:

```dart
try {
  final products = await firebaseService.getProducts();
} on FirebaseException catch (e) {
  print('Firebase error: ${e.code} - ${e.message}');
} catch (e) {
  print('Unknown error: $e');
}
```

Common Firebase error codes:
- `permission-denied`: User doesn't have permission
- `not-found`: Document not found
- `unavailable`: Network error
- `failed-precondition`: Missing Firestore index

---

## 📊 Response Formats

### Success Response
Functions return data directly:
```dart
List<Product> products = await getProducts();
```

### Error Response
Throws exceptions:
```dart
throw FirebaseException(
  code: 'not-found',
  message: 'Product not found',
);
```

---

## 🔗 API Rate Limits

Firebase Firestore limits (free tier):
- **Reads**: 50,000/day
- **Writes**: 20,000/day
- **Deletes**: 20,000/day

Supabase Storage limits (free tier):
- **Storage**: 1GB
- **Bandwidth**: 2GB/month

---

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ⏳ Windows/Linux/macOS (desktop - planned)

---

## 📖 Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Dart Documentation](https://dart.dev/guides)

---

**Last Updated**: 2026-04-04  
**API Version**: 1.0.0  
**Contact**: Rentify Development Team
