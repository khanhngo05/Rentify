import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

/// Service để xử lý chọn ảnh từ camera hoặc gallery
/// Hỗ trợ pick single hoặc multiple images với validation
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Pick một ảnh từ camera hoặc gallery
  /// 
  /// [source]: ImageSource.camera hoặc ImageSource.gallery
  /// [maxWidth], [maxHeight]: Giới hạn kích thước (để compress)
  /// [imageQuality]: 0-100, default 85
  /// 
  /// Returns: XFile hoặc null nếu user cancel
  Future<XFile?> pickSingleImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      return image;
    } on PlatformException catch (e) {
      debugPrint('Error picking image: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error picking image: $e');
      return null;
    }
  }

  /// Pick nhiều ảnh từ gallery
  /// 
  /// [maxImages]: Số lượng ảnh tối đa cho phép chọn
  /// [maxWidth], [maxHeight]: Giới hạn kích thước
  /// [imageQuality]: 0-100, default 85
  /// 
  /// Returns: List<XFile> hoặc null nếu user cancel
  /// Note: Camera không support multiple images
  Future<List<XFile>?> pickMultipleImages({
    int maxImages = 3,
    double? maxWidth,
    double? maxHeight,
    int imageQuality = 85,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      // Validate số lượng ảnh
      if (images.length > maxImages) {
        debugPrint('User selected ${images.length} images, limiting to $maxImages');
        return images.sublist(0, maxImages);
      }

      return images.isEmpty ? null : images;
    } on PlatformException catch (e) {
      debugPrint('Error picking multiple images: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error picking multiple images: $e');
      return null;
    }
  }

  /// Show dialog để user chọn source: Camera hoặc Gallery
  /// 
  /// [context]: BuildContext để show dialog
  /// [allowMultiple]: Có cho phép chọn nhiều ảnh không (chỉ với gallery)
  /// [maxImages]: Số ảnh tối đa nếu allowMultiple = true
  /// 
  /// Returns: List<XFile> hoặc null nếu user cancel
  Future<List<XFile>?> showImageSourceDialog({
    required BuildContext context,
    bool allowMultiple = true,
    int maxImages = 3,
    double? maxWidth,
    double? maxHeight,
    int imageQuality = 85,
  }) async {
    return showModalBottomSheet<List<XFile>>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Chọn ảnh từ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const Divider(),

                // Camera option
                ListTile(
                  leading: const Icon(Icons.camera_alt, size: 28),
                  title: const Text('Chụp ảnh'),
                  subtitle: const Text('Sử dụng camera'),
                  onTap: () async {
                    try {
                      final XFile? image = await pickSingleImage(
                        source: ImageSource.camera,
                        maxWidth: maxWidth,
                        maxHeight: maxHeight,
                        imageQuality: imageQuality,
                      );
                      if (!context.mounted) return;
                      if (image != null) {
                        Navigator.pop(context, [image]);
                      } else {
                        Navigator.pop(context);
                      }
                    } on PlatformException catch (e) {
                      if (!context.mounted) return;
                      Navigator.pop(context); // Close bottom sheet
                      _showPermissionError(context, 'Camera', e.message);
                    }
                  },
                ),

                // Gallery option
                ListTile(
                  leading: const Icon(Icons.photo_library, size: 28),
                  title: Text(allowMultiple ? 'Chọn từ thư viện' : 'Chọn một ảnh'),
                  subtitle: Text(
                    allowMultiple ? 'Chọn tối đa $maxImages ảnh' : 'Chọn ảnh từ thiết bị',
                  ),
                  onTap: () async {
                    try {
                      if (allowMultiple) {
                        final List<XFile>? images = await pickMultipleImages(
                          maxImages: maxImages,
                          maxWidth: maxWidth,
                          maxHeight: maxHeight,
                          imageQuality: imageQuality,
                        );
                        if (!context.mounted) return;
                        if (images != null && images.isNotEmpty) {
                          Navigator.pop(context, images);
                        } else {
                          Navigator.pop(context);
                        }
                      } else {
                        final XFile? image = await pickSingleImage(
                          source: ImageSource.gallery,
                          maxWidth: maxWidth,
                          maxHeight: maxHeight,
                          imageQuality: imageQuality,
                        );
                        if (!context.mounted) return;
                        if (image != null) {
                          Navigator.pop(context, [image]);
                        } else {
                          Navigator.pop(context);
                        }
                      }
                    } on PlatformException catch (e) {
                      if (!context.mounted) return;
                      Navigator.pop(context); // Close bottom sheet
                      _showPermissionError(context, 'Thư viện', e.message);
                    }
                  },
                ),

                // Cancel button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Validate kích thước file ảnh
  /// 
  /// [file]: File ảnh cần validate
  /// [maxSizeInMB]: Kích thước tối đa tính bằng MB (default: 5MB)
  /// 
  /// Returns: true nếu ảnh hợp lệ, false nếu quá lớn
  Future<bool> validateImageSize(XFile file, {double maxSizeInMB = 5.0}) async {
    final int fileSizeInBytes = await file.length();
    final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
    
    if (fileSizeInMB > maxSizeInMB) {
      debugPrint('Image too large: ${fileSizeInMB.toStringAsFixed(2)}MB (max: $maxSizeInMB MB)');
      return false;
    }
    
    return true;
  }

  /// Validate danh sách ảnh
  /// 
  /// Returns: Map với keys:
  /// - 'valid': List<XFile> ảnh hợp lệ
  /// - 'invalid': List<XFile> ảnh không hợp lệ (quá lớn)
  Future<Map<String, List<XFile>>> validateImages(
    List<XFile> images, {
    double maxSizeInMB = 5.0,
  }) async {
    final List<XFile> valid = [];
    final List<XFile> invalid = [];

    for (final image in images) {
      final isValid = await validateImageSize(image, maxSizeInMB: maxSizeInMB);
      if (isValid) {
        valid.add(image);
      } else {
        invalid.add(image);
      }
    }

    return {'valid': valid, 'invalid': invalid};
  }

  /// Show error dialog khi không có permission
  void _showPermissionError(BuildContext context, String source, String? errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Không có quyền truy cập'),
        content: Text(
          'Ứng dụng cần quyền truy cập $source để tiếp tục. '
          'Vui lòng cấp quyền trong Cài đặt.\n\n'
          '${errorMessage ?? ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Get file size formatted string
  Future<String> getFormattedFileSize(XFile file) async {
    final int bytes = await file.length();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
