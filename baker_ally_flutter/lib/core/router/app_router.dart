import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/catalog/presentation/screens/product_detail_screen.dart';
import '../../features/catalog/presentation/screens/subcategory_products_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/order_confirmation_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/placeholder_screen.dart';

/// Guests can view the cart and add items freely (05_cart_and_checkout.md
/// §2/§3) -- login is gated at the checkout "Proceed" action, not on /cart
/// itself. Order history/addresses screens (Phase 5) will add their own
/// protected paths here.
const _protectedPaths = <String>[];

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.isLoading) return null;

      final goingToLogin = state.uri.path == '/login';
      final needsAuth = _protectedPaths.any(state.uri.path.startsWith);

      if (!auth.isLoggedIn && needsAuth) {
        return '/login?redirect=${state.uri.path}';
      }
      if (auth.isLoggedIn && goingToLogin) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (c, s) => const PlaceholderScreen(title: 'Home')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/catalog', builder: (c, s) => const CatalogScreen()),
            GoRoute(
              path: '/catalog/:categoryId/:subId',
              builder: (c, s) => SubcategoryProductsScreen(
                categoryId: s.pathParameters['categoryId']!,
                initialSubCategoryId: s.pathParameters['subId']!,
              ),
            ),
            // Reachable from the catalog grid (and, later, search/home/wishlist)
            // -- a sibling of /catalog rather than nested under it, per
            // 00_common_architecture.md's GoRouter map, but still inside this
            // branch so the bottom nav stays visible on Level 3.
            GoRoute(
              path: '/product/:productId',
              builder: (c, s) => ProductDetailScreen(productId: s.pathParameters['productId']!),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/order-again', builder: (c, s) => const PlaceholderScreen(title: 'Order Again')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/brownie-points', builder: (c, s) => const PlaceholderScreen(title: 'Brownie Points')),
          ]),
          StatefulShellBranch(routes: [
            // The Cart tab IS the checkout page (05_cart_and_checkout.md §3).
            GoRoute(path: '/cart', builder: (c, s) => const CheckoutScreen()),
            // Sibling inside the Cart branch so the bottom nav stays visible on
            // confirmation (00_common_architecture.md navigation rules).
            GoRoute(
              path: '/checkout/confirmation',
              builder: (c, s) {
                final extra = s.extra as Map<String, dynamic>?;
                return OrderConfirmationScreen(
                  orderId: extra?['orderId'] as String?,
                  total: extra?['total'] as int?,
                );
              },
            ),
          ]),
        ],
      ),
    ],
  );
});

/// Bridges a Stream (here, the auth StateNotifier's own change stream) into
/// the ChangeNotifier GoRouter expects for `refreshListenable`, so protected
/// routes re-evaluate immediately on login/logout instead of only on the
/// next navigation.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
