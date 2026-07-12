/// One line in the cart. `serverId` is the server cart_item id (null for a
/// guest item not yet synced). All prices are paise
/// (00_common_architecture.md §6). Matches the GET /v1/cart item shape.
class CartItem {
  const CartItem({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.currentPrice,
    required this.originalPrice,
    required this.stockQty,
    required this.quantity,
    this.serverId,
    this.imageUrl,
  });

  final String? serverId;
  final String variantId;
  final String productId;
  final String productName;
  final String variantName;
  final int currentPrice;
  final int originalPrice;
  final int stockQty;
  final int quantity;
  final String? imageUrl;

  int get lineTotal => currentPrice * quantity;
  bool get isOnSale => originalPrice != currentPrice;

  CartItem copyWith({int? quantity, String? serverId, int? stockQty, int? currentPrice}) {
    return CartItem(
      serverId: serverId ?? this.serverId,
      variantId: variantId,
      productId: productId,
      productName: productName,
      variantName: variantName,
      currentPrice: currentPrice ?? this.currentPrice,
      originalPrice: originalPrice,
      stockQty: stockQty ?? this.stockQty,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
    );
  }

  /// Parses a row from GET /v1/cart (and the other cart endpoints, which all
  /// return the full cart). `id` there is the server cart_item id.
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      serverId: json['id'] as String?,
      variantId: json['variantId'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      variantName: json['variantName'] as String,
      currentPrice: json['currentPrice'] as int,
      originalPrice: json['originalPrice'] as int? ?? json['currentPrice'] as int,
      stockQty: json['stockQty'] as int? ?? 0,
      quantity: json['quantity'] as int,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
