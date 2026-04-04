import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/favorite_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/biometric_preference_service.dart';
import '../services/biometric_service.dart';
import '../services/firebase_service.dart';
import '../services/supabase_service.dart';
import 'history_screen.dart';
import 'product_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final BiometricPreferenceService _biometricPreferenceService =
      BiometricPreferenceService();
  final BiometricService _biometricService = BiometricService();
  final FirebaseService _firebaseService = FirebaseService();
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _imagePicker = ImagePicker();

  UserModel? _user;
  bool _isLoadingProfile = true;
  bool _isSavingProfile = false;
  bool _isUploadingAvatar = false;
  bool _isSigningOut = false;
  bool _biometricLoginEnabled = false;
  bool _isUpdatingBiometricSetting = false;

  List<FavoriteModel> _favorites = <FavoriteModel>[];
  bool _isLoadingFavorites = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait(<Future<void>>[
      _loadProfile(),
      _loadFavorites(),
      _loadBiometricPreference(),
    ]);
  }

  Future<void> _loadBiometricPreference() async {
    final current = _authService.currentUser;
    if (current == null) {
      if (!mounted) return;
      setState(() {
        _biometricLoginEnabled = false;
      });
      return;
    }

    final isEnabled = await _biometricPreferenceService.isEnabledForUser(
      current.uid,
    );
    if (!mounted) return;

    setState(() {
      _biometricLoginEnabled = isEnabled;
    });
  }

  Future<void> _onBiometricSwitchChanged(bool value) async {
    final current = _authService.currentUser;
    if (current == null || _isUpdatingBiometricSetting) {
      return;
    }

    setState(() {
      _isUpdatingBiometricSetting = true;
    });

    try {
      if (!value) {
        await _biometricPreferenceService.setEnabledForUser(current.uid, false);
        await _biometricPreferenceService.clearRememberedUserProfile();
        if (!mounted) return;
        setState(() {
          _biometricLoginEnabled = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tắt đăng nhập Face ID')),
        );
        return;
      }

      final result = await _biometricService.authenticateForLogin();
      if (result == BiometricAuthResult.verified) {
        await _biometricPreferenceService.setEnabledForUser(current.uid, true);
        await _biometricPreferenceService.saveRememberedUserProfile(
          current,
          displayNameOverride: _user?.displayName,
          avatarUrlOverride: _user?.avatarUrl,
          emailOverride: _user?.email,
        );
        if (!mounted) return;
        setState(() {
          _biometricLoginEnabled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã bật đăng nhập Face ID')),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _biometricLoginEnabled = false;
      });

      if (result == BiometricAuthResult.unavailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thiết bị chưa bật Face ID để sử dụng tính năng này'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xác thực sinh trắc học')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingBiometricSetting = false;
        });
      }
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    final current = _authService.currentUser;
    if (current == null) {
      if (!mounted) return;
      setState(() {
        _user = null;
        _isLoadingProfile = false;
      });
      return;
    }

    try {
      final user = await _firebaseService.getUserById(current.uid);
      if (!mounted) return;
      final effectiveUser =
          user ??
          UserModel(
            uid: current.uid,
            email: current.email ?? '',
            displayName: current.displayName ?? 'Người dùng Rentify',
            phoneNumber: current.phoneNumber,
            avatarUrl: current.photoURL,
            createdAt: DateTime.now(),
          );

      await _biometricPreferenceService.saveRememberedUserProfile(
        current,
        displayNameOverride: effectiveUser.displayName,
        avatarUrlOverride: effectiveUser.avatarUrl,
        emailOverride: effectiveUser.email,
      );

      if (!mounted) return;
      setState(() {
        _user = effectiveUser;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoadingFavorites = true;
    });

    final current = _authService.currentUser;
    if (current == null) {
      if (!mounted) return;
      setState(() {
        _favorites = <FavoriteModel>[];
        _isLoadingFavorites = false;
      });
      return;
    }

    try {
      final favorites = await _firebaseService.getFavoritesByUser(current.uid);
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingFavorites = false;
      });
    }
  }

  Future<void> _showEditProfileDialog() async {
    final user = _user;
    final current = _authService.currentUser;
    if (user == null || current == null || _isSavingProfile) return;

    final nameController = TextEditingController(text: user.displayName);
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    final avatarController = TextEditingController(text: user.avatarUrl ?? '');
    final addressController = TextEditingController(text: user.address ?? '');

    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (_) {
        final currentAvatarUrl = avatarController.text.trim();
        return AlertDialog(
          title: const Text('Chỉnh sửa thông tin cá nhân'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.surfaceVariant,
                    backgroundImage: currentAvatarUrl.isNotEmpty
                        ? NetworkImage(currentAvatarUrl)
                        : null,
                    child: currentAvatarUrl.isEmpty
                        ? Text(
                            (nameController.text.trim().isNotEmpty
                                    ? nameController.text
                                          .trim()
                                          .characters
                                          .first
                                    : 'R')
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingAvatar
                          ? null
                          : () async {
                              final picked = await _imagePicker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                                maxWidth: 1200,
                              );
                              if (picked == null || !mounted) return;

                              setState(() {
                                _isUploadingAvatar = true;
                              });

                              try {
                                final uploadUrl = await _supabaseService
                                    .uploadAvatarBytes(
                                      userId: current.uid,
                                      imageBytes: await picked.readAsBytes(),
                                      fileExtension: _getFileExtension(
                                        picked.name,
                                      ),
                                    );

                                if (uploadUrl == null || !mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Upload ảnh thất bại'),
                                    ),
                                  );
                                  return;
                                }

                                avatarController.text = uploadUrl;
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Đã tải ảnh đại diện lên Supabase',
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isUploadingAvatar = false;
                                  });
                                }
                              }
                            },
                      icon: _isUploadingAvatar
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_rounded),
                      label: Text(
                        _isUploadingAvatar
                            ? 'Đang tải ảnh...'
                            : 'Chọn ảnh đại diện từ thiết bị',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: user.email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    readOnly: true,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: _isUploadingAvatar
                  ? null
                  : () {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      Navigator.of(context).pop(true);
                    },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true || !mounted) {
      nameController.dispose();
      phoneController.dispose();
      avatarController.dispose();
      addressController.dispose();
      return;
    }

    setState(() {
      _isSavingProfile = true;
    });

    try {
      final updatedDisplayName = nameController.text.trim();
      final updatedPhoneNumber = phoneController.text.trim();
      final updatedAvatarUrl = avatarController.text.trim();
      final updatedAddress = addressController.text.trim();

      await _firebaseService.updateUser(current.uid, {
        'displayName': updatedDisplayName,
        'phoneNumber': updatedPhoneNumber,
        'avatarUrl': updatedAvatarUrl,
        'address': updatedAddress,
      });
      await current.updateDisplayName(updatedDisplayName);
      await _biometricPreferenceService.saveRememberedUserProfile(
        current,
        displayNameOverride: updatedDisplayName,
        avatarUrlOverride: updatedAvatarUrl,
        emailOverride: user.email,
      );
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật hồ sơ')));
    } finally {
      nameController.dispose();
      phoneController.dispose();
      avatarController.dispose();
      addressController.dispose();
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  Future<void> _removeFavorite(String productId) async {
    final current = _authService.currentUser;
    if (current == null) return;

    await _firebaseService.removeFavorite(current.uid, productId);
    await _loadFavorites();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa khỏi yêu thích')));
  }

  Future<void> _showSignOutDialog() async {
    if (_isSigningOut) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _biometricPreferenceService.saveRememberedUserProfile(
          currentUser,
          displayNameOverride: _user?.displayName,
          avatarUrlOverride: _user?.avatarUrl,
          emailOverride: _user?.email,
        );
      }

      await _authService.signOut();
      if (!mounted) return;
      setState(() {
        _user = null;
        _favorites = <FavoriteModel>[];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đăng xuất thành công')));
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  String _getFileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return 'jpg';
    }

    final ext = fileName.substring(dotIndex + 1).toLowerCase();
    if (ext.isEmpty) return 'jpg';
    return ext;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tài khoản')),
        body: const Center(
          child: Text(
            'Bạn chưa đăng nhập',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final user = _user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileHeaderCard(
              user: user,
              onEdit: _showEditProfileDialog,
              isSaving: _isSavingProfile,
            ),
            const SizedBox(height: 14),
            _ActionCard(
              title: 'Lịch sử thuê',
              subtitle: 'Xem lại các đơn đã đặt',
              icon: Icons.history_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _ActionCard(
              title: 'Yêu thích',
              subtitle: 'Danh sách sản phẩm bạn đã lưu',
              icon: Icons.favorite_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoriteListScreen()),
                );
              },
            ),
            const SizedBox(height: 14),
            _SectionCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.fingerprint_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kích hoạt Faceid, vân tay',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sau khi bật, lần đăng nhập sau chỉ cần quét sinh trắc học',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _biometricLoginEnabled,
                    onChanged: _isUpdatingBiometricSetting
                        ? null
                        : _onBiometricSwitchChanged,
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mục yêu thích gần đây',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingFavorites)
                    const LinearProgressIndicator(minHeight: 3)
                  else if (_favorites.isEmpty)
                    const Text(
                      'Chưa có sản phẩm yêu thích nào',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  else
                    ..._favorites
                        .take(3)
                        .map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.thumbnailUrl,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 52,
                                  height: 52,
                                  color: AppColors.shimmerBase,
                                  child: const Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(item.productName),
                            subtitle: Text(
                              AppConstants.formatPrice(item.rentalPricePerDay),
                            ),
                            trailing: IconButton(
                              tooltip: 'Xóa khỏi yêu thích',
                              onPressed: () => _removeFavorite(item.productId),
                              icon: const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.favorite,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: _isSigningOut ? null : _showSignOutDialog,
                icon: _isSigningOut
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.logout_rounded),
                label: const Text('Đăng xuất'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteListScreen extends StatefulWidget {
  const FavoriteListScreen({super.key});

  @override
  State<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends State<FavoriteListScreen> {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  List<FavoriteModel> _favorites = <FavoriteModel>[];
  List<Product> _products = <Product>[];
  Set<String> _favoriteIds = <String>{};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final current = _authService.currentUser;
    if (current == null) {
      if (!mounted) return;
      setState(() {
        _favorites = <FavoriteModel>[];
        _products = <Product>[];
        _favoriteIds = <String>{};
        _isLoading = false;
      });
      return;
    }

    try {
      final results = await Future.wait<dynamic>([
        _firebaseService.getFavoritesByUser(current.uid),
        _firebaseService.getProducts(),
      ]);
      final favorites = results[0] as List<FavoriteModel>;
      final products = results[1] as List<Product>;

      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _products = products;
        _favoriteIds = favorites.map((e) => e.productId).toSet();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(Product product) async {
    final current = _authService.currentUser;
    if (current == null) return;

    final isFavorite = _favoriteIds.contains(product.id);
    if (isFavorite) {
      await _firebaseService.removeFavorite(current.uid, product.id);
    } else {
      await _firebaseService.addFavorite(
        current.uid,
        FavoriteModel(
          productId: product.id,
          productName: product.name,
          thumbnailUrl: product.thumbnailUrl,
          rentalPricePerDay: product.rentalPricePerDay,
          addedAt: DateTime.now(),
        ),
      );
    }

    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? 'Đã xóa khỏi yêu thích' : 'Đã thêm vào yêu thích',
        ),
      ),
    );
  }

  Future<void> _openProductDetail(String productId) async {
    final product = await _firebaseService.getProductById(productId);
    if (!mounted) return;
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sản phẩm không còn khả dụng')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm yêu thích')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Đã lưu ${_favorites.length} sản phẩm',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_favorites.isEmpty)
                    const _SectionCard(
                      child: Text(
                        'Bạn chưa có sản phẩm yêu thích nào.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    _SectionCard(
                      child: Column(
                        children: _favorites
                            .map(
                              (item) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                onTap: () => _openProductDetail(item.productId),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.thumbnailUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 56,
                                      height: 56,
                                      color: AppColors.shimmerBase,
                                      child: const Icon(
                                        Icons.image_not_supported_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(item.productName),
                                subtitle: Text(
                                  '${AppConstants.formatPrice(item.rentalPricePerDay)}/ngày',
                                ),
                                trailing: IconButton(
                                  tooltip: 'Bỏ yêu thích',
                                  onPressed: () {
                                    final product = _products.firstWhere(
                                      (p) => p.id == item.productId,
                                      orElse: () => Product(
                                        id: item.productId,
                                        name: item.productName,
                                        description: '',
                                        rentalPricePerDay:
                                            item.rentalPricePerDay,
                                        depositAmount: 0,
                                        thumbnailUrl: item.thumbnailUrl,
                                        category: 'phu_kien',
                                        createdAt: DateTime.now(),
                                        updatedAt: DateTime.now(),
                                      ),
                                    );
                                    _toggleFavorite(product);
                                  },
                                  icon: const Icon(
                                    Icons.favorite_rounded,
                                    color: AppColors.favorite,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gợi ý thêm sản phẩm',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    child: Column(
                      children: _products.take(8).map((product) {
                        final isFavorite = _favoriteIds.contains(product.id);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            );
                          },
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.thumbnailUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: AppColors.shimmerBase,
                                child: const Icon(
                                  Icons.image_not_supported_rounded,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${AppConstants.formatPrice(product.rentalPricePerDay)}/ngày',
                          ),
                          trailing: IconButton(
                            tooltip: isFavorite
                                ? 'Xóa khỏi yêu thích'
                                : 'Thêm vào yêu thích',
                            onPressed: () => _toggleFavorite(product),
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite
                                  ? AppColors.favorite
                                  : AppColors.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.user,
    required this.onEdit,
    required this.isSaving,
  });

  final UserModel user;
  final VoidCallback onEdit;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = (user.avatarUrl ?? '').trim();
    return _SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? Text(
                    (user.displayName.isNotEmpty
                            ? user.displayName.characters.first
                            : 'R')
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  user.phoneNumber?.isNotEmpty == true
                      ? user.phoneNumber!
                      : 'Chưa cập nhật số điện thoại',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (user.address?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.address!,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : onEdit,
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_rounded),
                  label: const Text('Chỉnh sửa thông tin'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
