import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/favorite_model.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'rental_booking_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

  late final PageController _pageController;
  late final List<String> _images;
  int _imageIndex = 0;
  bool _isFavorite = false;
  bool _favoriteLoading = false;

  String _selectedSize = '';
  String _selectedColor = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _images = _buildImageList(widget.product);
    _selectedSize = widget.product.sizes.isNotEmpty
        ? widget.product.sizes.first
        : '';
    _selectedColor = widget.product.colors.isNotEmpty
        ? widget.product.colors.first
        : '';
    _loadFavoriteStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteStatus() async {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }

    final isFavorite = await _firebaseService.isFavorite(
      user.uid,
      widget.product.id,
    );
    if (!mounted) return;
    setState(() {
      _isFavorite = isFavorite;
    });
  }

  List<String> _buildImageList(Product product) {
    final list = <String>[];
    if (product.thumbnailUrl.trim().isNotEmpty) {
      list.add(product.thumbnailUrl.trim());
    }
    for (final url in product.imageUrls) {
      final value = url.trim();
      if (value.isNotEmpty && !list.contains(value)) {
        list.add(value);
      }
    }
    return list;
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteLoading) {
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      _showMessage(
        'Vui l\u00f2ng \u0111\u0103ng nh\u1eadp \u0111\u1ec3 d\u00f9ng y\u00eau th\u00edch',
      );
      return;
    }

    setState(() {
      _favoriteLoading = true;
    });

    try {
      if (_isFavorite) {
        await _firebaseService.removeFavorite(user.uid, widget.product.id);
      } else {
        await _firebaseService.addFavorite(
          user.uid,
          FavoriteModel(
            productId: widget.product.id,
            productName: widget.product.name,
            thumbnailUrl: widget.product.thumbnailUrl,
            rentalPricePerDay: widget.product.rentalPricePerDay,
            addedAt: DateTime.now(),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } finally {
      if (mounted) {
        setState(() {
          _favoriteLoading = false;
        });
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi ti\u1ebft s\u1ea3n ph\u1ea9m'),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: _favoriteLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isFavorite ? AppColors.favorite : null,
                  ),
            tooltip: 'Y\u00eau th\u00edch',
          ),
        ],
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 330,
            child: _images.isEmpty
                ? const _ImagePlaceholder()
                : Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: _images.length,
                        onPageChanged: (value) {
                          setState(() {
                            _imageIndex = value;
                          });
                        },
                        itemBuilder: (_, index) {
                          return Image.network(
                            _images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _ImagePlaceholder(),
                          );
                        },
                      ),
                      if (_images.length > 1)
                        Positioned(
                          bottom: 14,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_images.length, (index) {
                              final active = index == _imageIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: active ? 18 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MetaChip(
                      label: AppConstants.getCategoryName(product.category),
                    ),
                    const SizedBox(width: 8),
                    _MetaChip(
                      label: product.brand.isEmpty
                          ? 'Kh\u00f4ng r\u00f5 th\u01b0\u01a1ng hi\u1ec7u'
                          : product.brand,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${AppConstants.formatPrice(product.rentalPricePerDay)}/ng\u00e0y',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '\u0110\u1eb7t c\u1ecdc: ${AppConstants.formatPrice(product.depositAmount)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'M\u00f4 t\u1ea3 chi ti\u1ebft',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  product.description.isEmpty
                      ? 'S\u1ea3n ph\u1ea9m ch\u01b0a c\u00f3 m\u00f4 t\u1ea3 chi ti\u1ebft.'
                      : product.description,
                  style: const TextStyle(height: 1.45),
                ),
                const SizedBox(height: 16),
                _OptionSelector(
                  title: 'Ch\u1ecdn size',
                  options: product.sizes,
                  selected: _selectedSize,
                  onSelected: (value) {
                    setState(() {
                      _selectedSize = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _OptionSelector(
                  title: 'Ch\u1ecdn m\u00e0u',
                  options: product.colors,
                  selected: _selectedColor,
                  onSelected: (value) {
                    setState(() {
                      _selectedColor = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.star),
                    const SizedBox(width: 6),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${product.reviewCount} review)',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RentalBookingScreen(
                    product: product,
                    selectedSize: _selectedSize,
                    selectedColor: _selectedColor,
                  ),
                ),
              );
            },
            child: const Text('Thu\u00ea ngay'),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _OptionSelector extends StatelessWidget {
  const _OptionSelector({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (options.isEmpty)
          const Text(
            'Kh\u00f4ng c\u00f3 t\u00f9y ch\u1ecdn',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isActive = option == selected;
              return ChoiceChip(
                label: Text(option),
                selected: isActive,
                onSelected: (_) => onSelected(option),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.shimmerBase,
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_rounded,
        color: AppColors.textHint,
        size: 42,
      ),
    );
  }
}
