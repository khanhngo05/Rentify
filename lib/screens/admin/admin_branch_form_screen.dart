import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../models/branch_model.dart';
import '../../services/admin_service.dart';
import '../../services/supabase_service.dart';

/// Màn hình thêm/sửa chi nhánh
class AdminBranchFormScreen extends StatefulWidget {
  final BranchModel? branch;

  const AdminBranchFormScreen({super.key, this.branch});

  @override
  State<AdminBranchFormScreen> createState() => _AdminBranchFormScreenState();
}

class _AdminBranchFormScreenState extends State<AdminBranchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool get _isEditing => widget.branch != null;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _latController;
  late TextEditingController _lonController;

  String? _imageUrl;
  File? _newImage;
  bool _isActive = true;

  // Opening hours for each day
  Map<String, DayHours> _openingHours = {};
  final List<String> _weekDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];
  final Map<String, String> _dayNames = {
    'monday': 'Thứ 2',
    'tuesday': 'Thứ 3',
    'wednesday': 'Thứ 4',
    'thursday': 'Thứ 5',
    'friday': 'Thứ 6',
    'saturday': 'Thứ 7',
    'sunday': 'Chủ nhật',
  };

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initOpeningHours();
  }

  void _initControllers() {
    final b = widget.branch;
    _nameController = TextEditingController(text: b?.name ?? '');
    _addressController = TextEditingController(text: b?.address ?? '');
    _phoneController = TextEditingController(text: b?.phone ?? '');
    _emailController = TextEditingController(text: b?.email ?? '');
    _latController = TextEditingController(
      text: b?.latitude.toString() ?? '10.7769',
    );
    _lonController = TextEditingController(
      text: b?.longitude.toString() ?? '106.7009',
    );

    if (b != null) {
      _imageUrl = b.imageUrl;
      _isActive = b.isActive;
    }
  }

  void _initOpeningHours() {
    final b = widget.branch;
    for (final day in _weekDays) {
      if (b != null && b.openingHours.containsKey(day)) {
        _openingHours[day] = b.openingHours[day]!;
      } else {
        _openingHours[day] = DayHours(
          open: '08:00',
          close: '21:00',
          isOpen: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa chi nhánh' : 'Thêm chi nhánh'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    _buildSectionTitle('Ảnh chi nhánh'),
                    const SizedBox(height: 8),
                    _buildImagePicker(),

                    const SizedBox(height: 24),

                    // Basic info
                    _buildSectionTitle('Thông tin cơ bản'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Tên chi nhánh *'),
                      validator: (v) =>
                          v?.isEmpty == true ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: _inputDecoration('Địa chỉ *'),
                      maxLines: 2,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Vui lòng nhập địa chỉ' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: _inputDecoration('Số điện thoại *'),
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                v?.isEmpty == true ? 'Bắt buộc' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration('Email'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Location
                    _buildSectionTitle('Vị trí GPS'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            decoration: _inputDecoration('Latitude'),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v?.isEmpty == true) return 'Bắt buộc';
                              if (double.tryParse(v!) == null) {
                                return 'Số không hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lonController,
                            decoration: _inputDecoration('Longitude'),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v?.isEmpty == true) return 'Bắt buộc';
                              if (double.tryParse(v!) == null) {
                                return 'Số không hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tip: Lấy tọa độ từ Google Maps',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Opening hours
                    _buildSectionTitle('Giờ mở cửa'),
                    const SizedBox(height: 12),
                    ..._weekDays.map((day) => _buildDayHoursRow(day)),

                    const SizedBox(height: 24),

                    // Active status
                    SwitchListTile(
                      title: const Text('Chi nhánh đang hoạt động'),
                      subtitle: Text(
                        _isActive
                            ? 'Chi nhánh sẽ hiển thị cho khách hàng'
                            : 'Chi nhánh sẽ bị ẩn',
                      ),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeColor: AppColors.success,
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveBranch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isEditing ? 'Cập nhật' : 'Thêm chi nhánh',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: _newImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_newImage!, fit: BoxFit.cover),
              )
            : _imageUrl != null && _imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_imageUrl!, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 48, color: AppColors.textHint),
                      SizedBox(height: 8),
                      Text('Chọn ảnh chi nhánh',
                          style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDayHoursRow(String day) {
    final hours = _openingHours[day]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hours.isOpen ? AppColors.surfaceVariant : AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Day name
          SizedBox(
            width: 80,
            child: Text(
              _dayNames[day]!,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: hours.isOpen
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          // Is open switch
          Switch(
            value: hours.isOpen,
            onChanged: (v) {
              setState(() {
                _openingHours[day] = DayHours(
                  open: hours.open,
                  close: hours.close,
                  isOpen: v,
                );
              });
            },
            activeColor: AppColors.success,
          ),
          const SizedBox(width: 8),
          // Time pickers (only if open)
          if (hours.isOpen) ...[
            _buildTimePicker(hours.open, (time) {
              setState(() {
                _openingHours[day] = DayHours(
                  open: time,
                  close: hours.close,
                  isOpen: hours.isOpen,
                );
              });
            }),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('-'),
            ),
            _buildTimePicker(hours.close, (time) {
              setState(() {
                _openingHours[day] = DayHours(
                  open: hours.open,
                  close: time,
                  isOpen: hours.isOpen,
                );
              });
            }),
          ] else
            const Text(
              'Nghỉ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String currentTime, Function(String) onChanged) {
    return GestureDetector(
      onTap: () async {
        final parts = currentTime.split(':');
        final initialTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );

        final picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );

        if (picked != null) {
          final formatted =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onChanged(formatted);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          currentTime,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _newImage = File(image.path));
    }
  }

  String _generateGeohash(double lat, double lon) {
    // Simplified geohash - in production, use geoflutterfire_plus
    return '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';
  }

  Future<void> _saveBranch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imageUrl = _imageUrl ?? '';

      // Upload new image
      if (_newImage != null) {
        final branchId = widget.branch?.id ??
            DateTime.now().millisecondsSinceEpoch.toString();
        final uploadedUrl = await _supabaseService.uploadBranchImage(
          branchId: branchId,
          imageFile: _newImage!,
        );
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      final lat = double.parse(_latController.text);
      final lon = double.parse(_lonController.text);

      // Convert opening hours to map
      final hoursMap = <String, dynamic>{};
      _openingHours.forEach((day, hours) {
        hoursMap[day] = hours.toMap();
      });

      if (_isEditing) {
        // Update
        await _adminService.updateBranch(widget.branch!.id, {
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'location': GeoPoint(lat, lon),
          'geohash': _generateGeohash(lat, lon),
          'imageUrl': imageUrl,
          'openingHours': hoursMap,
          'isActive': _isActive,
        });
      } else {
        // Create
        final branch = BranchModel(
          id: '',
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          location: GeoPoint(lat, lon),
          geohash: _generateGeohash(lat, lon),
          imageUrl: imageUrl,
          openingHours: _openingHours,
          isActive: _isActive,
          createdAt: DateTime.now(),
        );
        await _adminService.createBranch(branch);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditing ? 'Đã cập nhật chi nhánh' : 'Đã thêm chi nhánh'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}
