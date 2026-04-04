# Architecture Documentation - Rentify

## 📐 Tổng quan kiến trúc

Rentify được xây dựng theo kiến trúc **MVVM (Model-View-ViewModel)** kết hợp với **Provider** pattern để quản lý state, sử dụng **Firebase** làm backend và **Supabase** cho image storage.

---

## 🏗️ Architecture Layers

```
┌─────────────────────────────────────────────────┐
│              Presentation Layer                 │
│  (Screens, Widgets, UI Components)              │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│            ViewModel Layer                      │
│  (ViewModels, Providers, State Management)      │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│             Service Layer                       │
│  (Business Logic, API Calls, Data Processing)   │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│              Data Layer                         │
│  (Models, Firebase, Supabase, Local Storage)    │
└─────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
lib/
├── constants/              # App constants, colors, themes
│   ├── app_colors.dart     # Color palette
│   ├── app_constants.dart  # Constants (collections, categories, etc.)
│   └── app_theme.dart      # Material theme configuration
│
├── models/                 # Data models
│   ├── product_model.dart  # Product/Trang phục
│   ├── order_model.dart    # Order/Đơn thuê
│   ├── user_model.dart     # User/Người dùng
│   ├── branch_model.dart   # Branch/Chi nhánh (with GPS)
│   ├── cart_item_model.dart
│   ├── review_model.dart
│   └── favorite_model.dart
│
├── services/               # Business logic & API services
│   ├── auth_service.dart           # Authentication (Email, Google)
│   ├── firebase_service.dart       # Firestore CRUD operations
│   ├── supabase_service.dart       # Image upload/storage
│   ├── image_picker_service.dart   # Camera/Gallery picker
│   ├── biometric_service.dart      # Face ID/Fingerprint
│   ├── biometric_preference_service.dart
│   └── admin_service.dart          # Admin operations
│
├── providers/              # State management
│   └── cart_provider.dart  # Shopping cart state
│
├── viewmodels/             # ViewModels for screens
│   ├── home_view_model.dart
│   ├── profile_view_model.dart
│   ├── branch_view_model.dart
│   ├── branch_detail_view_model.dart
│   ├── history_view_model.dart
│   ├── messages_view_model.dart
│   └── splash_view_model.dart
│
├── screens/                # UI screens
│   ├── auth/              # Authentication screens
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── profile_setup_screen.dart
│   │
│   ├── home/              # Home & product listing
│   │   ├── home_screen.dart
│   │   └── widgets/
│   │
│   ├── admin/             # Admin management
│   │   ├── admin_main_screen.dart
│   │   ├── admin_dashboard_screen.dart
│   │   ├── admin_products_screen.dart
│   │   ├── admin_orders_screen.dart
│   │   ├── admin_branches_screen.dart
│   │   ├── admin_reviews_screen.dart
│   │   └── admin_users_screen.dart
│   │
│   ├── product_detail_screen.dart
│   ├── cart_screen.dart
│   ├── order_screen.dart
│   ├── profile_screen.dart
│   ├── branch_screen.dart
│   ├── branch_detail_screen.dart
│   ├── rental_booking_screen.dart
│   ├── rental_history_page.dart
│   ├── history_screen.dart
│   ├── messages_screen.dart
│   ├── biometric_unlock_screen.dart
│   └── splash_screen.dart
│
├── widgets/
│   └── common/            # Reusable widgets
│       ├── product_card.dart
│       ├── custom_button.dart
│       ├── loading_widget.dart
│       └── add_to_cart_dialog.dart
│
├── utils/                 # Utilities
│   ├── seed_data.dart
│   └── update_image_urls.dart
│
├── firebase_options.dart  # Firebase configuration
└── main.dart             # App entry point
```

---

## 🔄 Data Flow

### User Flow Example: Đặt thuê sản phẩm

