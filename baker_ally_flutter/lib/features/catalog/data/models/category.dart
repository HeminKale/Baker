class Category {
  const Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sortOrder,
    required this.subCategoryCount,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final int sortOrder;
  final int subCategoryCount;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      subCategoryCount: json['subCategoryCount'] as int? ?? 0,
    );
  }
}
