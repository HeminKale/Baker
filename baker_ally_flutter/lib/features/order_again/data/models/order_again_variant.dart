/// Live product/variant display data for a previously-ordered variant
/// (matches `loadVariantDisplayInfo` in routes/order-again.ts). Keyed by the
/// exact variant bought, not the product's default display variant.
class OrderAgainVariant {
  const OrderAgainVariant({
    required this.variantId,
    required this.variantName,
    required this.currentPrice,
    required this.originalPrice,
    required this.stockQty,
    required this.isActive,
    required this.productId,
    required this.productName,
    this.imageUrl,
  });

  final String variantId;
  final String variantName;
  final int currentPrice;
  final int originalPrice;
  final int stockQty;
  final bool isActive;
  final String productId;
  final String productName;
  final String? imageUrl;

  bool get isOutOfStock => !isActive || stockQty <= 0;

  factory OrderAgainVariant.fromJson(Map<String, dynamic> json) {
    return OrderAgainVariant(
      variantId: json['variantId'] as String,
      variantName: json['variantName'] as String,
      currentPrice: json['currentPrice'] as int,
      originalPrice: json['originalPrice'] as int,
      stockQty: json['stockQty'] as int,
      isActive: json['isActive'] as bool,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

/// `GET /order-again/frequently-bought` row -- a combo of 2+ variants the
/// user has ordered together more than once.
class FrequentlyBoughtGroup {
  const FrequentlyBoughtGroup({required this.variantIds, required this.orderCount, required this.items});

  final List<String> variantIds;
  final int orderCount;
  final List<OrderAgainVariant> items;

  factory FrequentlyBoughtGroup.fromJson(Map<String, dynamic> json) {
    return FrequentlyBoughtGroup(
      variantIds: (json['variantIds'] as List).cast<String>(),
      orderCount: json['orderCount'] as int,
      items: (json['items'] as List).map((e) => OrderAgainVariant.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// `GET /order-again/previously-bought` row -- one distinct variant, most
/// recently ordered first.
class PreviouslyBoughtItem {
  const PreviouslyBoughtItem({required this.variant, required this.lastOrderedAt});

  final OrderAgainVariant variant;
  final DateTime lastOrderedAt;

  factory PreviouslyBoughtItem.fromJson(Map<String, dynamic> json) {
    return PreviouslyBoughtItem(
      variant: OrderAgainVariant.fromJson(json),
      lastOrderedAt: DateTime.parse(json['lastOrderedAt'] as String),
    );
  }
}
