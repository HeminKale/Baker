import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/models/wishlist_item.dart';
import '../../data/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(dio: ref.watch(dioProvider), db: ref.watch(appDatabaseProvider));
});

/// O(1) heart-state lookup (02_catalog_tab.md §10). Seeded from the Drift
/// cache immediately, then refreshed from the server (wishlist is per-login
/// and synced across devices -- 00_common_architecture.md §17 decision #9).
class WishlistNotifier extends StateNotifier<Set<String>> {
  WishlistNotifier(this._repository) : super(const {}) {
    _init();
  }

  final WishlistRepository _repository;

  Future<void> _init() async {
    state = await _repository.getCachedVariantIds();
    try {
      state = await _repository.refresh();
    } catch (_) {
      // Offline or logged out -- keep whatever was cached locally.
    }
  }

  /// Optimistic toggle -- heart flips instantly, reverts on failure. Matches
  /// the snippet in 02_catalog_tab.md §6.
  Future<void> toggle({
    required String variantId,
    required String productId,
    required String productName,
    required String variantName,
    required int currentPrice,
    String? imageUrl,
  }) async {
    final wasInWishlist = state.contains(variantId);
    state = wasInWishlist ? ({...state}..remove(variantId)) : {...state, variantId};

    try {
      if (wasInWishlist) {
        await _repository.remove(variantId);
      } else {
        await _repository.add(
          variantId: variantId,
          productId: productId,
          productName: productName,
          variantName: variantName,
          currentPrice: currentPrice,
          imageUrl: imageUrl,
        );
      }
    } catch (_) {
      state = wasInWishlist ? {...state, variantId} : ({...state}..remove(variantId));
    }
  }
}

final wishlistIdsProvider = StateNotifierProvider<WishlistNotifier, Set<String>>((ref) {
  return WishlistNotifier(ref.watch(wishlistRepositoryProvider));
});

/// Full display data for the `/wishlist` grid screen -- autoDispose so it
/// clears on logout/sheet-close rather than serving stale items next login
/// (matches the `profileProvider` precedent).
final wishlistItemsProvider = FutureProvider.autoDispose<List<WishlistItem>>((ref) async {
  return ref.watch(wishlistRepositoryProvider).getItems();
});
