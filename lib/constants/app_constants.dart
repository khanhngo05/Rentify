/// Các hằng số dùng chung trong toàn bộ ứng dụng Rentify
class AppConstants {
  AppConstants._();

  // ── Tên ứng dụng ──────────────────────────────────────────
  static const String appName = 'Rentify';
  static const String appTagline = 'Cho thuê trang phục trực tuyến';

  // ── Firestore Collection Names ────────────────────────────
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String branchesCollection = 'branches';
  static const String ordersCollection = 'orders';
  static const String reviewsCollection = 'reviews';
  static const String favoritesCollection = 'favorites';
  static const String inventorySubcollection = 'inventory';
  static const String favItemsSubcollection = 'items';

  // ── Supabase ──────────────────────────────────────────────
  static const String supabaseBucket = 'fashion-images';
  static const String supabaseProductsFolder = 'products';
  static const String supabaseReviewsFolder = 'reviews';
  static const String supabaseAvatarsFolder = 'avatars';
  static const String supabaseBranchesFolder = 'branches';

  // ── Danh mục sản phẩm ─────────────────────────────────────
  static const Map<String, String> categories = {
    'ao_dai': 'Áo dài',
    'vay_cuoi': 'Váy cưới',
    'dam_da_hoi': 'Đầm dạ hội',
    'vest_suit': 'Vest / Suit',
    'hanbok': 'Hanbok',
    'trang_phuc_dan_toc': 'Trang phục dân tộc',
    'trang_phuc_chup_anh': 'Trang phục chụp ảnh',
    'phu_kien': 'Phụ kiện',
  };

  // ── Trạng thái đơn thuê ───────────────────────────────────
  static const Map<String, String> orderStatuses = {
    'pending': 'Chờ xác nhận',
    'confirmed': 'Đã xác nhận',
    'renting': 'Đang thuê',
    'returned': 'Đã trả',
    'completed': 'Hoàn thành',
    'cancelled': 'Đã hủy',
  };

  // ── Vai trò người dùng ────────────────────────────────────
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';

  // ── Quy tắc nghiệp vụ ────────────────────────────────────
  static const int minRentalDays = 1;
  static const int maxRentalDays = 30;
  static const int minRating = 1;
  static const int maxRating = 5;
  static const int maxReviewPhotos = 3;

  // ── Định dạng ─────────────────────────────────────────────
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String currencySymbol = '₫';
  static const String currencyLocale = 'vi_VN';

  /// Lấy tên hiển thị của danh mục
  static String getCategoryName(String key) {
    return categories[key] ?? 'Khác';
  }

  /// Lấy tên hiển thị của trạng thái đơn
  static String getStatusName(String key) {
    return orderStatuses[key] ?? 'Không rõ';
  }

  /// Format giá tiền VNĐ (VD: 250,000₫)
  static String formatPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '$formatted$currencySymbol';
  }
}
