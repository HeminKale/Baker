class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.sku,
    required this.originalPrice,
    required this.currentPrice,
    required this.stockQty,
  });

  final String id;
  final String productId;
  final String name;
  final String sku;

  /// Paise -- 00_common_architecture.md §6 two-price model.
  final int originalPrice;
  final int currentPrice;
  final int stockQty;

  bool get isOnSale => originalPrice != currentPrice;
  bool get isOutOfStock => stockQty <= 0;
  bool get isLowStock => stockQty > 0 && stockQty <= 5;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      productId: json['productId'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      originalPrice: json['originalPrice'] as int,
      currentPrice: json['currentPrice'] as int,
      stockQty: json['stockQty'] as int? ?? 0,
    );
  }
}
