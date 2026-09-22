class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.variantId,
    required this.quantity,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.currentPrice,
    required this.originalPrice,
    required this.stockQty,
    this.imageUrl,
  });

  final String id;
  final String variantId;
  final int quantity;
  final String productId;
  final String productName;
  final String variantName;
  final int currentPrice;
  final int originalPrice;
  final int stockQty;
  final String? imageUrl;

  bool get isOnSale => originalPrice > currentPrice;
  int get lineCurrentTotal => currentPrice * quantity;
  int get lineOriginalTotal => originalPrice * quantity;

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      id: json['id'] as String,
      variantId: json['variantId'] as String,
      quantity: json['quantity'] as int,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      variantName: json['variantName'] as String,
      currentPrice: json['currentPrice'] as int,
      originalPrice: json['originalPrice'] as int,
      stockQty: json['stockQty'] as int,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
