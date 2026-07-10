class ProductImage {
  const ProductImage({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.publicUrl,
    required this.sortOrder,
    required this.isPrimary,
  });

  final String id;
  final String productId;
  final String? variantId;
  final String publicUrl;
  final int sortOrder;
  final bool isPrimary;

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as String,
      productId: json['productId'] as String,
      variantId: json['variantId'] as String?,
      publicUrl: json['publicUrl'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}
