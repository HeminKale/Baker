class WishlistItem {
  const WishlistItem({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.currentPrice,
    required this.imageUrl,
  });

  final String variantId;
  final String productId;
  final String productName;
  final String variantName;
  final int currentPrice;
  final String? imageUrl;

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      variantId: json['variantId'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      variantName: json['variantName'] as String,
      currentPrice: json['currentPrice'] as int,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
