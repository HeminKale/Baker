import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../data/cart_repository.dart';
import '../../data/models/cart_item.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(dio: ref.watch(dioProvider), db: ref.watch(appDatabaseProvider));
});

/// Cart items + derived totals. Bill breakdown (discount, shipping, grand
/// total) is a checkout-screen concern and lives in checkout_providers, not
/// here -- CartState stays focused on what the badge, tiles and cart list need.
class CartState {
  const CartState({this.items = const [], this.isLoading = false});

  final List<CartItem> items;
  final bool isLoading;

  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  /// Item total in paise (00_common_architecture.md §6).
  int get subtotal => items.fold(0, (sum, i) => sum + i.lineTotal);

  int quantityOf(String variantId) {
    for (final item in items) {
      if (item.variantId == variantId) return item.quantity;
    }
    return 0;
  }

  CartState copyWith({List<CartItem>? items, bool? isLoading}) {
    return CartState(items: items ?? this.items, isLoading: isLoading ?? this.isLoading);
  }
}

/// Server-synced, Drift-backed cart (05_cart_and_checkout.md §2, §12). Replaces
/// Milestone 2's in-memory stub. Seeds from Drift instantly, refreshes from the
/// server when logged in, and merges a guest's local cart on login.
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this._ref, this._repository) : super(const CartState()) {
    _init();
    _ref.listen<AuthSessionState>(authProvider, (previous, next) {
      final wasLoggedIn = previous?.isLoggedIn ?? false;
      if (!wasLoggedIn && next.isLoggedIn) {
        _onLogin();
      } else if (wasLoggedIn && !next.isLoggedIn) {
        _onLogout();
      }
    });
  }

  final Ref _ref;
  final CartRepository _repository;

  bool get _isLoggedIn => _ref.read(authProvider).isLoggedIn;

  Future<void> _init() async {
    final local = await _repository.loadLocalCart();
    state = state.copyWith(items: local);
    if (_isLoggedIn) {
      try {
        final server = await _repository.fetchServerCart();
        state = state.copyWith(items: server);
      } catch (_) {
        // Offline -- keep the Drift-cached cart.
      }
    }
  }

  Future<void> _onLogin() async {
    try {
      // Only genuinely-guest items (no server id yet) are merged. Items that
      // already have a serverId came from a previous logged-in session's Drift
      // cache -- re-merging those would double their quantity on the server on
      // every cold start.
      final guestItems = state.items.where((i) => i.serverId == null).toList();
      final merged = guestItems.isNotEmpty
          ? await _repository.mergeGuestCart(guestItems)
          : await _repository.fetchServerCart();
      state = state.copyWith(items: merged);
    } catch (_) {
      // Server unreachable -- the local cart stays; a later add/refresh retries.
    }
  }

  Future<void> _onLogout() async {
    await _repository.clearLocalCart();
    state = const CartState();
  }

  /// Persist [items] to state + Drift together, so the optimistic UI survives
  /// an app kill and a revert restores both layers.
  void _setItems(List<CartItem> items) {
    state = state.copyWith(items: items);
    _repository.saveLocalCart(items);
  }

  List<CartItem> _upsert(List<CartItem> items, CartItem item) {
    final index = items.indexWhere((i) => i.variantId == item.variantId);
    final next = [...items];
    if (index >= 0) {
      next[index] = item;
    } else {
      next.add(item);
    }
    return next;
  }

  /// Adds one unit of a variant (or increments an existing line). Returns false
  /// without changing anything once stock is reached, so the caller can show
  /// "Max stock reached" (05_cart_and_checkout.md §1).
  bool addItem({
    required String variantId,
    required String productId,
    required String productName,
    required String variantName,
    required int currentPrice,
    required int originalPrice,
    required int stockQty,
    String? imageUrl,
  }) {
    final currentQty = state.quantityOf(variantId);
    if (currentQty >= stockQty) return false;

    final previous = state.items;
    final existing = previous.where((i) => i.variantId == variantId).toList();
    final updated = (existing.isNotEmpty
            ? existing.first
            : CartItem(
                variantId: variantId,
                productId: productId,
                productName: productName,
                variantName: variantName,
                currentPrice: currentPrice,
                originalPrice: originalPrice,
                stockQty: stockQty,
                quantity: 0,
                imageUrl: imageUrl,
              ))
        .copyWith(quantity: currentQty + 1);

    _setItems(_upsert(previous, updated));
    _syncAfterOptimistic(previous, _isLoggedIn ? () => _repository.addItemToServer(variantId, 1) : null);
    return true;
  }

  /// Decrement one unit; quantity hitting 0 removes the line (qty-0 = removal,
  /// 05_cart_and_checkout.md Key Rules).
  void decrement(String variantId) {
    final previous = state.items;
    final existing = previous.where((i) => i.variantId == variantId).toList();
    if (existing.isEmpty) return;
    final item = existing.first;
    final newQty = item.quantity - 1;

    if (newQty <= 0) {
      _setItems(previous.where((i) => i.variantId != variantId).toList());
      _syncAfterOptimistic(
        previous,
        (_isLoggedIn && item.serverId != null) ? () => _repository.removeServerItem(item.serverId!) : null,
      );
    } else {
      _setItems(_upsert(previous, item.copyWith(quantity: newQty)));
      _syncAfterOptimistic(
        previous,
        (_isLoggedIn && item.serverId != null) ? () => _repository.updateServerItem(item.serverId!, newQty) : null,
      );
    }
  }

  /// Absolute quantity set from the checkout stepper. 0 removes the line.
  void setQuantity(String variantId, int quantity) {
    final previous = state.items;
    final existing = previous.where((i) => i.variantId == variantId).toList();
    if (existing.isEmpty) return;
    final item = existing.first;
    final capped = quantity < 0 ? 0 : (quantity > item.stockQty ? item.stockQty : quantity);

    if (capped == 0) {
      _setItems(previous.where((i) => i.variantId != variantId).toList());
      _syncAfterOptimistic(
        previous,
        (_isLoggedIn && item.serverId != null) ? () => _repository.removeServerItem(item.serverId!) : null,
      );
    } else {
      _setItems(_upsert(previous, item.copyWith(quantity: capped)));
      _syncAfterOptimistic(
        previous,
        (_isLoggedIn && item.serverId != null) ? () => _repository.updateServerItem(item.serverId!, capped) : null,
      );
    }
  }

  /// Order Again's "Add Selected Items to Cart" (Milestone 5). Server-only --
  /// Order Again's data requires past orders, so guests never reach it and
  /// no local/optimistic path is needed here. Throws on failure; the caller
  /// (GroupDetailSheet) shows the error.
  Future<void> addBatch(List<({String variantId, int quantity})> items) async {
    if (items.isEmpty) return;
    final server = await _repository.addItemsBatch(items);
    state = state.copyWith(items: server);
  }

  /// Pulls the authoritative server cart -- used after a PRICE_CHANGED response
  /// so the bill reflects updated prices before the user retries.
  Future<void> refresh() async {
    if (!_isLoggedIn) return;
    try {
      final server = await _repository.fetchServerCart();
      state = state.copyWith(items: server);
    } catch (_) {
      // Offline -- keep current state.
    }
  }

  /// Called after a confirmed order -- cart is already server-cleared by the
  /// confirm endpoint, so this just resets local state + Drift.
  Future<void> clearAfterOrder() async {
    await _repository.clearLocalCart();
    state = const CartState();
  }

  Future<void> _syncAfterOptimistic(
    List<CartItem> previous,
    Future<List<CartItem>> Function()? serverCall,
  ) async {
    if (serverCall == null) return; // guest -- local only
    try {
      final serverItems = await serverCall();
      state = state.copyWith(items: serverItems);
    } catch (_) {
      _setItems(previous); // revert both state + Drift
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref, ref.watch(cartRepositoryProvider));
});
