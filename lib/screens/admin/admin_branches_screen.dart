import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/branch_model.dart';
import '../../services/admin_service.dart';
import 'admin_branch_form_screen.dart';
import 'admin_branch_inventory_screen.dart';

/// Màn hình quản lý chi nhánh
class AdminBranchesScreen extends StatefulWidget {
  const AdminBranchesScreen({super.key});

  @override
  State<AdminBranchesScreen> createState() => _AdminBranchesScreenState();
}

class _AdminBranchesScreenState extends State<AdminBranchesScreen> {
  final AdminService _adminService = AdminService();

  List<BranchModel> _branches = [];
  bool _isLoading = true;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoading = true);
    try {
      final branches = await _adminService.getAllBranches();
      setState(() {
        _branches = branches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  List<BranchModel> get _filteredBranches {
    if (_showInactive) return _branches;
    return _branches.where((b) => b.isActive).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tổng: ${_filteredBranches.length} chi nhánh',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _addBranch,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilterChip(
                label: Text(
                  'Đã đóng',
                  style: TextStyle(
                    color: _showInactive ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                selected: _showInactive,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                backgroundColor: AppColors.surfaceVariant,
                onSelected: (v) {
                  setState(() => _showInactive = v);
                },
              ),
            ],
          ),
        ),

        // Branch list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredBranches.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.store_outlined,
                        size: 64,
                        color: AppColors.textHint,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Không có chi nhánh nào',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBranches,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredBranches.length,
                    itemBuilder: (context, index) {
                      return _buildBranchItem(_filteredBranches[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBranchItem(BranchModel branch) {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final todayHours = branch.openingHours[dayName];
    final isOpenToday = todayHours?.isOpen ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: () => _editBranch(branch),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Image header
            if (branch.imageUrl != null && branch.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  branch.imageUrl!,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: AppColors.shimmerBase,
                    child: const Icon(
                      Icons.store,
                      size: 40,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          branch.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: branch.isActive
                              ? (isOpenToday
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.warning.withOpacity(0.1))
                              : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          branch.isActive
                              ? (isOpenToday ? 'Đang mở' : 'Nghỉ hôm nay')
                              : 'Đã đóng',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: branch.isActive
                                ? (isOpenToday
                                      ? AppColors.success
                                      : AppColors.warning)
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Address
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          branch.address,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Phone
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        branch.phone,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  if (isOpenToday && todayHours != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${todayHours.open} - ${todayHours.close}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Divider(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: _buildBranchActionButton(
                            onPressed: () => _viewInventory(branch),
                            icon: Icons.inventory_2,
                            label: 'Tồn kho',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: _buildBranchActionButton(
                            onPressed: () => _editBranch(branch),
                            icon: Icons.edit,
                            label: 'Chỉnh sửa',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border.withOpacity(0.6),
                          ),
                        ),
                        child: IconButton(
                          onPressed: () => _toggleBranchStatus(branch),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          tooltip: branch.isActive ? 'Đóng cửa' : 'Mở cửa',
                          icon: Icon(
                            branch.isActive
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: branch.isActive
                                ? AppColors.textHint
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withOpacity(0.7), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return days[weekday - 1];
  }

  void _addBranch() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminBranchFormScreen()),
    );
    if (result == true) {
      _loadBranches();
    }
  }

  void _editBranch(BranchModel branch) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminBranchFormScreen(branch: branch)),
    );
    if (result == true) {
      _loadBranches();
    }
  }

  void _viewInventory(BranchModel branch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminBranchInventoryScreen(branch: branch),
      ),
    );
  }

  void _toggleBranchStatus(BranchModel branch) async {
    final action = branch.isActive ? 'đóng cửa' : 'mở cửa lại';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận $action'),
        content: Text('Bạn có chắc muốn $action chi nhánh "${branch.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: branch.isActive
                  ? AppColors.error
                  : AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(branch.isActive ? 'Đóng cửa' : 'Mở cửa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.updateBranch(branch.id, {
          'isActive': !branch.isActive,
        });
        _loadBranches();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Đã $action chi nhánh')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }
}
