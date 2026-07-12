import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../shared/local_db/app_database.dart';
import 'models/cart_item.dart';

/// Two-layer cart (00_common_architecture.md §8): Drift is the instant-UI /
/// guest layer, the server is the source of truth once logged in. Every server
/// mutation endpoint returns the full cart, so callers replace state wholesale
/// from the response. Follows the WishlistRepository DI + Drift pattern.
class CartRepository {
  CartRepository({required Dio dio, required AppDatabase db}) : _dio = dio, _db = db;

  final Dio _dio;
  final AppDatabase _db;

  // ---- Drift (local) ----

  Future<List<CartItem>> loadLocalCart() async {
    final rows = await _db.select(_db.cachedCartItems).get();
    return rows
        .map((r) => CartItem(
              serverId: r.serverId,
              variantId: r.variantId,
              productId: r.productId,
              productName: r.productName,
              variantName: r.variantName,
              currentPrice: r.currentPrice,
              originalPrice: r.originalPrice,
              stockQty: r.stockQty,
              quantity: r.quantity,
              imageUrl: r.imageUrl,
            ))
        .toList();
  }

  /// Replaces the entire local cart table with [items] -- the cart is small,
  /// so a full rewrite is simpler and race-free versus per-row diffing.
  Future<void> saveLocalCart(List<CartItem> items) async {
    await _db.transaction(() async {
      await _db.delete(_db.cachedCartItems).go();
      if (items.isEmpty) return;
      await _db.batch((batch) {
        batch.insertAll(
          _db.cachedCartItems,
          items.map(
            (i) => CachedCartItemsCompanion.insert(
              variantId: i.variantId,
              serverId: Value(i.serverId),
              productId: i.productId,
              productName: i.productName,
              variantName: i.variantName,
              currentPrice: i.currentPrice,
              originalPrice: i.originalPrice,
              stockQty: i.stockQty,
              quantity: i.quantity,
              imageUrl: Value(i.imageUrl),
            ),
          ),
        );
      });
    });
  }

  Future<void> clearLocalCart() => _db.delete(_db.cachedCartItems).go();

  // ---- Server ----

  List<CartItem> _parseCart(Response<Map<String, dynamic>> response) {
    final items = (response.data!['data']['items'] as List)
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return items;
  }

  Future<List<CartItem>> fetchServerCart() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/cart');
    final items = _parseCart(response);
    await saveLocalCart(items);
    return items;
  }

  Future<List<CartItem>> addItemToServer(String variantId, int quantity) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/cart/items',
      data: {'variantId': variantId, 'quantity': quantity},
    );
    final items = _parseCart(response);
    await saveLocalCart(items);
    return items;
  }

  Future<List<CartItem>> updateServerItem(String cartItemId, int quantity) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/v1/cart/items/$cartItemId',
      data: {'quantity': quantity},
    );
    final items = _parseCart(response);
    await saveLocalCart(items);
    return items;
  }

  Future<List<CartItem>> removeServerItem(String cartItemId) async {
    final response = await _dio.delete<Map<String, dynamic>>('/v1/cart/items/$cartItemId');
    final items = _parseCart(response);
    await saveLocalCart(items);
    return items;
  }

  /// Guest -> login merge (00_common_architecture.md §8). Sends local items,
  /// server adds their quantities to the server cart, returns the merged cart.
  Future<List<CartItem>> mergeGuestCart(List<CartItem> localItems) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/cart/merge',
      data: {
        'items': localItems.map((i) => {'variantId': i.variantId, 'quantity': i.quantity}).toList(),
      },
    );
    final items = _parseCart(response);
    await saveLocalCart(items);
    return items;
  }

  /// Order Again's "Add Selected Items to Cart" (Milestone 5) -- hits Phase
  /// 1's `POST /cart/items/batch`, one round trip for the whole selection
  /// instead of N calls to `addItemToServer`.
  Future<List<CartItem>> addItemsBatch(List<({String variantId, int quantity})> items) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/cart/items/batch',
      data: {'items': items.map((i) => {'variantId': i.variantId, 'quantity': i.quantity}).toList()},
    );
    final parsed = _parseCart(response);
    await saveLocalCart(parsed);
    return parsed;
  }

  Future<void> clearServerCart() async {
    await _dio.delete<Map<String, dynamic>>('/v1/cart');
    await clearLocalCart();
  }
}
