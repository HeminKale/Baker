class SubCategory {
  const SubCategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.imageUrl,
    required this.sortOrder,
  });

  final String id;
  final String categoryId;
  final String name;
  final String? imageUrl;
  final int sortOrder;

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
