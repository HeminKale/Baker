import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../shared/local_db/app_database.dart';
import '../../catalog/data/models/product.dart';
import '../../catalog/data/models/product_variant.dart';
import 'models/home_sections.dart';

/// Network-first with Drift fallback for the Home preview
/// (01_home_tab.md §11) -- mirrors CatalogRepository/OrderRepository's
/// pattern. "See all" pagination (`getSection`) is network-only, same
/// treatment as Order Again's Previously Bought pagination in Milestone 5.
class HomeRepository {
  HomeRepository({required Dio dio, required AppDatabase db}) : _dio = dio, _db = db;

  final Dio _dio;
  final AppDatabase _db;

  Future<HomeSections> getHomeSections() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/v1/home');
      final sections = HomeSections.fromJson(response.data!['data'] as Map<String, dynamic>);
      await _cache(sections);
      return sections;
    } on DioException {
      final cached = await _cachedSections();
      if (cached == null) rethrow;
      return cached;
    }
  }

  Future<List<Product>> getSection(HomeSection section, {int page = 1, int limit = 20}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/home/${section.apiSlug}',
      queryParameters: {'page': page, 'limit': limit},
    );
    return (response.data!['data'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _cache(HomeSections sections) async {
    await _db.transaction(() async {
      await _db.delete(_db.cachedHomeSections).go();
      await _insertRows(HomeSection.newlyLaunched, sections.newlyLaunched);
      await _insertRows(HomeSection.newOffers, sections.newOffers);
      await _insertRows(HomeSection.trending, sections.trending);
    });
  }

  Future<void> _insertRows(HomeSection section, List<Product> products) async {
    if (products.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(
        _db.cachedHomeSections,
        products.asMap().entries.map(
              (entry) => CachedHomeSectionsCompanion.insert(
                section: section.name,
                productId: entry.value.id,
                subCategoryId: entry.value.subCategoryId,
                name: entry.value.name,
                isTrending: entry.value.isTrending,
                createdAt: entry.value.createdAt,
                sortOrder: entry.key,
                variantId: Value(entry.value.displayVariant?.id),
                variantName: Value(entry.value.displayVariant?.name),
                originalPrice: Value(entry.value.displayVariant?.originalPrice),
                currentPrice: Value(entry.value.displayVariant?.currentPrice),
                stockQty: Value(entry.value.displayVariant?.stockQty),
                imageUrl: Value(entry.value.displayImageUrl),
              ),
            ),
      );
    });
  }

  Future<HomeSections?> _cachedSections() async {
    final rows = await (_db.select(_db.cachedHomeSections)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
    if (rows.isEmpty) return null;

    List<Product> forSection(HomeSection section) => rows
        .where((r) => r.section == section.name)
        .map(_productFromRow)
        .toList();

    return HomeSections(
      newlyLaunched: forSection(HomeSection.newlyLaunched),
      newOffers: forSection(HomeSection.newOffers),
      trending: forSection(HomeSection.trending),
    );
  }

  Product _productFromRow(CachedHomeSection row) {
    return Product(
      id: row.productId,
      subCategoryId: row.subCategoryId,
      name: row.name,
      isTrending: row.isTrending,
      createdAt: row.createdAt,
      displayVariant: row.variantId == null
          ? null
          : ProductVariant(
              id: row.variantId!,
              productId: row.productId,
              name: row.variantName ?? '',
              sku: '',
              originalPrice: row.originalPrice ?? 0,
              currentPrice: row.currentPrice ?? 0,
              stockQty: row.stockQty ?? 0,
            ),
      displayImageUrl: row.imageUrl,
    );
  }
}
