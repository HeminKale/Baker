import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/login_required_sheet.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../providers/wishlist_provider.dart';

/// Appears on the product detail page and on catalog grid tiles (top-right of
/// the tile image, mirroring BadgeRow's top-left placement -- Milestone 6
/// plan §6.5, closing the gap where out-of-stock tiles had no way to
/// wishlist/notify-me from the grid). Optimistic toggle, login-gated.
class WishlistHeart extends ConsumerWidget {
  const WishlistHeart({
    super.key,
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.currentPrice,
    this.imageUrl,
  });

  final String variantId;
  final String productId;
  final String productName;
  final String variantName;
  final int currentPrice;
  final String? imageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInWishlist = ref.watch(wishlistIdsProvider).contains(variantId);

    return IconButton(
      icon: Icon(
        isInWishlist ? Icons.favorite : Icons.favorite_border,
        color: isInWishlist ? Colors.red : null,
      ),
      onPressed: () {
        if (!ref.read(authProvider).isLoggedIn) {
          showLoginRequiredSheet(context);
          return;
        }
        ref.read(wishlistIdsProvider.notifier).toggle(
              variantId: variantId,
              productId: productId,
              productName: productName,
              variantName: variantName,
              currentPrice: currentPrice,
              imageUrl: imageUrl,
            );
      },
    );
  }
}
