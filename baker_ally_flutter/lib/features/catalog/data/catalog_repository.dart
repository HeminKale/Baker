import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../shared/local_db/app_database.dart';
import 'models/category.dart';
import 'models/product.dart';
import 'models/product_detail.dart';
import 'models/product_variant.dart';
import 'models/sub_category.dart';

/// Network-first with Drift fallback for list endpoints, per
/// 00_common_architecture.md §15 and 02_catalog_tab.md §9. Product detail is
/// deliberately network-only -- it is not part of the offline story.
class CatalogRepository {
  CatalogRepository({required Dio dio, required AppDatabase db}) : _dio = dio, _db = db;

  final Dio _dio;
  final AppDatabase _db;

  static const _lastSyncedKey = 'catalog_last_synced_at';

  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/v1/categories');
      final categories = (response.data!['data'] as List)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
      await _cacheCategories(categories);
      await _markSynced();
      return categories;
    } on DioException {
      final cached = await _db.select(_db.cachedCategories).get();
      if (cached.isEmpty) rethrow;
      return cached
          .map((row) => Category(
                id: row.id,
                name: row.name,
                imageUrl: row.imageUrl,
                sortOrder: row.sortOrder,
                subCategoryCount: row.subCategoryCount,
              ))
          .toList();
    }
  }

  Future<void> _cacheCategories(List<Category> categories) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.cachedCategories,
        categories.map(
          (c) => CachedCategoriesCompanion.insert(
            id: c.id,
            name: c.name,
            imageUrl: Value(c.imageUrl),
            sortOrder: c.sortOrder,
            subCategoryCount: c.subCategoryCount,
          ),
        ),
      );
    });
  }

  Future<List<SubCategory>> getSubCategories(String categoryId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/v1/categories/$categoryId/subcategories');
      final subs = (response.data!['data'] as List)
          .map((e) => SubCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(
          _db.cachedSubCategories,
          subs.map(
            (s) => CachedSubCategoriesCompanion.insert(
              id: s.id,
              categoryId: s.categoryId,
              name: s.name,
              imageUrl: Value(s.imageUrl),
              sortOrder: s.sortOrder,
            ),
          ),
        );
      });
      return subs;
    } on DioException {
      final cached =
          await (_db.select(_db.cachedSubCategories)..where((t) => t.categoryId.equals(categoryId))).get();
      if (cached.isEmpty) rethrow;
      return cached
          .map((row) => SubCategory(
                id: row.id,
                categoryId: row.categoryId,
                name: row.name,
                imageUrl: row.imageUrl,
                sortOrder: row.sortOrder,
              ))
          .toList();
    }
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/products',
        queryParameters: {'categoryId': categoryId},
      );
      final products =
          (response.data!['data'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      await _cacheProducts(categoryId, products);
      await _markSynced();
      return products;
    } on DioException {
      final cached = await (_db.select(_db.cachedProducts)..where((t) => t.categoryId.equals(categoryId))).get();
      if (cached.isEmpty) rethrow;
      return cached.map(_productFromRow).toList();
    }
  }

  Future<void> _cacheProducts(String categoryId, List<Product> products) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.cachedProducts,
        products.map(
          (p) => CachedProductsCompanion.insert(
            id: p.id,
            subCategoryId: p.subCategoryId,
            categoryId: categoryId,
            name: p.name,
            isTrending: p.isTrending,
            createdAt: p.createdAt,
            sortOrder: 0,
            variantId: Value(p.displayVariant?.id),
            variantName: Value(p.displayVariant?.name),
            originalPrice: Value(p.displayVariant?.originalPrice),
            currentPrice: Value(p.displayVariant?.currentPrice),
            stockQty: Value(p.displayVariant?.stockQty),
            imageUrl: Value(p.displayImageUrl),
          ),
        ),
      );
    });
  }

  Product _productFromRow(CachedProduct row) {
    return Product(
      id: row.id,
      subCategoryId: row.subCategoryId,
      name: row.name,
      isTrending: row.isTrending,
      createdAt: row.createdAt,
      displayVariant: row.variantId == null
          ? null
          : ProductVariant(
              id: row.variantId!,
              productId: row.id,
              name: row.variantName ?? '',
              sku: '',
              originalPrice: row.originalPrice ?? 0,
              currentPrice: row.currentPrice ?? 0,
              stockQty: row.stockQty ?? 0,
            ),
      displayImageUrl: row.imageUrl,
    );
  }

  /// Never cached -- see class doc.
  Future<ProductDetail> getProduct(String productId) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/products/$productId');
    return ProductDetail.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<List<Product>> getRelated(String productId) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/products/$productId/related');
    return (response.data!['data'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Product>> search(String query, {int page = 1, int limit = 20}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/products',
      queryParameters: {'q': query, 'page': page, 'limit': limit},
    );
    return (response.data!['data'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _markSynced() async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: _lastSyncedKey, value: DateTime.now().toIso8601String()),
        );
  }

  Future<DateTime?> getCatalogLastSyncedAt() async {
    final row = await (_db.select(_db.appSettings)..where((t) => t.key.equals(_lastSyncedKey))).getSingleOrNull();
    if (row == null) return null;
    return DateTime.tryParse(row.value);
  }
}
