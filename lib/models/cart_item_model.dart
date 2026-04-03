class CartItemModel {
  final String productId;
  final String productName;
  final String imageUrl;
  final String selectedSize;
  final String selectedColor;
  final double rentalPricePerDay;
  final double depositPrice;
  final String branchId;
  final String branchName;
  final String branchAddress;
  int quantity;
  int rentalDays; // Số ngày thuê mặc định

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.selectedSize,
    required this.selectedColor,
    required this.rentalPricePerDay,
    required this.depositPrice,
    required this.branchId,
    required this.branchName,
    required this.branchAddress,
    this.quantity = 1,
    this.rentalDays = 1,
  });

  // Tự động tính tiền thuê cho item này
  double get totalItemRental => rentalPricePerDay * quantity * rentalDays;
  
  // Tự động tính tiền cọc cho item này
  double get totalItemDeposit => depositPrice * quantity;

  // Convert to Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'rentalPricePerDay': rentalPricePerDay,
      'depositPrice': depositPrice,
      'branchId': branchId,
      'branchName': branchName,
      'branchAddress': branchAddress,
      'quantity': quantity,
      'rentalDays': rentalDays,
    };
  }

  // Convert từ Map (Firestore) sang CartItemModel
  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      selectedSize: map['selectedSize'] ?? '',
      selectedColor: map['selectedColor'] ?? '',
      rentalPricePerDay: (map['rentalPricePerDay'] ?? 0).toDouble(),
      depositPrice: (map['depositPrice'] ?? 0).toDouble(),
      branchId: map['branchId'] ?? '',
      branchName: map['branchName'] ?? '',
      branchAddress: map['branchAddress'] ?? '',
      quantity: (map['quantity'] ?? 1).toInt(),
      rentalDays: (map['rentalDays'] ?? 1).toInt(),
    );
  }
}