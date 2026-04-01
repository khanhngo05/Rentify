import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/favorite_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

  late Future<List<FavoriteModel>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _loadFavorites();
  }

  Future<List<FavoriteModel>> _loadFavorites() async {
    final user = _authService.currentUser;
    if (user == null) {
      return [];
    }
    return _firebaseService.getFavoritesByUser(user.uid);
  }

  Future<void> _refresh() async {
    setState(() {
      _favoritesFuture = _loadFavorites();
    });
  }

  Future<void> _removeFavorite(String productId) async {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }

    await _firebaseService.removeFavorite(user.uid, productId);
    await _refresh();
  }

  Future<void> _openDetail(FavoriteModel favorite) async {
    final product = await _firebaseService.getProductById(favorite.productId);
    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kh\u00f4ng t\u00ecm th\u1ea5y s\u1ea3n ph\u1ea9m'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<List<FavoriteModel>>(
      future: _favoritesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c danh s\u00e1ch y\u00eau th\u00edch',
            ),
          );
        }

        final favorites = snapshot.data ?? [];
        if (favorites.isEmpty) {
          return const Center(
            child: Text(
              'B\u1ea1n ch\u01b0a c\u00f3 s\u1ea3n ph\u1ea9m y\u00eau th\u00edch',
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              return InkWell(
                onTap: () => _openDetail(favorite),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          favorite.thumbnailUrl,
                          width: 74,
                          height: 74,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 74,
                            height: 74,
                            color: AppColors.shimmerBase,
                            child: const Icon(Icons.broken_image_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              favorite.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${AppConstants.formatPrice(favorite.rentalPricePerDay)}/ng\u00e0y',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeFavorite(favorite.productId),
                        icon: const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.favorite,
                        ),
                        tooltip: 'X\u00f3a kh\u1ecfi y\u00eau th\u00edch',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(title: const Text('Y\u00eau th\u00edch')),
        body: body,
      );
    }

    return body;
  }
}
