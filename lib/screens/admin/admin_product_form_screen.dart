import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../services/admin_service.dart';
import '../../services/supabase_service.dart';

/// Màn hình thêm/sửa sản phẩm
class AdminProductFormScreen extends StatefulWidget {
  final Product? product;

  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool get _isEditing => widget.product != null;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _depositController;
  late TextEditingController _brandController;
  late TextEditingController _tagsController;

  String _selectedCategory = 'ao_dai';
  List<String> _selectedSizes = [];
  List<String> _selectedColors = [];
  bool _isActive = true;

  // Images
  String? _thumbnailUrl;
  List<String> _imageUrls = [];
  File? _newThumbnail;
  List<File> _newImages = [];

  final List<String> _availableSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final List<String> _availableColors = [
    'Đỏ', 'Xanh', 'Vàng', 'Trắng', 'Đen', 'Hồng', 'Tím', 'Cam', 'Nâu', 'Xám'
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(
      text: p?.rentalPricePerDay.toStringAsFixed(0) ?? '',
    );
    _depositController = TextEditingController(
      text: p?.depositAmount.toStringAsFixed(0) ?? '',
    );
    _brandController = TextEditingController(text: p?.brand ?? '');
    _tagsController = TextEditingController(text: p?.tags.join(', ') ?? '');

    if (p != null) {
      _selectedCategory = p.category;
      _selectedSizes = List.from(p.sizes);
      _selectedColors = List.from(p.colors);
      _isActive = p.isActive;
      _thumbnailUrl = p.thumbnailUrl;
      _imageUrls = List.from(p.imageUrls);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _brandController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(_isActive ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() => _isActive = !_isActive);
              },
              tooltip: _isActive ? 'Đang hiển thị' : 'Đang ẩn',
            ),
        ],
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
                    // Thumbnail
                    _buildSectionTitle('Ảnh đại diện *'),
                    const SizedBox(height: 8),
                    _buildThumbnailPicker(),

                    const SizedBox(height: 24),

                    // Gallery
                    _buildSectionTitle('Ảnh chi tiết'),
                    const SizedBox(height: 8),
                    _buildGalleryPicker(),

                    const SizedBox(height: 24),

                    // Basic info
                    _buildSectionTitle('Thông tin cơ bản'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Tên sản phẩm *'),
                      validator: (v) =>
                          v?.isEmpty == true ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _inputDecoration('Mô tả'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _inputDecoration('Danh mục *'),
                      items: AppConstants.categories.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _brandController,
                      decoration: _inputDecoration('Thương hiệu'),
                    ),

                    const SizedBox(height: 24),

                    // Pricing
                    _buildSectionTitle('Giá'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: _inputDecoration('Giá thuê/ngày (₫) *'),
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
                            controller: _depositController,
                            decoration: _inputDecoration('Tiền cọc (₫) *'),
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

                    const SizedBox(height: 24),

                    // Sizes
                    _buildSectionTitle('Kích cỡ'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableSizes.map((size) {
                        final selected = _selectedSizes.contains(size);
                        return FilterChip(
                          label: Text(
                            size,
                            style: TextStyle(
                              color: selected ? Colors.white : AppColors.textPrimary,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          selected: selected,
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          backgroundColor: AppColors.surfaceVariant,
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _selectedSizes.add(size);
                              } else {
                                _selectedSizes.remove(size);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Colors
                    _buildSectionTitle('Màu sắc'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableColors.map((color) {
                        final selected = _selectedColors.contains(color);
                        return FilterChip(
                          label: Text(
                            color,
                            style: TextStyle(
                              color: selected ? Colors.white : AppColors.textPrimary,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          selected: selected,
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          backgroundColor: AppColors.surfaceVariant,
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _selectedColors.add(color);
                              } else {
                                _selectedColors.remove(color);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Tags
                    _buildSectionTitle('Tags (phân cách bằng dấu phẩy)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tagsController,
                      decoration: _inputDecoration('VD: áo dài, cưới, đỏ'),
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isEditing ? 'Cập nhật' : 'Thêm sản phẩm',
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

  Widget _buildThumbnailPicker() {
    return GestureDetector(
      onTap: _pickThumbnail,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: _newThumbnail != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_newThumbnail!, fit: BoxFit.cover),
              )
            : _thumbnailUrl != null && _thumbnailUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_thumbnailUrl!, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 40, color: AppColors.textHint),
                      SizedBox(height: 8),
                      Text('Chọn ảnh',
                          style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildGalleryPicker() {
    final allImages = [
      ..._imageUrls.map((url) => {'type': 'url', 'data': url}),
      ..._newImages.map((file) => {'type': 'file', 'data': file}),
    ];

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add button
          GestureDetector(
            onTap: _pickGalleryImage,
            child: Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 30, color: AppColors.textHint),
                  Text('Thêm ảnh',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                ],
              ),
            ),
          ),
          // Existing images
          ...allImages.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isUrl = item['type'] == 'url';

            return Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isUrl
                        ? Image.network(
                            item['data'] as String,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            item['data'] as File,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeGalleryImage(index, isUrl),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _pickThumbnail() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _newThumbnail = File(image.path));
    }
  }

  Future<void> _pickGalleryImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _newImages.add(File(image.path)));
    }
  }

  void _removeGalleryImage(int index, bool isUrl) {
    setState(() {
      if (isUrl) {
        _imageUrls.removeAt(index);
      } else {
        _newImages.removeAt(index - _imageUrls.length);
      }
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate thumbnail
    if (_thumbnailUrl == null && _newThumbnail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh đại diện')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String thumbnailUrl = _thumbnailUrl ?? '';
      List<String> imageUrls = List.from(_imageUrls);

      // Upload new thumbnail
      if (_newThumbnail != null) {
        final productId = widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        final uploadedUrl = await _supabaseService.uploadProductImage(
          productId: productId,
          imageFile: _newThumbnail!,
        );
        if (uploadedUrl != null) {
          thumbnailUrl = uploadedUrl;
        }
      }

      // Upload new gallery images
      for (final file in _newImages) {
        final productId = widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        final url = await _supabaseService.uploadProductImage(
          productId: productId,
          imageFile: file,
        );
        if (url != null) {
          imageUrls.add(url);
        }
      }

      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final now = DateTime.now();

      if (_isEditing) {
        // Update existing product
        await _adminService.updateProduct(widget.product!.id, {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory,
          'brand': _brandController.text.trim(),
          'rentalPricePerDay': double.parse(_priceController.text),
          'depositAmount': double.parse(_depositController.text),
          'thumbnailUrl': thumbnailUrl,
          'imageUrls': imageUrls,
          'sizes': _selectedSizes,
          'colors': _selectedColors,
          'tags': tags,
          'isActive': _isActive,
        });
      } else {
        // Create new product
        final product = Product(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          brand: _brandController.text.trim(),
          rentalPricePerDay: double.parse(_priceController.text),
          depositAmount: double.parse(_depositController.text),
          thumbnailUrl: thumbnailUrl,
          imageUrls: imageUrls,
          sizes: _selectedSizes,
          colors: _selectedColors,
          tags: tags,
          isActive: _isActive,
          createdAt: now,
          updatedAt: now,
        );
        await _adminService.createProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Đã cập nhật sản phẩm' : 'Đã thêm sản phẩm'),
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
