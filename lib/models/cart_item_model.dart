class CartItemModel {
  final String productId;
  final String productName;
  final String imageUrl;
  final String selectedSize;
  final String selectedColor;
  final double rentalPricePerDay;
  final double depositPrice;
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
    this.quantity = 1,
    this.rentalDays = 1,
  });

  // Tự động tính tiền thuê cho item này
  double get totalItemRental => rentalPricePerDay * quantity * rentalDays;
  
  // Tự động tính tiền cọc cho item này
  double get totalItemDeposit => depositPrice * quantity;
}