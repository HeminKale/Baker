import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../shared/local_db/app_database.dart';
import 'models/wishlist_item.dart';

/// Optimistic add/remove against Drift + background Dio call, matching the
/// exact pattern in Planning docs/Architecture/02_catalog_tab.md §6.
class WishlistRepository {
  WishlistRepository({required Dio dio, required AppDatabase db}) : _dio = dio, _db = db;

  final Dio _dio;
  final AppDatabase _db;

  Future<Set<String>> getCachedVariantIds() async {
    final rows = await _db.select(_db.cachedWishlistItems).get();
    return rows.map((r) => r.variantId).toSet();
  }

  /// Replaces the local cache with the server's wishlist -- call on login /
  /// app open so wishlist state is correct across devices (per-login, synced
  /// -- 00_common_architecture.md §17 decision #9).
  Future<Set<String>> refresh() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/wishlist');
    final items =
        (response.data!['data'] as List).map((e) => WishlistItem.fromJson(e as Map<String, dynamic>)).toList();

    await _db.delete(_db.cachedWishlistItems).go();
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.cachedWishlistItems,
        items.map(
          (i) => CachedWishlistItemsCompanion.insert(
            variantId: i.variantId,
            productId: i.productId,
            productName: i.productName,
            variantName: i.variantName,
            currentPrice: i.currentPrice,
            imageUrl: Value(i.imageUrl),
          ),
        ),
      );
    });
    return items.map((i) => i.variantId).toSet();
  }

  /// Caches locally first (instant heart fill), then syncs to server.
  /// Reverts the local cache and rethrows if the server call fails, so the
  /// caller (WishlistNotifier) can revert its optimistic UI state too.
  /// Full display data for the `/wishlist` grid screen (Milestone 5) --
  /// network-first with the same Drift fallback shape as AddressRepository,
  /// distinct from the lightweight id-only `refresh()`/`getCachedVariantIds()`
  /// used for the O(1) heart lookup.
  Future<List<WishlistItem>> getItems() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/v1/wishlist');
      return (response.data!['data'] as List).map((e) => WishlistItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException {
      final cached = await _db.select(_db.cachedWishlistItems).get();
      if (cached.isEmpty) rethrow;
      return cached
          .map((r) => WishlistItem(
                variantId: r.variantId,
                productId: r.productId,
                productName: r.productName,
                variantName: r.variantName,
                currentPrice: r.currentPrice,
                imageUrl: r.imageUrl,
              ))
          .toList();
    }
  }

  Future<void> add({
    required String variantId,
    required String productId,
    required String productName,
    required String variantName,
    required int currentPrice,
    String? imageUrl,
  }) async {
    await _db.into(_db.cachedWishlistItems).insertOnConflictUpdate(
          CachedWishlistItemsCompanion.insert(
            variantId: variantId,
            productId: productId,
            productName: productName,
            variantName: variantName,
            currentPrice: currentPrice,
            imageUrl: Value(imageUrl),
          ),
        );
    try {
      await _dio.post<void>('/v1/wishlist', data: {'variantId': variantId});
    } catch (_) {
      await (_db.delete(_db.cachedWishlistItems)..where((t) => t.variantId.equals(variantId))).go();
      rethrow;
    }
  }

  Future<void> remove(String variantId) async {
    final existing =
        await (_db.select(_db.cachedWishlistItems)..where((t) => t.variantId.equals(variantId))).getSingleOrNull();
    await (_db.delete(_db.cachedWishlistItems)..where((t) => t.variantId.equals(variantId))).go();
    try {
      await _dio.delete<void>('/v1/wishlist/$variantId');
    } catch (_) {
      if (existing != null) {
        await _db.into(_db.cachedWishlistItems).insertOnConflictUpdate(existing.toCompanion(true));
      }
      rethrow;
    }
  }
}
