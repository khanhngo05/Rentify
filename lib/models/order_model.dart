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
    return OrderItem(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      selectedSize: data['selectedSize'] ?? '',
      selectedColor: data['selectedColor'] ?? '',
      rentalPricePerDay: (data['rentalPricePerDay'] ?? 0).toDouble(),
      depositAmount: (data['depositAmount'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 1).toInt(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
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
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    return OrderModel(
      id: id,
      userId: data['userId'] ?? '',
      branchId: data['branchId'] ?? '',
      branchName: data['branchName'] ?? '',
      branchAddress: data['branchAddress'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      rentalStartDate:
          (data['rentalStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rentalEndDate:
          (data['rentalEndDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rentalDays: (data['rentalDays'] ?? 1).toInt(),
      totalRentalFee: (data['totalRentalFee'] ?? 0).toDouble(),
      depositPaid: (data['depositPaid'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      deliveryAddress: data['deliveryAddress'] ?? '',
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
