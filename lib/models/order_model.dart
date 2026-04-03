import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho 1 mục trong đơn thuê
class OrderItem {
  final String productId;
  final String productName;
  final String thumbnailUrl;
  final String selectedSize;
  final String selectedColor;
  final double rentalPricePerDay;
  final double depositAmount;
  final int quantity;
  final double subtotal;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.thumbnailUrl,
    required this.selectedSize,
    required this.selectedColor,
    required this.rentalPricePerDay,
    required this.depositAmount,
    this.quantity = 1,
    required this.subtotal,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    final rentalPrice = _asDouble(data['rentalPricePerDay'] ?? data['pricePerDay']);
    final deposit = _asDouble(data['depositAmount'] ?? data['depositPrice']);
    final quantity = _asInt(data['quantity'] ?? 1);
    final rawSubtotal = _asDouble(data['subtotal']);

    return OrderItem(
      productId: data['productId'] ?? '',
      productName: (data['productName'] ?? data['name'] ?? '').toString(),
      thumbnailUrl: (data['thumbnailUrl'] ?? data['imageUrl'] ?? '').toString(),
      selectedSize: (data['selectedSize'] ?? data['size'] ?? '').toString(),
      selectedColor: (data['selectedColor'] ?? data['color'] ?? '').toString(),
      rentalPricePerDay: rentalPrice,
      depositAmount: deposit,
      quantity: quantity,
      subtotal: rawSubtotal > 0 ? rawSubtotal : rentalPrice * quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'thumbnailUrl': thumbnailUrl,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'rentalPricePerDay': rentalPricePerDay,
      'depositAmount': depositAmount,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}

/// Model đại diện cho đơn thuê
class OrderModel {
  final String id;
  final String userId;
  final String branchId;
  final String branchName;
  final String branchAddress;
  final List<OrderItem> items;
  final DateTime rentalStartDate;
  final DateTime rentalEndDate;
  final int rentalDays;
  final double totalRentalFee;
  final double depositPaid;
  final String status;
  final String deliveryAddress;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.branchId,
    required this.branchName,
    required this.branchAddress,
    required this.items,
    required this.rentalStartDate,
    required this.rentalEndDate,
    required this.rentalDays,
    required this.totalRentalFee,
    required this.depositPaid,
    this.status = 'pending',
    required this.deliveryAddress,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Tổng số sản phẩm trong đơn
  int get totalItemCount => items.fold(0, (acc, item) => acc + item.quantity);

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    final now = DateTime.now();
    final createdAt = _dateFromDynamic(data['createdAt'], now);
    final updatedAt = _dateFromDynamic(data['updatedAt'], createdAt);
    final rentalStartDate = _dateFromDynamic(data['rentalStartDate'] ?? data['startDate'], now);
    final rentalEndDate = _dateFromDynamic(data['rentalEndDate'] ?? data['endDate'], rentalStartDate);

    return OrderModel(
      id: id,
      userId: (data['userId'] ?? '').toString(),
      branchId: (data['branchId'] ?? data['branch'] ?? '').toString(),
      branchName: (data['branchName'] ?? data['branch'] ?? '').toString(),
      branchAddress: (data['branchAddress'] ?? '').toString(),
      items: (data['items'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      rentalStartDate: rentalStartDate,
      rentalEndDate: rentalEndDate,
      rentalDays: _asInt(data['rentalDays'] ?? 1),
      totalRentalFee: _asDouble(data['totalRentalFee'] ?? data['totalRentalPrice']),
      depositPaid: _asDouble(data['depositPaid'] ?? data['totalDepositPrice']),
      status: (data['status'] ?? 'pending').toString(),
      deliveryAddress: (data['deliveryAddress'] ?? data['address'] ?? '').toString(),
      note: data['note']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'branchId': branchId,
      'branchName': branchName,
      'branchAddress': branchAddress,
      'items': items.map((item) => item.toMap()).toList(),
      'rentalStartDate': Timestamp.fromDate(rentalStartDate),
      'rentalEndDate': Timestamp.fromDate(rentalEndDate),
      'rentalDays': rentalDays,
      'totalRentalFee': totalRentalFee,
      'depositPaid': depositPaid,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _dateFromDynamic(dynamic value, DateTime fallback) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return fallback;
}
