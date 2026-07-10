import 'product_image.dart';
import 'product_variant.dart';

/// Shape returned by GET /v1/products/:id -- deliberately NOT Drift-cached
/// (00_common_architecture.md §15), so this model only ever comes from the
/// network.
class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.isTrending,
    required this.subCategoryId,
    required this.subCategoryName,
    required this.categoryName,
    required this.variants,
    required this.images,
  });

  final String id;
  final String name;
  final String? description;
  final bool isTrending;
  final String subCategoryId;
  final String subCategoryName;
  final String categoryName;
  final List<ProductVariant> variants;
  final List<ProductImage> images;

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isTrending: json['isTrending'] as bool? ?? false,
      subCategoryId: json['subCategoryId'] as String,
      subCategoryName: json['subCategoryName'] as String,
      categoryName: json['categoryName'] as String,
      variants: (json['variants'] as List)
          .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List)
          .map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
