import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/product_model.dart';

/// Widget thẻ sản phẩm dùng trong GridView
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ảnh sản phẩm ──────────────────────────────────
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Ảnh
                  _ProductImage(product: product),

                  // Nút yêu thích ❤️
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? AppColors.favorite
                              : AppColors.textHint,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  // Badge danh mục
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppConstants.getCategoryName(product.category),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Thông tin sản phẩm ────────────────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên sản phẩm
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),

                    // Đánh giá
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.star,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '(${product.reviewCount})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Giá thuê
                    Text(
                      '${AppConstants.formatPrice(product.rentalPricePerDay)}/ngày',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatefulWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  State<_ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<_ProductImage> {
  late List<String> _candidates;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _candidates = _buildCandidates(widget.product);
  }

  @override
  void didUpdateWidget(covariant _ProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id ||
        oldWidget.product.thumbnailUrl != widget.product.thumbnailUrl ||
        oldWidget.product.imageUrls != widget.product.imageUrls) {
      _candidates = _buildCandidates(widget.product);
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_candidates.isEmpty) {
      return _buildImageError();
    }

    final imageUrl = _candidates[_currentIndex];
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildImagePlaceholder();
      },
      errorBuilder: (_, __, ___) {
        _tryNextImage();
        return _buildImageError();
      },
    );
  }

  void _tryNextImage() {
    if (!mounted) return;
    if (_currentIndex >= _candidates.length - 1) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _currentIndex += 1;
      });
    });
  }

  List<String> _buildCandidates(Product product) {
    final urls = <String>[];

    final thumb = product.thumbnailUrl.trim();
    if (thumb.isNotEmpty) {
      final normalized = _normalizeImageUrl(thumb);
      if (normalized.isNotEmpty) {
        urls.add(normalized);
      }
    }

    for (final value in product.imageUrls) {
      final url = value.trim();
      if (url.isEmpty) continue;
      final normalized = _normalizeImageUrl(url);
      if (normalized.isNotEmpty && !urls.contains(normalized)) {
        urls.add(normalized);
      }
    }

    return urls;
  }

  String _normalizeImageUrl(String rawUrl) {
    final url = rawUrl.trim();
    if (url.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return Uri.encodeFull(url);
    }

    final host = uri.host.toLowerCase();
    if (!host.contains('drive.google.com')) {
      return Uri.encodeFull(url);
    }

    String? fileId;
    final segments = uri.pathSegments;

    final dIndex = segments.indexOf('d');
    if (dIndex != -1 && dIndex + 1 < segments.length) {
      fileId = segments[dIndex + 1];
    }

    fileId ??= uri.queryParameters['id'];

    if (fileId == null || fileId.isEmpty) {
      return Uri.encodeFull(url);
    }

    return 'https://drive.google.com/uc?export=view&id=$fileId';
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.shimmerBase,
      child: const Center(
        child: Icon(
          Icons.checkroom_rounded,
          color: AppColors.textHint,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: AppColors.shimmerBase,
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: AppColors.textHint,
          size: 32,
        ),
      ),
    );
  }
}