```
1. User opens app
   └─> SplashScreen
       └─> Check auth state (AuthService)
           ├─> Logged in → HomeScreen
           └─> Not logged in → LoginScreen

2. User browses products
   └─> HomeScreen
       └─> HomeViewModel.loadProducts()
           └─> FirebaseService.getProducts()
               └─> Firestore query
                   └─> Return List<Product>

3. User adds to cart
   └─> ProductDetailScreen
       └─> CartProvider.addToCart(item)
           └─> Validate stock
           └─> Add to local cart
           └─> Save to Firestore (carts/{userId})

4. User proceeds to checkout
   └─> CartScreen
       └─> Select dates (rentalStartDate, rentalEndDate)
       └─> Navigate to RentalBookingScreen
           └─> FirebaseService.createOrder()
               ├─> Save to Firestore (orders/)
               ├─> Update inventory
               └─> Clear cart

5. Order confirmation
   └─> Navigate to OrderScreen
       └─> Display order details
```

---

## 🔐 Authentication Flow

```
┌─────────────┐
│ LoginScreen │
└──────┬──────┘
       │
       ├─── Email/Password ───> AuthService.signIn()
       │                          └─> FirebaseAuth
       │                              └─> Create/Update UserModel in Firestore
       │
       └─── Google Sign-In ───> AuthService.signInWithGoogle()
                                 └─> GoogleSignIn API
                                     └─> FirebaseAuth credential
                                         └─> Create/Update UserModel

After successful login:
└─> Check biometric preference
    ├─> Enabled → BiometricUnlockScreen
    └─> Disabled → HomeScreen
```

---

## 🗄️ Database Design

### Firestore Collections

```
firestore/
├── users/                           # User profiles
│   └── {userId}
│       ├── email: string
│       ├── displayName: string
│       ├── role: string (user/admin)
│       ├── phoneNumber: string
│       └── createdAt: timestamp
│
├── products/                        # Trang phục
│   └── {productId}
│       ├── name: string
│       ├── category: string
│       ├── rentalPricePerDay: number
│       ├── depositAmount: number
│       ├── sizes: array
│       ├── colors: array
│       ├── imageUrls: array
│       ├── rating: number
│       ├── reviewCount: number
│       └── isActive: boolean
│
├── branches/                        # Chi nhánh
│   └── {branchId}
│       ├── name: string
│       ├── address: string
│       ├── location: geopoint (lat, lng)
│       ├── geohash: string
│       ├── phone: string
│       ├── openingHours: map
│       └── isActive: boolean
│
├── branch_inventory/                # Tồn kho theo chi nhánh
│   └── {branchId}/products/{productId}
│       ├── totalStock: number
│       ├── availableStock: number
│       └── updatedAt: timestamp
│
├── orders/                          # Đơn thuê
│   └── {orderId}
│       ├── userId: string
│       ├── branchId: string
│       ├── items: array
│       ├── rentalStartDate: timestamp
│       ├── rentalEndDate: timestamp
│       ├── totalRentalFee: number
│       ├── depositPaid: number
│       ├── status: string
│       └── createdAt: timestamp
│
├── reviews/                         # Đánh giá
│   └── {reviewId}
│       ├── userId: string
│       ├── productId: string
│       ├── orderId: string
│       ├── rating: number
│       ├── comment: string
│       ├── imageUrls: array
│       └── createdAt: timestamp
│
├── favorites/                       # Yêu thích
│   └── {userId}/products/{productId}
│       └── createdAt: timestamp
│
└── carts/                           # Giỏ hàng
    └── {userId}
        ├── items: array
        └── updatedAt: timestamp
```

See [DATABASE_DESIGN.md](DATABASE_DESIGN.md) for detailed schema.

---

## 🎯 Design Patterns

### 1. MVVM (Model-View-ViewModel)

**Models**: Pure data classes
```dart
class Product {
  final String id;
  final String name;
  final double rentalPricePerDay;
  
  factory Product.fromFirestore(...);
  Map<String, dynamic> toMap();
}
```

