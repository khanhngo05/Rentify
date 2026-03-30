import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Script seed dữ liệu mẫu lên Firestore
/// Gọi SeedData.seedAll() trong main.dart 1 LẦN rồi xóa lời gọi
class SeedData {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Seed toàn bộ dữ liệu (xóa cũ trước)
  static Future<void> seedAll() async {
    debugPrint('🌱 Bắt đầu seed dữ liệu...');

    await _clearAll();
    debugPrint('🗑️ Đã xóa dữ liệu cũ');

    await _seedBranches();
    debugPrint('✅ Seed chi nhánh xong');

    await _seedProducts();
    debugPrint('✅ Seed sản phẩm xong');

    await _seedInventory();
    debugPrint('✅ Seed tồn kho xong');

    await _seedAdminUser();
    debugPrint('✅ Seed admin user xong');

    debugPrint('🎉 SEED HOÀN TẤT!');
  }

  /// Xóa toàn bộ dữ liệu cũ
  static Future<void> _clearAll() async {
    // Xóa inventory subcollection trong mỗi branch
    for (final branchId in ['branch_001', 'branch_002', 'branch_003']) {
      final invDocs = await _db
          .collection(AppConstants.branchesCollection)
          .doc(branchId)
          .collection(AppConstants.inventorySubcollection)
          .get();
      for (final doc in invDocs.docs) {
        await doc.reference.delete();
      }
    }

    // Xóa branches
    final branches = await _db.collection(AppConstants.branchesCollection).get();
    for (final doc in branches.docs) {
      await doc.reference.delete();
    }

    // Xóa products
    final products = await _db.collection(AppConstants.productsCollection).get();
    for (final doc in products.docs) {
      await doc.reference.delete();
    }

    // Xóa users
    final users = await _db.collection(AppConstants.usersCollection).get();
    for (final doc in users.docs) {
      await doc.reference.delete();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  CHI NHÁNH (3 chi nhánh tại Hà Nội — địa chỉ từ sample_data.json)
  // ═══════════════════════════════════════════════════════════════
  static Future<void> _seedBranches() async {
    final branches = [
      {
        'name': 'Chi nhánh Đống Đa',
        'address': '158 Đường Lê Duẩn, Khâm Thiên, Văn Miếu - Quốc Tử Giám, Hà Nội',
        'location': const GeoPoint(21.017638376815693, 105.84131255350822),
        'geohash': 'w3gv2e',
        'phone': '024.3825.1234',
        'email': 'dongda@rentify.vn',
        'imageUrl': '',
        'openingHours': {
          'monday': {'open': '08:00', 'close': '21:00', 'isOpen': true},
          'tuesday': {'open': '08:00', 'close': '21:00', 'isOpen': true},
          'wednesday': {'open': '08:00', 'close': '21:00', 'isOpen': true},
          'thursday': {'open': '08:00', 'close': '21:00', 'isOpen': true},
          'friday': {'open': '08:00', 'close': '22:00', 'isOpen': true},
          'saturday': {'open': '09:00', 'close': '22:00', 'isOpen': true},
          'sunday': {'open': '09:00', 'close': '20:00', 'isOpen': true},
        },
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'name': 'Chi nhánh Cầu Giấy',
        'address': 'Số 5 Ng. 181 Đ. Xuân Thủy, Dịch Vọng Hậu, Cầu Giấy, Hà Nội, Việt Nam',
        'location': const GeoPoint(21.036533456308057, 105.78358846695033),
        'geohash': 'w3gsmq',
        'phone': '024.3756.5678',
        'email': 'caugiay@rentify.vn',
        'imageUrl': '',
        'openingHours': {
          'monday': {'open': '08:30', 'close': '21:00', 'isOpen': true},
          'tuesday': {'open': '08:30', 'close': '21:00', 'isOpen': true},
          'wednesday': {'open': '08:30', 'close': '21:00', 'isOpen': true},
          'thursday': {'open': '08:30', 'close': '21:00', 'isOpen': true},
          'friday': {'open': '08:30', 'close': '22:00', 'isOpen': true},
          'saturday': {'open': '09:00', 'close': '22:00', 'isOpen': true},
          'sunday': {'open': '10:00', 'close': '20:00', 'isOpen': true},
        },
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'name': 'Chi nhánh Thanh Xuân',
        'address': '382 Nguyễn Trãi, Thanh Xuân Trung, Thanh Xuân, Hà Nội',
        'location': const GeoPoint(20.993984749269153, 105.80605545161112),
        'geohash': 'w3gufe',
        'phone': '024.3512.9900',
        'email': 'thanhxuan@rentify.vn',
        'imageUrl': '',
        'openingHours': {
          'monday': {'open': '09:00', 'close': '21:00', 'isOpen': true},
          'tuesday': {'open': '09:00', 'close': '21:00', 'isOpen': true},
          'wednesday': {'open': '09:00', 'close': '21:00', 'isOpen': true},
          'thursday': {'open': '09:00', 'close': '21:00', 'isOpen': true},
          'friday': {'open': '09:00', 'close': '21:30', 'isOpen': true},
          'saturday': {'open': '09:00', 'close': '22:00', 'isOpen': true},
          'sunday': {'open': '09:00', 'close': '21:00', 'isOpen': true},
        },
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
    ];

    for (int i = 0; i < branches.length; i++) {
      await _db
          .collection(AppConstants.branchesCollection)
          .doc('branch_00${i + 1}')
          .set(branches[i]);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  SẢN PHẨM (30 sản phẩm)
  // ═══════════════════════════════════════════════════════════════
  static Future<void> _seedProducts() async {
    final products = [
      // ── Áo dài (1-4) ──
      {
        'name': 'Áo Dài Gấm Đỏ Thêu Phượng',
        'description': 'Áo dài gấm đỏ truyền thống, thêu hoa phượng tinh xảo. Phù hợp lễ hội, Tết Nguyên Đán, đám hỏi và các sự kiện trọng đại.',
        'rentalPricePerDay': 250000,
        'depositAmount': 1000000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'ao_dai',
        'sizes': ['S', 'M', 'L'],
        'colors': ['Đỏ', 'Vàng gold'],
        'brand': 'NTK Minh Hạnh',
        'rating': 4.8,
        'reviewCount': 56,
        'isActive': true,
        'tags': ['áo dài', 'lễ hội', 'tết', 'truyền thống'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Áo Dài Lụa Tơ Tằm Xanh Ngọc',
        'description': 'Áo dài lụa tơ tằm cao cấp màu xanh ngọc, kiểu dáng hiện đại. Phù hợp sự kiện, tiệc cưới.',
        'rentalPricePerDay': 300000,
        'depositAmount': 1200000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'ao_dai',
        'sizes': ['XS', 'S', 'M', 'L'],
        'colors': ['Xanh ngọc', 'Hồng phấn'],
        'brand': 'NTK Thủy Nguyễn',
        'rating': 4.9,
        'reviewCount': 32,
        'isActive': true,
        'tags': ['áo dài', 'lụa', 'hiện đại', 'tiệc cưới'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Áo Dài Cách Tân Hoa Nhí',
        'description': 'Áo dài cách tân họa tiết hoa nhí, tay lỡ trẻ trung. Phù hợp chụp ảnh kỷ yếu, du lịch.',
        'rentalPricePerDay': 180000,
        'depositAmount': 800000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'ao_dai',
        'sizes': ['S', 'M', 'L'],
        'colors': ['Trắng hoa nhí', 'Vàng hoa nhí'],
        'brand': 'Áo Dài Việt',
        'rating': 4.6,
        'reviewCount': 78,
        'isActive': true,
        'tags': ['áo dài', 'cách tân', 'kỷ yếu', 'du lịch'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Áo Dài Nam Gấm Xanh Than',
        'description': 'Áo dài nam vải gấm xanh than, cổ đứng lịch lãm. Phù hợp đám cưới, lễ hội truyền thống.',
        'rentalPricePerDay': 220000,
        'depositAmount': 900000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'ao_dai',
        'sizes': ['M', 'L', 'XL', 'XXL'],
        'colors': ['Xanh than', 'Đen'],
        'brand': 'NTK Minh Hạnh',
        'rating': 4.5,
        'reviewCount': 38,
        'isActive': true,
        'tags': ['áo dài', 'nam', 'đám cưới', 'gấm'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // ── Váy cưới (5-8) ──
      {
        'name': 'Váy Cưới Bồng Bềnh Princess',
        'description': 'Váy cưới dáng bồng công chúa, chất vải organza cao cấp. Thiết kế lộng lẫy, phù hợp hôn lễ và chụp ảnh cưới.',
        'rentalPricePerDay': 800000,
        'depositAmount': 5000000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'vay_cuoi',
        'sizes': ['XS', 'S', 'M', 'L'],
        'colors': ['Trắng ngà', 'Trắng tinh'],
        'brand': 'Vera Wedding',
        'rating': 4.9,
        'reviewCount': 34,
        'isActive': true,
        'tags': ['váy cưới', 'hôn lễ', 'chụp ảnh cưới'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Váy Cưới Đuôi Cá Ren Pháp',
        'description': 'Váy cưới đuôi cá ôm body, ren Pháp sang trọng. Tôn dáng tối đa cho cô dâu.',
        'rentalPricePerDay': 1000000,
        'depositAmount': 6000000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'vay_cuoi',
        'sizes': ['XS', 'S', 'M'],
        'colors': ['Trắng', 'Champagne'],
        'brand': 'Bridal Luxe',
        'rating': 5.0,
        'reviewCount': 18,
        'isActive': true,
        'tags': ['váy cưới', 'đuôi cá', 'ren pháp', 'sang trọng'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Váy Cưới Chữ A Tối Giản',
        'description': 'Váy cưới dáng chữ A tối giản, vải satin trơn cao cấp. Phong cách minimalist hiện đại.',
        'rentalPricePerDay': 650000,
        'depositAmount': 3500000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'vay_cuoi',
        'sizes': ['XS', 'S', 'M', 'L'],
        'colors': ['Trắng', 'Nude'],
        'brand': 'Vera Wedding',
        'rating': 4.7,
        'reviewCount': 22,
        'isActive': true,
        'tags': ['váy cưới', 'minimalist', 'chữ A', 'satin'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Váy Cưới Lệch Vai Bohemian',
        'description': 'Váy cưới lệch vai phong cách bohemian, ren hoa vintage. Chụp ảnh ngoại cảnh, tiệc cưới ngoài trời.',
        'rentalPricePerDay': 750000,
        'depositAmount': 4000000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'vay_cuoi',
        'sizes': ['S', 'M', 'L'],
        'colors': ['Trắng kem', 'Champagne'],
        'brand': 'Bridal Luxe',
        'rating': 4.8,
        'reviewCount': 26,
        'isActive': true,
        'tags': ['váy cưới', 'bohemian', 'ngoài trời', 'lệch vai'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // ── Đầm dạ hội (9-12) ──
      {
        'name': 'Đầm Dạ Hội Sequin Vàng',
        'description': 'Đầm dạ hội đính sequin vàng lấp lánh, dáng ôm tôn dáng. Lý tưởng cho tiệc tùng và gala dinner.',
        'rentalPricePerDay': 450000,
        'depositAmount': 2000000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'dam_da_hoi',
        'sizes': ['XS', 'S', 'M', 'L'],
        'colors': ['Vàng', 'Bạc', 'Đỏ merlot'],
        'brand': 'EleganceVN',
        'rating': 4.7,
        'reviewCount': 89,
        'isActive': true,
        'tags': ['đầm dạ hội', 'tiệc', 'gala', 'sequin'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Đầm Dạ Hội Xẻ Đùi Navy',
        'description': 'Đầm dạ hội xẻ đùi quyến rũ, chất liệu satin mềm mại. Tone navy thanh lịch.',
        'rentalPricePerDay': 500000,
        'depositAmount': 2500000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'dam_da_hoi',
        'sizes': ['S', 'M', 'L'],
        'colors': ['Navy', 'Đen', 'Đỏ rượu'],
        'brand': 'NightGlow',
        'rating': 4.8,
        'reviewCount': 45,
        'isActive': true,
        'tags': ['đầm dạ hội', 'xẻ đùi', 'satin', 'quyến rũ'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Đầm Cocktail Hồng Pastel',
        'description': 'Đầm cocktail dáng xòe ngắn, tone hồng pastel nhẹ nhàng. Phù hợp tiệc sinh nhật, party.',
        'rentalPricePerDay': 280000,
        'depositAmount': 1200000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'dam_da_hoi',
        'sizes': ['XS', 'S', 'M', 'L'],
        'colors': ['Hồng pastel', 'Xanh baby', 'Tím lavender'],
        'brand': 'SweetDress',
        'rating': 4.5,
        'reviewCount': 67,
        'isActive': true,
        'tags': ['cocktail', 'party', 'sinh nhật', 'pastel'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Đầm Maxi Đỏ Rượu Vang',
        'description': 'Đầm maxi dáng dài chất liệu chiffon, tone đỏ rượu vang quyến rũ. Phù hợp dạ tiệc, tiệc tối.',
        'rentalPricePerDay': 380000,
        'depositAmount': 1800000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'dam_da_hoi',
        'sizes': ['S', 'M', 'L'],
        'colors': ['Đỏ rượu vang', 'Xanh emerald'],
        'brand': 'EleganceVN',
        'rating': 4.6,
        'reviewCount': 53,
        'isActive': true,
        'tags': ['đầm maxi', 'chiffon', 'dạ tiệc', 'rượu vang'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // ── Vest / Suit (13-16) ──
      {
        'name': 'Vest Nam Đen Classic',
        'description': 'Vest nam đen cổ điển 2 mảnh, vải tweed cao cấp không nhăn. Phù hợp đám cưới và sự kiện formal.',
        'rentalPricePerDay': 300000,
        'depositAmount': 1500000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'vest_suit',
        'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
        'colors': ['Đen', 'Navy', 'Xám than'],
        'brand': 'GentleMan VN',
        'rating': 4.6,
        'reviewCount': 42,
        'isActive': true,
        'tags': ['vest', 'suit', 'nam', 'đám cưới'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Suit Xám Slim Fit 3 Mảnh',
        'description': 'Suit xám 3 mảnh (áo vest + gile + quần), dáng slim fit hiện đại. Cà vạt đi kèm.',
        'rentalPricePerDay': 400000,
        'depositAmount': 2000000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'vest_suit',
        'sizes': ['S', 'M', 'L', 'XL'],
        'colors': ['Xám nhạt', 'Xám đậm', 'Be'],
        'brand': 'Modern Man',
        'rating': 4.7,
        'reviewCount': 28,
        'isActive': true,
        'tags': ['suit', '3 mảnh', 'slim fit', 'cà vạt'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Tuxedo Đen Dạ Tiệc',
        'description': 'Tuxedo đen sang trọng, cổ satin bóng. Dành cho dạ tiệc, gala, sự kiện VIP.',
        'rentalPricePerDay': 600000,
        'depositAmount': 3000000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'vest_suit',
        'sizes': ['M', 'L', 'XL'],
        'colors': ['Đen'],
        'brand': 'GentleMan VN',
        'rating': 4.9,
        'reviewCount': 15,
        'isActive': true,
        'tags': ['tuxedo', 'dạ tiệc', 'gala', 'VIP'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Vest Nữ Trắng Power Suit',
        'description': 'Vest nữ trắng cá tính dáng oversized, phong cách power suit. Phù hợp sự kiện, chụp ảnh thời trang.',
        'rentalPricePerDay': 350000,
        'depositAmount': 1500000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'vest_suit',
        'sizes': ['XS', 'S', 'M', 'L'],
        'colors': ['Trắng', 'Đen', 'Be'],
        'brand': 'Modern Woman',
        'rating': 4.6,
        'reviewCount': 37,
        'isActive': true,
        'tags': ['vest nữ', 'power suit', 'thời trang', 'sự kiện'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // ── Hanbok (17-19) ──
      {
        'name': 'Hanbok Nữ Hồng Pastel',
        'description': 'Hanbok nữ truyền thống Hàn Quốc màu hồng pastel. Phù hợp chụp ảnh du lịch và lễ hội văn hóa.',
        'rentalPricePerDay': 350000,
        'depositAmount': 1200000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'hanbok',
        'sizes': ['S', 'M', 'L'],
        'colors': ['Hồng pastel', 'Xanh ngọc', 'Tím lavender'],
        'brand': 'Korea Style',
        'rating': 4.9,
        'reviewCount': 112,
        'isActive': true,
        'tags': ['hanbok', 'hàn quốc', 'chụp ảnh', 'du lịch'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Hanbok Nam Xanh Truyền Thống',
        'description': 'Hanbok nam truyền thống, tone xanh dương đậm. Phù hợp đi cặp với Hanbok nữ.',
        'rentalPricePerDay': 300000,
        'depositAmount': 1000000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'hanbok',
        'sizes': ['M', 'L', 'XL'],
        'colors': ['Xanh dương', 'Xám xanh'],
        'brand': 'Korea Style',
        'rating': 4.7,
        'reviewCount': 58,
        'isActive': true,
        'tags': ['hanbok', 'nam', 'truyền thống', 'cặp đôi'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Hanbok Trẻ Em Cặp Đôi',
        'description': 'Set Hanbok trẻ em cho bé trai và bé gái, màu sắc tươi sáng. Phù hợp chụp ảnh gia đình, lễ hội.',
        'rentalPricePerDay': 200000,
        'depositAmount': 600000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'hanbok',
        'sizes': ['3-5 tuổi', '5-7 tuổi', '7-10 tuổi'],
        'colors': ['Hồng + Xanh', 'Vàng + Tím'],
        'brand': 'Korea Style',
        'rating': 4.8,
        'reviewCount': 65,
        'isActive': true,
        'tags': ['hanbok', 'trẻ em', 'gia đình', 'cute'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // ── Trang phục chụp ảnh (20-22) ──
      {
        'name': 'Đầm Vintage Hoa Retro',
        'description': 'Đầm vintage họa tiết hoa retro thập niên 60. Phù hợp chụp ảnh concept, kỷ yếu.',
        'rentalPricePerDay': 200000,
        'depositAmount': 800000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'trang_phuc_chup_anh',
        'sizes': ['S', 'M', 'L'],
        'colors': ['Đỏ hoa', 'Vàng hoa', 'Xanh hoa'],
        'brand': 'RetroVibe',
        'rating': 4.4,
        'reviewCount': 95,
        'isActive': true,
        'tags': ['vintage', 'retro', 'chụp ảnh', 'kỷ yếu'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Set Học Sinh Nhật Bản',
        'description': 'Set đồng phục học sinh Nhật Bản (áo sailor + váy xếp ly). Chụp ảnh anime, cosplay.',
        'rentalPricePerDay': 150000,
        'depositAmount': 600000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'trang_phuc_chup_anh',
        'sizes': ['S', 'M', 'L'],
        'colors': ['Navy + trắng', 'Đen + trắng'],
        'brand': 'CosplayVN',
        'rating': 4.6,
        'reviewCount': 130,
        'isActive': true,
        'tags': ['nhật bản', 'sailor', 'cosplay', 'anime'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Bộ Yếm Đào + Áo Mớ Ba',
        'description': 'Bộ yếm đào truyền thống kết hợp áo mớ ba. Phù hợp chụp ảnh sen, concept Việt cổ.',
        'rentalPricePerDay': 180000,
        'depositAmount': 700000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'trang_phuc_chup_anh',
        'sizes': ['S', 'M', 'L'],
        'colors': ['Đào hồng', 'Vàng kem'],
        'brand': 'Việt Phục',
        'rating': 4.7,
        'reviewCount': 88,
        'isActive': true,
        'tags': ['yếm đào', 'việt cổ', 'chụp ảnh sen', 'truyền thống'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // ── Trang phục dân tộc (23-25) ──
      {
        'name': 'Áo Bà Ba Trắng Truyền Thống',
        'description': 'Áo bà ba trắng Nam Bộ, chất liệu lụa mềm. Phù hợp lễ hội văn hóa, chụp ảnh.',
        'rentalPricePerDay': 120000,
        'depositAmount': 500000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'trang_phuc_dan_toc',
        'sizes': ['S', 'M', 'L', 'XL'],
        'colors': ['Trắng', 'Đen', 'Xanh nhạt'],
        'brand': 'Việt Phục',
        'rating': 4.3,
        'reviewCount': 47,
        'isActive': true,
        'tags': ['bà ba', 'nam bộ', 'truyền thống', 'lễ hội'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Trang Phục H\'Mông Nữ',
        'description': 'Trang phục truyền thống dân tộc H\'Mông, thêu tay sặc sỡ. Chụp ảnh Sapa, Hà Giang.',
        'rentalPricePerDay': 250000,
        'depositAmount': 1000000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'trang_phuc_dan_toc',
        'sizes': ['S', 'M', 'L'],
        'colors': ['Đỏ thêu', 'Xanh thêu'],
        'brand': 'Ethnic Style',
        'rating': 4.8,
        'reviewCount': 73,
        'isActive': true,
        'tags': ['h\'mông', 'dân tộc', 'sapa', 'hà giang'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Áo Tứ Thân Truyền Thống',
        'description': 'Áo tứ thân Bắc Bộ kết hợp khăn mỏ quạ và nón quai thao. Chụp ảnh quan họ, hội Lim.',
        'rentalPricePerDay': 200000,
        'depositAmount': 800000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'trang_phuc_dan_toc',
        'sizes': ['S', 'M', 'L'],
        'colors': ['Nâu + vàng', 'Xanh + đỏ'],
        'brand': 'Việt Phục',
        'rating': 4.5,
        'reviewCount': 41,
        'isActive': true,
        'tags': ['tứ thân', 'bắc bộ', 'quan họ', 'hội lim'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // ── Phụ kiện (26-30) ──
      {
        'name': 'Vương Miện Cô Dâu Pha Lê',
        'description': 'Vương miện cô dâu đính pha lê lấp lánh. Đi kèm váy cưới hoặc đầm dạ hội.',
        'rentalPricePerDay': 100000,
        'depositAmount': 500000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'phu_kien',
        'sizes': ['Free size'],
        'colors': ['Bạc', 'Vàng gold'],
        'brand': 'Bridal Luxe',
        'rating': 4.7,
        'reviewCount': 89,
        'isActive': true,
        'tags': ['vương miện', 'cô dâu', 'pha lê', 'phụ kiện'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Bộ Trang Sức Ngọc Trai',
        'description': 'Set vòng cổ + khuyên tai ngọc trai nhân tạo cao cấp. Phù hợp mọi trang phục lễ hội.',
        'rentalPricePerDay': 80000,
        'depositAmount': 400000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'phu_kien',
        'sizes': ['Free size'],
        'colors': ['Trắng ngọc trai', 'Hồng ngọc trai'],
        'brand': 'Pearl Shine',
        'rating': 4.5,
        'reviewCount': 55,
        'isActive': true,
        'tags': ['trang sức', 'ngọc trai', 'vòng cổ', 'khuyên tai'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Giày Cao Gót Đỏ Satin',
        'description': 'Giày cao gót 7cm chất liệu satin đỏ. Phối cùng áo dài, đầm dạ hội.',
        'rentalPricePerDay': 120000,
        'depositAmount': 600000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'phu_kien',
        'sizes': ['36', '37', '38', '39', '40'],
        'colors': ['Đỏ', 'Đen', 'Nude'],
        'brand': 'StepGlam',
        'rating': 4.4,
        'reviewCount': 42,
        'isActive': true,
        'tags': ['giày', 'cao gót', 'satin', 'phụ kiện'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Khăn Voan Lụa Cưới',
        'description': 'Khăn voan lụa dài 3m, viền ren tinh tế. Phụ kiện không thể thiếu cho cô dâu.',
        'rentalPricePerDay': 80000,
        'depositAmount': 300000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'phu_kien',
        'sizes': ['Free size'],
        'colors': ['Trắng', 'Champagne'],
        'brand': 'Bridal Luxe',
        'rating': 4.6,
        'reviewCount': 64,
        'isActive': true,
        'tags': ['khăn voan', 'cô dâu', 'lụa', 'phụ kiện cưới'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Clutch Dạ Hội Đính Đá',
        'description': 'Ví cầm tay (clutch) dạ hội đính đá pha lê. Phối cùng đầm dạ hội, váy cưới.',
        'rentalPricePerDay': 70000,
        'depositAmount': 350000,
        'thumbnailUrl': '',
        'imageUrls': <String>[],
        'category': 'phu_kien',
        'sizes': ['Free size'],
        'colors': ['Bạc', 'Vàng', 'Đen'],
        'brand': 'NightGlow',
        'rating': 4.3,
        'reviewCount': 38,
        'isActive': true,
        'tags': ['clutch', 'ví cầm tay', 'dạ hội', 'đính đá'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
    ];

    for (int i = 0; i < products.length; i++) {
      final id = 'prod_${(i + 1).toString().padLeft(3, '0')}';
      await _db
          .collection(AppConstants.productsCollection)
          .doc(id)
          .set(products[i]);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  TỒN KHO (phân bổ sản phẩm cho từng chi nhánh)
  // ═══════════════════════════════════════════════════════════════
  static Future<void> _seedInventory() async {
    final inventoryData = {
      'branch_001': {
        'prod_001': {'totalStock': 3, 'availableStock': 2},
        'prod_002': {'totalStock': 2, 'availableStock': 1},
        'prod_003': {'totalStock': 2, 'availableStock': 2},
        'prod_005': {'totalStock': 2, 'availableStock': 2},
        'prod_007': {'totalStock': 1, 'availableStock': 1},
        'prod_009': {'totalStock': 3, 'availableStock': 3},
        'prod_011': {'totalStock': 4, 'availableStock': 4},
        'prod_012': {'totalStock': 2, 'availableStock': 2},
        'prod_013': {'totalStock': 3, 'availableStock': 3},
        'prod_015': {'totalStock': 2, 'availableStock': 2},
        'prod_017': {'totalStock': 2, 'availableStock': 2},
        'prod_019': {'totalStock': 3, 'availableStock': 3},
        'prod_020': {'totalStock': 3, 'availableStock': 3},
        'prod_022': {'totalStock': 2, 'availableStock': 2},
        'prod_023': {'totalStock': 2, 'availableStock': 2},
        'prod_025': {'totalStock': 1, 'availableStock': 1},
        'prod_026': {'totalStock': 5, 'availableStock': 5},
        'prod_027': {'totalStock': 4, 'availableStock': 4},
        'prod_028': {'totalStock': 3, 'availableStock': 3},
        'prod_029': {'totalStock': 3, 'availableStock': 3},
      },
      'branch_002': {
        'prod_001': {'totalStock': 2, 'availableStock': 2},
        'prod_003': {'totalStock': 1, 'availableStock': 1},
        'prod_004': {'totalStock': 3, 'availableStock': 3},
        'prod_006': {'totalStock': 1, 'availableStock': 1},
        'prod_008': {'totalStock': 2, 'availableStock': 2},
        'prod_009': {'totalStock': 2, 'availableStock': 2},
        'prod_010': {'totalStock': 2, 'availableStock': 2},
        'prod_013': {'totalStock': 4, 'availableStock': 4},
        'prod_014': {'totalStock': 2, 'availableStock': 2},
        'prod_016': {'totalStock': 2, 'availableStock': 2},
        'prod_017': {'totalStock': 3, 'availableStock': 3},
        'prod_018': {'totalStock': 2, 'availableStock': 2},
        'prod_021': {'totalStock': 3, 'availableStock': 3},
        'prod_024': {'totalStock': 2, 'availableStock': 2},
        'prod_026': {'totalStock': 3, 'availableStock': 3},
        'prod_028': {'totalStock': 2, 'availableStock': 2},
        'prod_030': {'totalStock': 4, 'availableStock': 4},
      },
      'branch_003': {
        'prod_002': {'totalStock': 1, 'availableStock': 0},
        'prod_004': {'totalStock': 2, 'availableStock': 1},
        'prod_005': {'totalStock': 4, 'availableStock': 3},
        'prod_006': {'totalStock': 2, 'availableStock': 2},
        'prod_007': {'totalStock': 2, 'availableStock': 2},
        'prod_008': {'totalStock': 3, 'availableStock': 3},
        'prod_010': {'totalStock': 3, 'availableStock': 3},
        'prod_011': {'totalStock': 2, 'availableStock': 2},
        'prod_012': {'totalStock': 2, 'availableStock': 2},
        'prod_014': {'totalStock': 3, 'availableStock': 3},
        'prod_015': {'totalStock': 2, 'availableStock': 2},
        'prod_016': {'totalStock': 3, 'availableStock': 3},
        'prod_018': {'totalStock': 2, 'availableStock': 2},
        'prod_019': {'totalStock': 2, 'availableStock': 2},
        'prod_021': {'totalStock': 2, 'availableStock': 2},
        'prod_023': {'totalStock': 3, 'availableStock': 3},
        'prod_024': {'totalStock': 2, 'availableStock': 2},
        'prod_025': {'totalStock': 2, 'availableStock': 2},
        'prod_027': {'totalStock': 3, 'availableStock': 3},
        'prod_029': {'totalStock': 2, 'availableStock': 2},
        'prod_030': {'totalStock': 3, 'availableStock': 3},
      },
    };

    for (final entry in inventoryData.entries) {
      final branchId = entry.key;
      for (final inv in entry.value.entries) {
        final productId = inv.key;
        await _db
            .collection(AppConstants.branchesCollection)
            .doc(branchId)
            .collection(AppConstants.inventorySubcollection)
            .doc(productId)
            .set({
          'productId': productId,
          'totalStock': inv.value['totalStock'],
          'availableStock': inv.value['availableStock'],
          'updatedAt': Timestamp.now(),
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  ADMIN USER
  // ═══════════════════════════════════════════════════════════════
  static Future<void> _seedAdminUser() async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc('admin_rentify')
        .set({
      'email': 'admin@rentify.vn',
      'displayName': 'Admin Rentify',
      'phoneNumber': '0912000000',
      'avatarUrl': '',
      'address': 'Hà Nội',
      'role': 'admin',
      'createdAt': Timestamp.now(),
    });
  }
}
