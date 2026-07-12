import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/cart/presentation/providers/cart_providers.dart';
import '../../features/checkout/presentation/providers/checkout_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/profile/presentation/widgets/profile_overlay_sheet.dart';

/// Global bottom-nav shell -- 00_common_architecture.md §2. The bottom nav
/// bar never disappears across the 5 tabs; sub-screens added in later
/// milestones (product detail, cart, etc.) still render inside this shell.
/// Milestone 5 adds the top bar (avatar -> Profile Overlay) here too -- it's
/// foundational shell infrastructure with no other entry point, and no
/// notification bell (that needs Phase 4's `notifications` table).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _baseDestinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view),
      label: 'Catalog',
    ),
    NavigationDestination(
      icon: Icon(Icons.replay_outlined),
      selectedIcon: Icon(Icons.replay),
      label: 'Order Again',
    ),
    NavigationDestination(
      icon: Icon(Icons.cookie_outlined),
      selectedIcon: Icon(Icons.cookie),
      label: 'Brownie Points',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider.select((s) => s.totalItems));

    final destinations = [
      ..._baseDestinations,
      NavigationDestination(
        icon: _CartIcon(count: cartCount, selected: false),
        selectedIcon: _CartIcon(count: cartCount, selected: true),
        label: 'Cart',
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          const SafeArea(bottom: false, child: _TopBar()),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: destinations,
      ),
    );
  }
}

/// Best-effort default-address label + avatar button. Not a fully wired
/// global address switcher this milestone (Milestone 5 plan §Scope
/// decisions) -- just shows the current default so the top bar isn't blank.
class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider.select((s) => s.isLoggedIn));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Expanded(child: _DefaultAddressLabel()),
          _AvatarButton(isLoggedIn: isLoggedIn),
        ],
      ),
    );
  }
}

class _DefaultAddressLabel extends ConsumerWidget {
  const _DefaultAddressLabel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider.select((s) => s.isLoggedIn));
    if (!isLoggedIn) return const SizedBox.shrink();

    final addressesAsync = ref.watch(addressesProvider);
    return addressesAsync.maybeWhen(
      data: (addresses) {
        if (addresses.isEmpty) return const SizedBox.shrink();
        final def = addresses.where((a) => a.isDefault);
        final address = def.isNotEmpty ? def.first : addresses.first;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(address.shortLine, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _AvatarButton extends ConsumerWidget {
  const _AvatarButton({required this.isLoggedIn});

  final bool isLoggedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isLoggedIn) {
      return IconButton(
        onPressed: () => context.push('/login'),
        icon: const CircleAvatar(radius: 16, child: Icon(Icons.person_outline, size: 18)),
      );
    }

    final profileAsync = ref.watch(profileProvider);
    return IconButton(
      onPressed: () => ProfileOverlaySheet.show(context),
      icon: profileAsync.maybeWhen(
        data: (profile) => CircleAvatar(
          radius: 16,
          backgroundImage: profile.avatarUrl != null ? CachedNetworkImageProvider(profile.avatarUrl!) : null,
          child: profile.avatarUrl == null ? Text(profile.initials, style: const TextStyle(fontSize: 12)) : null,
        ),
        orElse: () => const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
      ),
    );
  }
}

class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(selected ? Icons.shopping_cart : Icons.shopping_cart_outlined),
        if (count > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