**ViewModels**: Business logic & state
```dart
class HomeViewModel extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    
    _products = await _firebaseService.getProducts();
    
    _isLoading = false;
    notifyListeners();
  }
}
```

**Views**: UI only
```dart
class HomeScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel()..loadProducts(),
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) return LoadingWidget();
          return ProductGrid(products: vm.products);
        },
      ),
    );
  }
}
```

### 2. Provider Pattern (State Management)

```dart
// Setup in main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => CartProvider()),
  ],
  child: MyApp(),
)

// Access anywhere
final cart = Provider.of<CartProvider>(context);
cart.addToCart(item);
```

### 3. Repository Pattern (Services)

```dart
class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Future<List<Product>> getProducts() async {
    final snapshot = await _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .get();
    
    return snapshot.docs
        .map((doc) => Product.fromFirestore(doc.data(), doc.id))
        .toList();
  }
}
```

### 4. Singleton Pattern (Services)

```dart
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  // Service methods...
}
```

---

## 🌐 Network Architecture

```
┌─────────────┐
│   Flutter   │
│     App     │
└──────┬──────┘
       │
       ├──────────────> Firebase Authentication
       │                (Email/Password, Google)
       │
       ├──────────────> Cloud Firestore
       │                (Products, Orders, Users, etc.)
       │
       ├──────────────> Supabase Storage
       │                (Product images, Review images)
       │
       ├──────────────> Geolocator/GeoFlutterFire
       │                (GPS location for nearby branches)
       │
       └──────────────> Local Storage
                        (SharedPreferences for settings)
```

---

## 🔒 Security Architecture

### Firebase Security Rules

```javascript
// Firestore rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write own data
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Products: public read, admin write
    match /products/{productId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Orders: own orders only
    match /orders/{orderId} {
      allow read: if request.auth.uid == resource.data.userId 
                  || isAdmin();
      allow create: if request.auth != null;
    }
  }
}
```

### Data Validation

- Client-side validation in forms
- Server-side validation via Firestore rules
- Type safety with Dart models

---

## 📱 Navigation Architecture

Using **GoRouter** for declarative routing:

```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => SplashScreen()),
    GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProductDetailScreen(productId: id);
      },
    ),
    // Admin routes
    GoRoute(
      path: '/admin',
      builder: (context, state) => AdminMainScreen(),
      redirect: (context, state) {
        // Check admin role
        return isAdmin ? null : '/home';
      },
    ),
  ],
);
```

---

## 🚀 Performance Optimization

### 1. Image Optimization
- Use `cached_network_image` for caching
- Lazy loading with `ListView.builder`
- Shimmer placeholders during loading

### 2. Firestore Optimization
- Composite indexes for complex queries
- Pagination for large lists
- Offline persistence enabled

### 3. State Management
- Provider for granular updates
- `notifyListeners()` only when needed
- Selective rebuilds with `Consumer`

---

## 🔄 CI/CD Pipeline (Planned)

```
GitHub Actions:
1. On Push → Run tests (flutter test)
2. On PR → Run linter (flutter analyze)
3. On Tag → Build release APK/IPA
4. Deploy → Firebase Hosting (Admin panel)
```

---

## 📊 Monitoring & Analytics (Planned)

- Firebase Crashlytics: Crash reporting
- Firebase Analytics: User behavior tracking
- Performance Monitoring: App performance metrics

---

## 🎨 UI/UX Architecture

### Theme System
- Central theme in `app_theme.dart`
- Color palette in `app_colors.dart`
- Consistent design tokens

### Component Library
- Reusable widgets in `widgets/common/`
- Consistent spacing, typography
- Dark mode ready (planned)

---

## 📖 References

- [Flutter Architecture](https://flutter.dev/docs/development/data-and-backend/state-mgmt/intro)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [MVVM Pattern](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel)

---

**Last Updated**: 2026-04-04  
**Version**: 1.0.0  
**Author**: Rentify Development Team
