import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';

/// Màn hình quản lý người dùng
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  Map<String, int> _orderCounts = {};
  bool _isLoading = true;
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _adminService.getAllUsers();

      // Load order counts for each user
      final orderCounts = <String, int>{};
      for (final user in users) {
        final count = await _adminService.getUserOrderCount(user.uid);
        orderCounts[user.uid] = count;
      }

      setState(() {
        _users = users;
        _orderCounts = orderCounts;
        _filterUsers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((u) {
        // Filter by role
        if (_roleFilter != 'all' && u.role != _roleFilter) return false;

        // Filter by search
        if (query.isNotEmpty) {
          return u.displayName.toLowerCase().contains(query) ||
              u.email.toLowerCase().contains(query) ||
              (u.phoneNumber?.contains(query) ?? false);
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminCount = _users.where((u) => u.role == 'admin').length;
    final userCount = _users.where((u) => u.role == 'user').length;

    return Column(
      children: [
        // Search and filter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, email, SĐT...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterChip('Tất cả', 'all', _users.length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Admin', 'admin', adminCount),
                  const SizedBox(width: 8),
                  _buildFilterChip('User', 'user', userCount),
                ],
              ),
            ],
          ),
        ),

        // Stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surfaceVariant,
          child: Row(
            children: [
              Text(
                'Hiển thị: ${_filteredUsers.length} người dùng',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // User list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: AppColors.textHint),
                          SizedBox(height: 16),
                          Text('Không tìm thấy người dùng',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          return _buildUserItem(_filteredUsers[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _roleFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : AppColors.textHint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : Colors.white,
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      backgroundColor: AppColors.surfaceVariant,
      showCheckmark: false,
      onSelected: (selected) {
        setState(() {
          _roleFilter = selected ? value : 'all';
          _filterUsers();
        });
      },
    );
  }

  Widget _buildUserItem(UserModel user) {
    final orderCount = _orderCounts[user.uid] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: user.avatarUrl != null &&
                          user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: user.isAdmin
                                  ? AppColors.warning.withOpacity(0.1)
                                  : AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              user.isAdmin ? 'Admin' : 'User',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: user.isAdmin
                                    ? AppColors.warning
                                    : AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (user.phoneNumber != null &&
                          user.phoneNumber!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.phoneNumber!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Stats and actions
            Row(
              children: [
                // Order count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '$orderCount đơn',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Join date
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(user.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Actions
                PopupMenuButton<String>(
                  onSelected: (value) => _handleUserAction(value, user),
                  itemBuilder: (context) => [
                    if (!user.isAdmin)
                      const PopupMenuItem(
                        value: 'make_admin',
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings, size: 20),
                            SizedBox(width: 8),
                            Text('Cấp quyền Admin'),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'remove_admin',
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 20),
                            SizedBox(width: 8),
                            Text('Hủy quyền Admin'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleUserAction(String action, UserModel user) async {
    switch (action) {
      case 'make_admin':
        _confirmRoleChange(user, AppConstants.roleAdmin);
        break;
      case 'remove_admin':
        _confirmRoleChange(user, AppConstants.roleUser);
        break;
    }
  }

  void _confirmRoleChange(UserModel user, String newRole) {
    final isPromotion = newRole == AppConstants.roleAdmin;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPromotion ? 'Cấp quyền Admin' : 'Hủy quyền Admin'),
        content: Text(
          isPromotion
              ? 'Bạn có chắc muốn cấp quyền Admin cho "${user.displayName}"?\n\nAdmin có thể quản lý toàn bộ hệ thống.'
              : 'Bạn có chắc muốn hủy quyền Admin của "${user.displayName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _adminService.updateUserRole(user.uid, newRole);
                await _loadUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isPromotion
                            ? 'Đã cấp quyền Admin'
                            : 'Đã hủy quyền Admin',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isPromotion ? AppColors.warning : AppColors.textSecondary,
              foregroundColor: Colors.white,
            ),
            child: Text(isPromotion ? 'Cấp quyền' : 'Hủy quyền'),
          ),
        ],
      ),
    );
  }
}
