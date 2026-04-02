import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho chi nhánh cửa hàng (có GPS)
class BranchModel {
  final String id;
  final String name;
  final String address;
  final GeoPoint location; // Tọa độ GPS
  final String geohash; // Geohash cho query vị trí
  final String phone;
  final String? email;
  final String? imageUrl;
  final Map<String, DayHours> openingHours;
  final bool isActive;
  final DateTime createdAt;

  BranchModel({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.geohash,
    required this.phone,
    this.email,
    this.imageUrl,
    required this.openingHours,
    this.isActive = true,
    required this.createdAt,
  });

  /// Tọa độ latitude
  double get latitude => location.latitude;

  /// Tọa độ longitude
  double get longitude => location.longitude;

  factory BranchModel.fromFirestore(Map<String, dynamic> data, String id) {
    // Parse openingHours map
    final hoursMap = <String, DayHours>{};
    if (data['openingHours'] != null) {
      (data['openingHours'] as Map<String, dynamic>).forEach((day, value) {
        hoursMap[day] = DayHours.fromMap(value as Map<String, dynamic>);
      });
    }

    return BranchModel(
      id: id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      geohash: data['geohash'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      imageUrl: data['imageUrl'],
      openingHours: hoursMap,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final hoursMap = <String, dynamic>{};
    openingHours.forEach((day, hours) {
      hoursMap[day] = hours.toMap();
    });

    return {
      'name': name,
      'address': address,
      'location': location,
      'geohash': geohash,
      'phone': phone,
      'email': email,
      'imageUrl': imageUrl,
      'openingHours': hoursMap,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class DayHours {
  final String open;
  final String close;
  final bool isOpen;

  DayHours({required this.open, required this.close, this.isOpen = true});

  factory DayHours.fromMap(Map<String, dynamic> data) {
    return DayHours(
      open: data['open'] ?? '08:00',
      close: data['close'] ?? '21:00',
      isOpen: data['isOpen'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {'open': open, 'close': close, 'isOpen': isOpen};
  }
}

/// Model tồn kho của 1 sản phẩm tại 1 chi nhánh
class BranchInventory {
  final String productId;
  final int totalStock;
  final int availableStock;
  final DateTime updatedAt;

  BranchInventory({
    required this.productId,
    required this.totalStock,
    required this.availableStock,
    required this.updatedAt,
  });

  bool get isAvailable => availableStock > 0;

  factory BranchInventory.fromFirestore(Map<String, dynamic> data, String id) {
    return BranchInventory(
      productId: id,
      totalStock: (data['totalStock'] ?? 0).toInt(),
      availableStock: (data['availableStock'] ?? 0).toInt(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'totalStock': totalStock,
      'availableStock': availableStock,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
