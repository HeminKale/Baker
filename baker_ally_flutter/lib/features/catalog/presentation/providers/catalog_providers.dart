import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/catalog_repository.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';
import '../../data/models/product_detail.dart';
import '../../data/models/sub_category.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(dio: ref.watch(dioProvider), db: ref.watch(appDatabaseProvider));
});

/// All categories -- loaded once, cached (02_catalog_tab.md §10).
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(catalogRepositoryProvider).getCategories();
});

/// Subcategories for one category -- Level 1 needs these per category
/// heading (02_catalog_tab.md §2); a direct extension of §10's pattern.
final subCategoriesProvider = FutureProvider.family<List<SubCategory>, String>((ref, categoryId) async {
  return ref.watch(catalogRepositoryProvider).getSubCategories(categoryId);
});

/// Products across all of a category's subcategories -- Level 2 groups this
/// flat list client-side by subCategoryId (02_catalog_tab.md §3, §9).
final categoryProductsProvider = FutureProvider.family<List<Product>, String>((ref, categoryId) async {
  return ref.watch(catalogRepositoryProvider).getProductsByCategory(categoryId);
});

/// Drives Level 2's left-strip <-> grid scroll-spy sync, keyed by categoryId
/// so switching categories doesn't leak selection state (02_catalog_tab.md §10).
final activeSubcategoryProvider = StateProvider.family<String?, String>((ref, categoryId) => null);

final productDetailProvider = FutureProvider.family<ProductDetail, String>((ref, productId) async {
  return ref.watch(catalogRepositoryProvider).getProduct(productId);
});

final relatedProductsProvider = FutureProvider.family<List<Product>, String>((ref, productId) async {
  return ref.watch(catalogRepositoryProvider).getRelated(productId);
});

enum CatalogSort { relevance, priceLowToHigh, priceHighToLow, newest }

/// Ephemeral filter/sort state for Level 2's [Filter] bottom sheet
/// (02_catalog_tab.md §7) -- not persisted anywhere, so it resets whenever
/// the screen is rebuilt fresh. Defaults to `inStockOnly: false` -- the Key
/// Rules in 02_catalog_tab.md are explicit that out-of-stock products are
/// shown, not hidden, until the user opts into hiding them via this sheet.
class CatalogFilter {
  const CatalogFilter({this.sort = CatalogSort.relevance, this.inStockOnly = false});

  final CatalogSort sort;
  final bool inStockOnly;

  CatalogFilter copyWith({CatalogSort? sort, bool? inStockOnly}) {
    return CatalogFilter(sort: sort ?? this.sort, inStockOnly: inStockOnly ?? this.inStockOnly);
  }
}

final catalogFilterProvider =
    StateProvider.family<CatalogFilter, String>((ref, categoryId) => const CatalogFilter());

/// Powers the "Last updated X ago" banner (00_common_architecture.md §15)
/// when catalog data came from the Drift fallback rather than the network.
final catalogLastSyncedProvider = FutureProvider<DateTime?>((ref) async {
  return ref.watch(catalogRepositoryProvider).getCatalogLastSyncedAt();
});

/// Debounced search state -- text-only (voice search stays deferred to
/// Phase 5, see Phase_Plan_Technical.md's Milestone 1 update). No debounce
/// package, just a plain Timer.
class SearchState {
  const SearchState({this.query = '', this.results = const [], this.isLoading = false});

  final String query;
  final List<Product> results;
  final bool isLoading;

  SearchState copyWith({String? query, List<Product>? results, bool? isLoading}) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._repository) : super(const SearchState());

  final CatalogRepository _repository;
  Timer? _debounce;

  void onQueryChanged(String query) {
    _debounce?.cancel();
    state = state.copyWith(query: query);
    if (query.trim().isEmpty) {
      state = state.copyWith(results: const [], isLoading: false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await _repository.search(query);
      if (state.query == query) {
        state = state.copyWith(results: results, isLoading: false);
      }
    } catch (_) {
      if (state.query == query) {
        state = state.copyWith(results: const [], isLoading: false);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider.autoDispose<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(catalogRepositoryProvider));
});

// Milestone 2's in-memory `localCartStubProvider` was removed in Milestone 3 --
// the product tile + detail CTA now talk to the real server-synced
// `cartProvider` (features/cart/presentation/providers/cart_providers.dart)
// directly, via `addToCart(...)` in product_tile.dart.
