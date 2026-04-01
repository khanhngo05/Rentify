import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'favorites_screen.dart';
import 'rental_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

  UserModel? _userModel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
    });

    final currentUser = _authService.currentUser;
    UserModel? model;
    if (currentUser != null) {
      model = await _firebaseService.getUserById(currentUser.uid);
      model ??= UserModel(
        uid: currentUser.uid,
        email: currentUser.email ?? '',
        displayName:
            currentUser.displayName ?? 'Ng\u01b0\u1eddi d\u00f9ng Rentify',
        phoneNumber: currentUser.phoneNumber,
        createdAt: DateTime.now(),
      );
    }

    if (!mounted) return;
    setState(() {
      _userModel = model;
      _loading = false;
    });
  }

  Future<void> _showEditProfileDialog() async {
    if (_userModel == null) {
      return;
    }

    final nameController = TextEditingController(text: _userModel!.displayName);
    final phoneController = TextEditingController(
      text: _userModel!.phoneNumber ?? '',
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ch\u1ec9nh s\u1eeda th\u00f4ng tin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'H\u1ecd t\u00ean',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'S\u1ed1 \u0111i\u1ec7n tho\u1ea1i',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('H\u1ee7y'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('L\u01b0u'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return;
    }

    await _firebaseService.updateUser(currentUser.uid, {
      'displayName': nameController.text.trim(),
      'phoneNumber': phoneController.text.trim().isEmpty
          ? null
          : phoneController.text.trim(),
    });

    await _loadProfile();
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('\u0110\u00e3 \u0111\u0103ng xu\u1ea5t')),
    );

    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _userModel == null
        ? const Center(
            child: Text(
              'Ch\u01b0a \u0111\u0103ng nh\u1eadp \u0111\u1ec3 xem profile',
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.surfaceVariant,
                      backgroundImage:
                          _userModel!.avatarUrl != null &&
                              _userModel!.avatarUrl!.isNotEmpty
                          ? NetworkImage(_userModel!.avatarUrl!)
                          : null,
                      child:
                          _userModel!.avatarUrl == null ||
                              _userModel!.avatarUrl!.isEmpty
                          ? const Icon(Icons.person_rounded, size: 40)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userModel!.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_userModel!.email),
                    const SizedBox(height: 4),
                    Text(
                      _userModel!.phoneNumber ??
                          'Ch\u01b0a c\u1eadp nh\u1eadt s\u1ed1 \u0111i\u1ec7n tho\u1ea1i',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _showEditProfileDialog,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text(
                        'Ch\u1ec9nh s\u1eeda th\u00f4ng tin c\u00e1 nh\u00e2n',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ProfileActionTile(
                icon: Icons.history_rounded,
                title: 'L\u1ecbch s\u1eed thu\u00ea',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RentalHistoryScreen(),
                    ),
                  );
                },
              ),
              _ProfileActionTile(
                icon: Icons.favorite_rounded,
                title: 'Y\u00eau th\u00edch',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FavoritesScreen(showAppBar: true),
                    ),
                  );
                },
              ),
              _ProfileActionTile(
                icon: Icons.logout_rounded,
                title: '\u0110\u0103ng xu\u1ea5t',
                iconColor: AppColors.error,
                onTap: _logout,
              ),
            ],
          );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(title: const Text('T\u00e0i kho\u1ea3n')),
        body: body,
      );
    }

    return body;
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor ?? AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
