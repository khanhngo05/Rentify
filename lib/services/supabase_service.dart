import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// Service xử lý upload/download ảnh từ Supabase Storage
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Bucket lưu ảnh
  SupabaseStorageClient get _storage => _client.storage;

  // ═══════════════════════════════════════════════════════════════
  //  UPLOAD ẢNH
  // ═══════════════════════════════════════════════════════════════

  /// Upload ảnh sản phẩm
  /// Trả về URL công khai của ảnh
  Future<String?> uploadProductImage({
    required String productId,
    required File imageFile,
    String? fileName,
  }) async {
    final name = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '${AppConstants.supabaseProductsFolder}/$productId/$name';
    return await _uploadFile(path, imageFile);
  }

  /// Upload ảnh đánh giá (từ camera)
  Future<String?> uploadReviewPhoto({
    required String reviewId,
    required File imageFile,
    String? fileName,
  }) async {
    final name = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '${AppConstants.supabaseReviewsFolder}/$reviewId/$name';
    return await _uploadFile(path, imageFile);
  }

  /// Upload ảnh đại diện
  Future<String?> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '${AppConstants.supabaseAvatarsFolder}/$userId/$name';
    return await _uploadFile(path, imageFile);
  }

  /// Upload ảnh đại diện bằng bytes (hỗ trợ web)
  Future<String?> uploadAvatarBytes({
    required String userId,
    required Uint8List imageBytes,
    String fileExtension = 'jpg',
  }) async {
    final ext = fileExtension.replaceAll('.', '').toLowerCase();
    final safeExt = ext.isEmpty ? 'jpg' : ext;
    final name = '${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    final path = '${AppConstants.supabaseAvatarsFolder}/$userId/$name';
    final contentType = _contentTypeFromExtension(safeExt);
    return await _uploadBinary(path, imageBytes, contentType: contentType);
  }

  /// Upload ảnh chi nhánh
  Future<String?> uploadBranchImage({
    required String branchId,
    required File imageFile,
    String? fileName,
  }) async {
    final name = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '${AppConstants.supabaseBranchesFolder}/$branchId/$name';
    return await _uploadFile(path, imageFile);
  }

  // ═══════════════════════════════════════════════════════════════
  //  XÓA ẢNH
  // ═══════════════════════════════════════════════════════════════

  /// Xóa 1 ảnh theo đường dẫn
  Future<bool> deleteImage(String path) async {
    try {
      await _storage.from(AppConstants.supabaseBucket).remove([path]);
      return true;
    } catch (e) {
      debugPrint('Lỗi xóa ảnh: $e');
      return false;
    }
  }

  /// Xóa tất cả ảnh trong 1 thư mục (VD: xóa toàn bộ ảnh review)
  Future<bool> deleteFolder(String folderPath) async {
    try {
      final files = await _storage
          .from(AppConstants.supabaseBucket)
          .list(path: folderPath);

      if (files.isNotEmpty) {
        final paths = files.map((f) => '$folderPath/${f.name}').toList();
        await _storage.from(AppConstants.supabaseBucket).remove(paths);
      }
      return true;
    } catch (e) {
      debugPrint('Lỗi xóa thư mục: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  LẤY URL CÔNG KHAI
  // ═══════════════════════════════════════════════════════════════

  /// Lấy URL công khai của 1 ảnh
  String getPublicUrl(String path) {
    return _storage.from(AppConstants.supabaseBucket).getPublicUrl(path);
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPER
  // ═══════════════════════════════════════════════════════════════

  /// Upload file và trả về URL công khai
  Future<String?> _uploadFile(String path, File file) async {
    try {
      await _storage
          .from(AppConstants.supabaseBucket)
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      return getPublicUrl(path);
    } catch (e) {
      debugPrint('Lỗi upload ảnh: $e');
      return null;
    }
  }

  /// Upload bytes và trả về URL công khai
  Future<String?> _uploadBinary(
    String path,
    Uint8List bytes, {
    String? contentType,
  }) async {
    try {
      await _storage
          .from(AppConstants.supabaseBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: contentType,
            ),
          );

      return getPublicUrl(path);
    } catch (e) {
      debugPrint('Lỗi upload bytes: $e');
      return null;
    }
  }

  String _contentTypeFromExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}
