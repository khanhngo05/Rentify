import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Script giúp chèn nhanh link ảnh trực tiếp vào Firestore
/// Hướng dẫn:
/// 1. Thay link ảnh thật của bạn vào các map bên dưới.
/// 2. Code `await UpdateImages.execute();` trong main.dart.
/// 3. Chạy app 1 lần rồi xóa dòng gọi hàm đi.
class UpdateImages {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cấu hình gốc URL của Supabase để code ngắn gọn hơn
  // URL format: https://[PROJECT_ID].supabase.co/storage/v1/object/public/[BUCKET_NAME]
  static const String supabaseBaseUrl = 'https://tjydkxdvipovzqnmejrt.supabase.co/storage/v1/object/public/fashion-images';

  // 1. Cập nhật link ảnh chi nhánh (Sử dụng nối chuỗi cho gọn)
  static const Map<String, String> branchImageUrls = {
    'branch_001': '$supabaseBaseUrl/branches/branch_001.jpg',
    'branch_002': '$supabaseBaseUrl/branches/branch_002.jpg',
    'branch_003': '$supabaseBaseUrl/branches/branch_003.jpg',
  };

  // 2. Cập nhật link ảnh sản phẩm
  static const Map<String, List<String>> productImages = {
    'prod_001': [
      '$supabaseBaseUrl/products/prod_001(1).jpg', // Thumbnail
      '$supabaseBaseUrl/products/prod_001(1).jpg',     // Detail 1
      '$supabaseBaseUrl/products/prod_001_(2).jpg',     // Detail 2
    ],
    // ... các sản phẩm khác tương tự
    'prod_002': [
      '$supabaseBaseUrl/products/prod_002(1).jpg', //
      '$supabaseBaseUrl/products/prod_002(1).jpg',
      '$supabaseBaseUrl/products/prod_002_(2).jpg',
    ],
    'prod_003': [
      '$supabaseBaseUrl/products/prod_003.jpg',
      '$supabaseBaseUrl/products/prod_003.jpg',
    ],
    'prod_004': [
      '$supabaseBaseUrl/products/prod_004.jpg',
      '$supabaseBaseUrl/products/prod_004.jpg',
    ],
    'prod_005': [
      '$supabaseBaseUrl/products/prod_005.jpg',
      '$supabaseBaseUrl/products/prod_005.jpg',
    ],
    'prod_006': [
      '$supabaseBaseUrl/products/prod_006.jpg',
      '$supabaseBaseUrl/products/prod_006.jpg',
    ],
    'prod_007': [
      '$supabaseBaseUrl/products/prod_007.jpg',
      '$supabaseBaseUrl/products/prod_007.jpg',
    ],
    'prod_008': [
      '$supabaseBaseUrl/products/prod_008.jpg',
      '$supabaseBaseUrl/products/prod_008.jpg',
    ],
    'prod_009': [
      '$supabaseBaseUrl/products/prod_009.jpg',
      '$supabaseBaseUrl/products/prod_009.jpg',
    ],
    'prod_010': [
      '$supabaseBaseUrl/products/prod_010.jpg',
      '$supabaseBaseUrl/products/prod_010.jpg',
    ],
    'prod_011': [
      '$supabaseBaseUrl/products/prod_011.jpg',
      '$supabaseBaseUrl/products/prod_011.jpg',
    ],
    'prod_012': [
      '$supabaseBaseUrl/products/prod_012.jpg',
      '$supabaseBaseUrl/products/prod_012.jpg',
    ],
    'prod_013': [
      '$supabaseBaseUrl/products/prod_013.jpg',
      '$supabaseBaseUrl/products/prod_013.jpg',
    ],
    'prod_014': [
      '$supabaseBaseUrl/products/prod_014.jpg',
      '$supabaseBaseUrl/products/prod_014.jpg',
    ],
    'prod_015': [
      '$supabaseBaseUrl/products/prod_015.jpg',
      '$supabaseBaseUrl/products/prod_015.jpg',
    ],
    'prod_016': [
      '$supabaseBaseUrl/products/prod_016.jpg',
      '$supabaseBaseUrl/products/prod_016.jpg',
    ],
    'prod_017': [
      '$supabaseBaseUrl/products/prod_017.jpg',
      '$supabaseBaseUrl/products/prod_017.jpg',
    ],
    'prod_018': [
      '$supabaseBaseUrl/products/prod_018.jpg',
      '$supabaseBaseUrl/products/prod_018.jpg',
    ],
    'prod_019': [
      '$supabaseBaseUrl/products/prod_019.jpg',
      '$supabaseBaseUrl/products/prod_019.jpg',
    ],
    'prod_020': [
      '$supabaseBaseUrl/products/prod_020.jpg',
      '$supabaseBaseUrl/products/prod_020.jpg',
    ],
    'prod_021': [
      '$supabaseBaseUrl/products/prod_021.jpg',
      '$supabaseBaseUrl/products/prod_021.jpg',
    ],
    'prod_022': [
      '$supabaseBaseUrl/products/prod_022.jpg',
      '$supabaseBaseUrl/products/prod_022.jpg',
    ],
    'prod_023': [
      '$supabaseBaseUrl/products/prod_023.jpg',
      '$supabaseBaseUrl/products/prod_023.jpg',
    ],
    'prod_024': [
      '$supabaseBaseUrl/products/prod_024.jpg',
      '$supabaseBaseUrl/products/prod_024.jpg',
    ],
    'prod_025': [
      '$supabaseBaseUrl/products/prod_025.jpg',
      '$supabaseBaseUrl/products/prod_025.jpg',
    ],
    'prod_026': [
      '$supabaseBaseUrl/products/prod_026.jpg',
      '$supabaseBaseUrl/products/prod_026.jpg',
    ],
    'prod_027': [
      '$supabaseBaseUrl/products/prod_027.jpg',
      '$supabaseBaseUrl/products/prod_027.jpg',
    ],
    'prod_028': [
      '$supabaseBaseUrl/products/prod_028.jpg',
      '$supabaseBaseUrl/products/prod_028.jpg',
    ],
    'prod_029': [
      '$supabaseBaseUrl/products/prod_029.jpg',
      '$supabaseBaseUrl/products/prod_029.jpg',
    ],
    'prod_030': [
      '$supabaseBaseUrl/products/prod_030.jpg',
      '$supabaseBaseUrl/products/prod_030.jpg',
    ],
    'prod_031': [
      '$supabaseBaseUrl/products/prod_031.jpg',
      '$supabaseBaseUrl/products/prod_031.jpg',
    ],
    'prod_032': [
      '$supabaseBaseUrl/products/prod_032.jpg',
      '$supabaseBaseUrl/products/prod_032.jpg',
    ],
    'prod_033': [
      '$supabaseBaseUrl/products/prod_033.jpg',
      '$supabaseBaseUrl/products/prod_033.jpg',
    ],
    'prod_034': [
      '$supabaseBaseUrl/products/prod_034.jpg',
      '$supabaseBaseUrl/products/prod_034.jpg',
    ],
    'prod_035': [
      '$supabaseBaseUrl/products/prod_035.jpg',
      '$supabaseBaseUrl/products/prod_035.jpg',
    ],
    'prod_036': [
      '$supabaseBaseUrl/products/prod_036.jpg',
      '$supabaseBaseUrl/products/prod_036.jpg',
    ],
    'prod_037': [
      '$supabaseBaseUrl/products/prod_037.jpg',
      '$supabaseBaseUrl/products/prod_037.jpg',
    ],
    'prod_038': [
      '$supabaseBaseUrl/products/prod_038.jpg',
      '$supabaseBaseUrl/products/prod_038.jpg',
    ],
    'prod_039': [
      '$supabaseBaseUrl/products/prod_039.jpg',
      '$supabaseBaseUrl/products/prod_039.jpg',
    ],
    'prod_040': [
      '$supabaseBaseUrl/products/prod_040.jpg',
      '$supabaseBaseUrl/products/prod_040.jpg',
    ],
    
  };
  /// Chạy hàm này để cập nhật URLs lên Firestore
  static Future<void> execute() async {
    debugPrint('🖼️ Bắt đầu cập nhật link ảnh...');

    // Cập nhật Chi nhánh
    for (final entry in branchImageUrls.entries) {
      if (entry.value.isEmpty || entry.value.contains('link-anh-')) continue;

      await _db
          .collection(AppConstants.branchesCollection)
          .doc(entry.key)
          .update({'imageUrl': entry.value});
      debugPrint('Đã cập nhật ảnh cho chi nhánh: ${entry.key}');
    }

    // Cập nhật Sản phẩm
    for (final entry in productImages.entries) {
      final List<String> urls = entry.value;
      if (urls.isEmpty ||
          urls.first.isEmpty ||
          urls.first.contains('link-thumbnail-'))
        continue;

      final String thumbUrl = urls.first;
      final List<String> detailUrls = urls.length > 1 ? urls.sublist(1) : [];

      await _db
          .collection(AppConstants.productsCollection)
          .doc(entry.key)
          .update({
        'thumbnailUrl': thumbUrl,
        'imageUrls':
        detailUrls, // Chỉ ghi đè nếu muốn, hoặc bạn đổi lại kịch bản
      });
      debugPrint('Đã cập nhật ảnh cho sản phẩm: ${entry.key}');
    }

    debugPrint('🎉 CẬP NHẬT ẢNH HOÀN TẤT!');
  }
}
