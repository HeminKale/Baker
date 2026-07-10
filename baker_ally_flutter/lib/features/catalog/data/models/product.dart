import 'product_variant.dart';

/// Badge priority order + max-2 rule from
/// Planning docs/Architecture/02_catalog_tab.md §5.
enum ProductBadge { outOfStock, lowStock, sale, trending, newArrival }

/// List/tile shape returned by GET /v1/products (and /related) -- includes
/// only the "display" variant/image, not the full variant/image lists
/// (those live on ProductDetail, fetched per-product on Level 3).
class Product {
  const Product({
    required this.id,
    required this.subCategoryId,
    required this.name,
    required this.isTrending,
    required this.createdAt,
    required this.displayVariant,
    required this.displayImageUrl,
  });

  final String id;
  final String subCategoryId;
  final String name;
  final bool isTrending;
  final DateTime createdAt;
  final ProductVariant? displayVariant;
  final String? displayImageUrl;

  bool get isNew => DateTime.now().difference(createdAt).inDays <= 30;

  List<ProductBadge> get badges {
    final variant = displayVariant;
    final candidates = <ProductBadge>[
      if (variant?.isOutOfStock ?? false) ProductBadge.outOfStock,
      if (variant?.isLowStock ?? false) ProductBadge.lowStock,
      if (variant?.isOnSale ?? false) ProductBadge.sale,
      if (isTrending) ProductBadge.trending,
      if (isNew) ProductBadge.newArrival,
    ];
    return candidates.take(2).toList();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final variantJson = json['displayVariant'] as Map<String, dynamic>?;
    return Product(
      id: json['id'] as String,
      subCategoryId: json['subCategoryId'] as String,
      name: json['name'] as String,
      isTrending: json['isTrending'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      displayVariant: variantJson != null ? ProductVariant.fromJson(variantJson) : null,
      displayImageUrl: json['displayImageUrl'] as String?,
    );
  }
}
