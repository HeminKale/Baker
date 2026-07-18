import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../wishlist/presentation/widgets/wishlist_heart.dart';
import '../../data/models/product.dart';
import '../../data/models/product_variant.dart';
import 'badge_row.dart';
import 'shimmer_box.dart';

/// One consistent tile design used by Level 2's grid (and, later, Home /
/// Order Again / Wishlist) -- Planning docs/Architecture/02_catalog_tab.md §5.
class ProductTile extends ConsumerWidget {
  const ProductTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = product.displayVariant;
    final quantity = variant == null
        ? 0
        : ref.watch(cartProvider.select((s) => s.quantityOf(variant.id)));

    // Tiles are fixed-size grid/row cells budgeted for the app's default text
    // metrics -- letting the device's accessibility font-scale setting grow
    // text beyond that (seen on some Android skins that ship a larger default
    // scale, e.g. Vivo/Funtouch) overflows the card whenever a name wraps to
    // 2 lines, on every screen that renders a tile. Clamp scaling here only;
    // regular screens elsewhere still respect the user's font size.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        child: Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (product.displayImageUrl != null)
                      CachedNetworkImage(
                        imageUrl: product.displayImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ShimmerBox(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.image_not_supported_outlined),
                      )
                    else
                      const Icon(Icons.image_not_supported_outlined),
                    if (product.badges.isNotEmpty)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: BadgeRow(badges: product.badges),
                      ),
                    if (variant != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: WishlistHeart(
                          variantId: variant.id,
                          productId: product.id,
                          productName: product.name,
                          variantName: variant.name,
                          currentPrice: variant.currentPrice,
                          imageUrl: product.displayImageUrl,
                        ),
                      ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (variant != null)
                        Text(
                          variant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      if (variant != null) const SizedBox(height: 2),
                      if (variant != null) _PriceRow(variant: variant),
                      if (variant != null) const SizedBox(height: 2),
                      if (variant != null)
                        _AddToCartControl(
                          product: product,
                          variant: variant,
                          quantity: quantity,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.variant});

  final ProductVariant variant;

  String _rupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    if (!variant.isOnSale) {
      return Text(
        _rupees(variant.currentPrice),
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }
    return Row(
      children: [
        Text(
          _rupees(variant.originalPrice),
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          _rupees(variant.currentPrice),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

/// Button <-> stepper transition, `AnimatedSwitcher` 150ms, matching the
/// interaction spec verbatim (02_catalog_tab.md §5 / Phase_Plan_Technical.md
/// Phase 3.5). Backed by the real server-synced `cartProvider` (Milestone 3).
class _AddToCartControl extends ConsumerWidget {
  const _AddToCartControl({
    required this.product,
    required this.variant,
    required this.quantity,
  });

  final Product product;
  final ProductVariant variant;
  final int quantity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const compactButtonStyle = ButtonStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
      minimumSize: WidgetStatePropertyAll(Size(0, 32)),
      textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
    );
    const compactIconConstraints = BoxConstraints(minWidth: 32, minHeight: 32);

    if (variant.isOutOfStock) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: compactButtonStyle,
          onPressed: null,
          child: const Text('Out of Stock'),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: quantity == 0
          ? SizedBox(
              key: const ValueKey('add'),
              width: double.infinity,
              child: FilledButton(
                style: compactButtonStyle,
                onPressed: () => addToCart(
                  context,
                  ref,
                  variant,
                  productId: product.id,
                  productName: product.name,
                  imageUrl: product.displayImageUrl,
                ),
                child: const Text('Add to Cart'),
              ),
            )
          : Row(
              key: const ValueKey('stepper'),
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  constraints: compactIconConstraints,
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onPressed: () =>
                      ref.read(cartProvider.notifier).decrement(variant.id),
                  icon: const Icon(Icons.remove),
                ),
                Text('$quantity'),
                IconButton(
                  constraints: compactIconConstraints,
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onPressed: () => addToCart(
                    context,
                    ref,
                    variant,
                    productId: product.id,
                    productName: product.name,
                    imageUrl: product.displayImageUrl,
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
    );
  }
}

/// Shared by the catalog tile and product detail's CTA -- adds one unit to the
/// real server-synced cart, caps at `variant.stockQty` and surfaces "Max stock
/// reached", per Planning docs/Architecture/05_cart_and_checkout.md §1
/// ("Tap + beyond stock_qty -> + button disabled, shows tooltip"). Works for
/// guests too (cart stays in Drift until login, then merges). Takes explicit
/// product fields (not a Product) so the product detail screen -- which has a
/// ProductDetail, not a Product -- can call it with the same helper.
void addToCart(
  BuildContext context,
  WidgetRef ref,
  ProductVariant variant, {
  required String productId,
  required String productName,
  String? imageUrl,
}) {
  final added = ref
      .read(cartProvider.notifier)
      .addItem(
        variantId: variant.id,
        productId: productId,
        productName: productName,
        variantName: variant.name,
        currentPrice: variant.currentPrice,
        originalPrice: variant.originalPrice,
        stockQty: variant.stockQty,
        imageUrl: imageUrl,
      );
  if (!added) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Max stock reached'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
