import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/addresses/presentation/screens/address_form_screen.dart';
import '../../features/addresses/presentation/screens/address_list_screen.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/catalog/presentation/screens/product_detail_screen.dart';
import '../../features/catalog/presentation/screens/subcategory_products_screen.dart';
import '../../features/checkout/data/models/address.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/order_confirmation_screen.dart';
import '../../features/home/data/models/home_sections.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/home_section_screen.dart';
import '../../features/order_again/presentation/screens/order_again_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/order_history_screen.dart';
import '../../features/profile/presentation/screens/contact_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/help_screen.dart';
import '../../features/profile/presentation/screens/recipes_screen.dart';
import '../../features/receipts/presentation/screens/receipts_screen.dart';
import '../../features/wishlist/presentation/screens/wishlist_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/placeholder_screen.dart';

/// Guests can view the cart and add items freely (05_cart_and_checkout.md
/// §2/§3) -- login is gated at the checkout "Proceed" action, not on /cart
/// itself. Milestone 5 adds account/discovery screens here as they're built;
/// see 00_common_architecture.md line 192 for the full intended guard list.
const _protectedPaths = <String>['/profile/edit', '/addresses', '/wishlist', '/orders', '/receipts'];

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
      // Full-screen, outside the bottom-nav shell -- Profile Overlay pushes
      // here (06_profile_and_account.md: "a separate full screen, not nested
      // in the sheet").
      GoRoute(path: '/profile/edit', builder: (context, state) => const EditProfileScreen()),
      // Delivery Addresses -- pushed from the Profile Overlay menu, full
      // screens outside the bottom-nav shell (same treatment as
      // /profile/edit). /addresses/:id/edit gets its Address via `extra`
      // (list screen already has it from GET /addresses) since there's no
      // GET /addresses/:id.
      GoRoute(path: '/addresses', builder: (context, state) => const AddressListScreen()),
      GoRoute(path: '/addresses/new', builder: (context, state) => const AddressFormScreen()),
      GoRoute(
        path: '/addresses/:id/edit',
        builder: (context, state) => AddressFormScreen(existing: state.extra as Address?),
      ),
      GoRoute(path: '/wishlist', builder: (context, state) => const WishlistScreen()),
      // "Your Orders" and "Order Status" share this route -- the Profile
      // Overlay's Order Status tile pushes with extra {'status': 'active'}.
      GoRoute(
        path: '/orders',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OrderHistoryScreen(status: extra?['status'] as String?);
        },
      ),
      GoRoute(
        path: '/orders/:orderId',
        builder: (context, state) => OrderDetailScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(path: '/receipts', builder: (context, state) => const ReceiptsScreen()),
      // Generic support content -- unprotected (06_profile_and_account.md /
      // Milestone 5 plan: "/recipes, /contact, /help also unprotected").
      GoRoute(path: '/recipes', builder: (context, state) => const RecipesScreen()),
      GoRoute(path: '/contact', builder: (context, state) => const ContactScreen()),
      GoRoute(path: '/help', builder: (context, state) => const HelpScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
            // Sibling inside the Home branch so the bottom nav stays visible
            // on "See all" (same treatment as Catalog's Level 2/3 routes).
            GoRoute(
              path: '/home/section/:slug',
              builder: (c, s) =>
                  HomeSectionScreen(section: homeSectionFromSlug(s.pathParameters['slug']!)),
            ),
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
            GoRoute(path: '/order-again', builder: (c, s) => const OrderAgainScreen()),
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
                  paymentMethodLabel: extra?['paymentMethod'] as String?,
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
