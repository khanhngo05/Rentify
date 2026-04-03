import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/cart_item_model.dart';
import '../models/branch_model.dart';
import '../models/favorite_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../providers/cart_provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'cart_booking_screen.dart';
import 'multi_cart_booking_screen.dart';
// Phần cấy thêm: Import Dialog giỏ hàng của Dũng (Nhớ báo Giang check lại đường dẫn nếu file để ở thư mục khác)
import '../widgets/common/add_to_cart_dialog.dart'; 

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

  String _selectedSize = '';
  String _selectedColor = '';
  List<BranchModel> _branches = <BranchModel>[];
  Map<String, BranchInventory> _inventoryByBranch = <String, BranchInventory>{};
  BranchModel? _selectedBranch;
  bool _isLoadingBranches = false;

  bool _isFavorite = false;
  bool _favoriteLoading = false;
  bool _isLoadingReviews = false;
  final Map<String, String> _reviewerNames = <String, String>{};
  bool _isSubmittingReview = false;
  bool _isCheckingReviewEligibility = false;
  List<ReviewModel> _reviews = <ReviewModel>[];
  double _averageRating = 0;
  int _reviewCount = 0;
  OrderModel? _eligibleReviewOrder;
  String _reviewBlockedMessage =
      'Bạn chỉ có thể đánh giá sau khi đơn thuê hoàn thành.';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _images = _collectImages(widget.product);
    _selectedSize = widget.product.sizes.isNotEmpty
        ? widget.product.sizes.first
        : '';
    _selectedColor = widget.product.colors.isNotEmpty
        ? widget.product.colors.first
        : '';
    _averageRating = widget.product.rating;
    _reviewCount = widget.product.reviewCount;
    _loadBranches();
    _loadFavoriteStatus();
    _loadReviews();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _collectImages(Product product) {
    final urls = <String>[];
    final thumb = product.thumbnailUrl.trim();
    if (thumb.isNotEmpty) {
      urls.add(thumb);
    }
    for (final value in product.imageUrls) {
      final v = value.trim();
      if (v.isNotEmpty && !urls.contains(v)) {
        urls.add(v);
      }
    }
    return urls;
  }

  Future<void> _loadFavoriteStatus() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final isFavorite = await _firebaseService.isFavorite(
      user.uid,
      widget.product.id,
    );
    if (!mounted) return;
    setState(() {
      _isFavorite = isFavorite;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteLoading) return;

    final user = _authService.currentUser;
    if (user == null) {
      _showMessage('Vui lòng đăng nhập để dùng yêu thích');
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

  Future<void> _loadBranches() async {
    setState(() {
      _isLoadingBranches = true;
    });

    try {
      final branches = await _firebaseService.getBranches();
      final inventoryResults = await Future.wait(
        branches.map(
          (branch) => _firebaseService.getProductInventory(
            branch.id,
            widget.product.id,
          ),
        ),
      );
      final inventoryByBranch = <String, BranchInventory>{};
      for (var i = 0; i < branches.length; i++) {
        final inventory = inventoryResults[i];
        if (inventory != null) {
          inventoryByBranch[branches[i].id] = inventory;
        }
      }

      if (!mounted) return;
      BranchModel? selectedBranch;
      if (branches.isNotEmpty) {
        selectedBranch = branches.firstWhere(
          (branch) => (inventoryByBranch[branch.id]?.availableStock ?? 0) > 0,
          orElse: () => branches.first,
        );
      }

      setState(() {
        _branches = branches;
        _inventoryByBranch = inventoryByBranch;
        _selectedBranch = selectedBranch;
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage('Không thể tải dữ liệu chi nhánh/tồn kho');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingBranches = false;
      });
    }
  }

  int _availableStockForBranch(String branchId) {
    return _inventoryByBranch[branchId]?.availableStock ?? 0;
  }

  bool _isOutOfStock(String branchId) {
    return _availableStockForBranch(branchId) <= 0;
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _rentNowWithNewCheckout() async {
    final selectedBranch = _selectedBranch;
    if (selectedBranch == null) {
      _showMessage('Vui lòng chọn chi nhánh trước khi đặt thuê');
      return;
    }

    final cartProvider = context.read<CartProvider>();
    final added = await cartProvider.addToCart(
      CartItemModel(
        productId: widget.product.id,
        productName: widget.product.name,
        imageUrl: widget.product.thumbnailUrl,
        selectedSize: _selectedSize,
        selectedColor: _selectedColor,
        rentalPricePerDay: widget.product.rentalPricePerDay.toDouble(),
        depositPrice: widget.product.depositAmount.toDouble(),
        branchId: selectedBranch.id,
        branchName: selectedBranch.name,
        branchAddress: selectedBranch.address,
        availableStock: _availableStockForBranch(selectedBranch.id),
      ),
    );

    if (!mounted) return;

    if (!added) {
      _showMessage('Sản phẩm đã đạt số lượng tồn kho tối đa trong giỏ hàng');
      return;
    }

    if (cartProvider.hasMultipleBranches) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MultiCartBookingScreen(),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartBookingScreen(
          branchId: selectedBranch.id,
          branchName: selectedBranch.name,
          branchAddress: selectedBranch.address,
        ),
      ),
    );
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
    });

    try {
      final reviews = await _firebaseService.getReviewsByProduct(widget.product.id);
      final reviewerNames = await _resolveReviewerNames(reviews);
      if (!mounted) return;

      double average = 0;
      if (reviews.isNotEmpty) {
        final total = reviews.fold<int>(0, (sum, item) => sum + item.rating);
        average = total / reviews.length;
      }

      setState(() {
        _reviews = reviews;
        _reviewerNames
          ..clear()
          ..addAll(reviewerNames);
        _reviewCount = reviews.length;
        _averageRating = reviews.isEmpty
            ? widget.product.rating
            : double.parse(average.toStringAsFixed(1));
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage('Không thể tải đánh giá sản phẩm');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  Future<Map<String, String>> _resolveReviewerNames(
    List<ReviewModel> reviews,
  ) async {
    final names = <String, String>{};

    for (final review in reviews) {
      final directName = (review.userDisplayName ?? '').trim();
      if (directName.isNotEmpty) {
        names[review.userId] = directName;
      }
    }

    final missingUserIds = reviews
        .map((review) => review.userId.trim())
        .where((id) => id.isNotEmpty && !names.containsKey(id))
        .toSet();
    if (missingUserIds.isEmpty) return names;

    await Future.wait(
      missingUserIds.map((userId) async {
        try {
          final user = await _firebaseService.getUserById(userId);
          final displayName = user?.displayName.trim() ?? '';
          if (displayName.isNotEmpty) {
            names[userId] = displayName;
          }
        } catch (_) {}
      }),
    );

    return names;
  }

  Future<void> _loadReviewEligibility() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _eligibleReviewOrder = null;
        _reviewBlockedMessage =
            'Vui lòng đăng nhập để đánh giá sản phẩm đã thuê.';
        _isCheckingReviewEligibility = false;
      });
      return;
    }

    setState(() {
      _isCheckingReviewEligibility = true;
    });

    try {
      final completedOrders = await _firebaseService.getCompletedOrdersByUser(
        user.uid,
      );
      final userReviews = await _firebaseService.getReviewsByUserAndProduct(
        user.uid,
        widget.product.id,
      );
      if (!mounted) return;

      final reviewedOrderIds = userReviews
          .map((review) => review.orderId.trim())
          .where((id) => id.isNotEmpty)
          .toSet();

      final ordersWithProduct = completedOrders.where((order) {
        return order.items.any(
          (item) => item.productId.trim() == widget.product.id,
        );
      }).toList();

      OrderModel? eligibleOrder;
      for (final order in ordersWithProduct) {
        if (!reviewedOrderIds.contains(order.id)) {
          eligibleOrder = order;
          break;
        }
      }

      String blockedMessage;
      if (eligibleOrder != null) {
        blockedMessage = '';
      } else if (ordersWithProduct.isEmpty) {
        blockedMessage =
            'Bạn chỉ có thể đánh giá sau khi đơn thuê sản phẩm này hoàn thành.';
      } else {
        blockedMessage = 'Bạn đã đánh giá hết các đơn hoàn thành của sản phẩm này.';
      }

      setState(() {
        _eligibleReviewOrder = eligibleOrder;
        _reviewBlockedMessage = blockedMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _eligibleReviewOrder = null;
        _reviewBlockedMessage =
            'Không thể kiểm tra điều kiện đánh giá lúc này.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isCheckingReviewEligibility = false;
      });
    }
  }

  // ignore: unused_element
  Future<void> _showReviewDialog() async {
    if (_isSubmittingReview || _isCheckingReviewEligibility) return;

    final user = _authService.currentUser;
    if (user == null) {
      _showMessage('Vui lòng đăng nhập để đánh giá sản phẩm');
      return;
    }

    final eligibleOrder = _eligibleReviewOrder;
    if (eligibleOrder == null) {
      _showMessage(
        _reviewBlockedMessage.isEmpty
            ? 'Bạn chưa đủ điều kiện để đánh giá sản phẩm này.'
            : _reviewBlockedMessage,
      );
      return;
    }

    final draft = await showDialog<_ReviewDraft>(
      context: context,
      builder: (_) => const _ReviewInputDialog(),
    );

    if (draft == null) return;

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      final review = ReviewModel(
        id: '',
        productId: widget.product.id,
        branchId: eligibleOrder.branchId,
        userId: user.uid,
        orderId: eligibleOrder.id,
        rating: draft.rating,
        comment: draft.comment?.trim().isEmpty == true
            ? null
            : draft.comment?.trim(),
        photoUrls: const <String>[],
        createdAt: DateTime.now(),
      );

      await _firebaseService.createReview(review);
      if (!mounted) return;
      await _loadReviews();
      await _loadReviewEligibility();
      _showMessage('Đã gửi đánh giá thành công');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Không thể gửi đánh giá lúc này');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmittingReview = false;
      });
    }
  }

  String _formatReviewDate(DateTime value) {
    return DateFormat(AppConstants.dateTimeFormat).format(value);
  }

  String _reviewUserLabel(String userId) {
    final fullName = _reviewerNames[userId.trim()]?.trim() ?? '';
    if (fullName.isNotEmpty) return fullName;

    final trimmed = userId.trim();
    if (trimmed.isEmpty) return 'Người dùng';
    if (trimmed.length <= 6) return trimmed;
    return 'User ${trimmed.substring(0, 6)}';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final canRent =
        _selectedBranch != null && !_isOutOfStock(_selectedBranch!.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            tooltip: 'Yêu thích',
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
          ),
        ],
      ),
      body: ListView(
        children: [
          Hero(
            tag: 'product_${product.id}',
            child: SizedBox(
              height: 330,
              child: _images.isEmpty
                  ? const _ImagePlaceholder()
                  : Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: _images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _imageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
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
                            left: 0,
                            right: 0,
                            bottom: 12,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_images.length, (index) {
                                final isActive = _imageIndex == index;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: isActive ? 18 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      label: AppConstants.getCategoryName(product.category),
                    ),
                    _MetaChip(
                      label: product.brand.isEmpty
                          ? 'Không rõ thương hiệu'
                          : product.brand,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${AppConstants.formatPrice(product.rentalPricePerDay)}/ngày',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Đặt cọc: ${AppConstants.formatPrice(product.depositAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mô tả chi tiết',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  product.description.isEmpty
                      ? 'Sản phẩm chưa có mô tả chi tiết.'
                      : product.description,
                  style: const TextStyle(height: 1.4),
                ),
                const SizedBox(height: 16),
                _OptionSelector(
                  title: 'Chọn size',
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
                  title: 'Chọn màu',
                  options: product.colors,
                  selected: _selectedColor,
                  onSelected: (value) {
                    setState(() {
                      _selectedColor = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chọn chi nhánh nhận đồ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (_isLoadingBranches)
                  const LinearProgressIndicator(minHeight: 3)
                else if (_branches.isEmpty)
                  const Text(
                    'Chưa có chi nhánh khả dụng',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _branches.map((branch) {
                      final isSelected = _selectedBranch?.id == branch.id;
                      final availableStock = _availableStockForBranch(
                        branch.id,
                      );
                      final isOutOfStock = availableStock <= 0;
                      return ChoiceChip(
                        label: Text(
                          '${branch.name} • ${isOutOfStock ? 'Hết hàng' : 'Còn $availableStock'}',
                        ),
                        showCheckmark: isSelected,
                        checkmarkColor: Colors.white,
                        backgroundColor: isOutOfStock
                            ? AppColors.surfaceVariant
                            : Colors.white,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isOutOfStock
                              ? AppColors.textHint
                              : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : AppColors.border,
                        ),
                        selected: isSelected,
                        onSelected: isOutOfStock
                            ? null
                            : (_) {
                                setState(() {
                                  _selectedBranch = branch;
                                });
                              },
                      );
                    }).toList(),
                  ),
                  if (_selectedBranch != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedBranch!.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedBranch!.address,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hotline: ${_selectedBranch!.phone}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isOutOfStock(_selectedBranch!.id)
                                ? 'Tồn kho: Hết hàng'
                                : 'Tồn kho: Còn ${_availableStockForBranch(_selectedBranch!.id)} sản phẩm',
                            style: TextStyle(
                              color: _isOutOfStock(_selectedBranch!.id)
                                  ? Colors.red
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.star),
                    const SizedBox(width: 6),
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($_reviewCount đánh giá)',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Đánh giá sản phẩm tại mục Đơn hàng, trong đơn Hoàn thành.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoadingReviews)
                  const LinearProgressIndicator(minHeight: 3)
                else if (_reviews.isEmpty)
                  const Text(
                    'Chưa có đánh giá nào cho sản phẩm này.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  Column(
                    children: _reviews.take(5).map((review) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _reviewUserLabel(review.userId),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatReviewDate(review.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 2,
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < review.rating
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 16,
                                  color: AppColors.star,
                                );
                              }),
                            ),
                            if ((review.comment ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(review.comment!.trim()),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          // Phần cấy thêm: Sửa nút Thuê ngay độc lập thành 1 Row chứa cả 2 nút
          child: Row(
            children: [
              // Nút Thêm vào giỏ (Gọi AddToCartDialog của Dũng)
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  onPressed: canRent
                      ? () {
                          final selectedBranch = _selectedBranch!;
                          showDialog(
                            context: context,
                            builder: (context) => AddToCartDialog(
                              productId: product.id,
                              productName: product.name,
                              imageUrl: product.thumbnailUrl,
                              rentalPrice: product.rentalPricePerDay.toDouble(),
                              depositPrice: product.depositAmount.toDouble(),
                              selectedSize: _selectedSize,
                              selectedColor: _selectedColor,
                              branchId: selectedBranch.id,
                              branchName: selectedBranch.name,
                              branchAddress: selectedBranch.address,
                              availableStock: _availableStockForBranch(
                                selectedBranch.id,
                              ),
                            ),
                          );
                        }
                      : null,
                  child: const Text(
                    'Thêm vào giỏ',
                    style: TextStyle(
                      color: AppColors.primary, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nút Thuê ngay (Giữ nguyên logic gốc của Giang)
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: canRent
                      ? _rentNowWithNewCheckout
                      : null,
                  child: const Text(
                    'Thuê ngay',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewDraft {
  const _ReviewDraft({required this.rating, this.comment});

  final int rating;
  final String? comment;
}

class _ReviewInputDialog extends StatefulWidget {
  const _ReviewInputDialog();

  @override
  State<_ReviewInputDialog> createState() => _ReviewInputDialogState();
}

class _ReviewInputDialogState extends State<_ReviewInputDialog> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _ReviewDraft(
        rating: _rating,
        comment: _commentController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đánh giá sản phẩm'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mức độ hài lòng'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = star;
                    });
                  },
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    star <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.star,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nhận xét (không bắt buộc)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _submit,
          child: const Text('Gửi'),
        ),
      ],
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
            'Không có tùy chọn',
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
                showCheckmark: isActive,
                checkmarkColor: Colors.white,
                backgroundColor: Colors.white,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isActive ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: isActive ? Colors.transparent : AppColors.border,
                ),
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
