import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../wishlist/presentation/widgets/wishlist_heart.dart';
import '../../data/models/product_detail.dart';
import '../../data/models/product_image.dart';
import '../../data/models/product_variant.dart';
import '../providers/catalog_providers.dart';
import '../widgets/product_tile.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/variant_chip.dart';

/// Level 3 -- swipeable gallery, variant chips, pricing, description, related
/// products, fixed bottom CTA. Planning docs/Architecture/02_catalog_tab.md §4.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _selectedVariantId;
  int _galleryIndex = 0;
  final _galleryController = PageController();

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(title: Text(detailAsync.valueOrNull?.name ?? '')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load product: $error')),
        data: (detail) {
          final variant = _resolveSelectedVariant(detail);
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  _Gallery(
                    images: detail.images,
                    controller: _galleryController,
                    currentIndex: _galleryIndex,
                    onPageChanged: (i) => setState(() => _galleryIndex = i),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(detail.name, style: Theme.of(context).textTheme.headlineSmall),
                            ),
                            if (variant != null)
                              WishlistHeart(
                                variantId: variant.id,
                                productId: detail.id,
                                productName: detail.name,
                                variantName: variant.name,
                                currentPrice: variant.currentPrice,
                                imageUrl: detail.images.isNotEmpty ? detail.images.first.publicUrl : null,
                              ),
                          ],
                        ),
                        Text(
                          '${detail.categoryName} · ${detail.subCategoryName}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        if (variant != null) _PriceBlock(variant: variant),
                        const SizedBox(height: 16),
                        if (detail.variants.length > 1) ...[
                          Text('Select Variant', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: detail.variants
                                .map((v) => VariantChip(
                                      variant: v,
                                      selected: v.id == variant?.id,
                                      onTap: () => setState(() => _selectedVariantId = v.id),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (detail.description != null && detail.description!.isNotEmpty) ...[
                          Text('Description', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(detail.description!),
                          const SizedBox(height: 16),
                        ],
                        _RelatedProducts(productId: detail.id),
                      ],
                    ),
                  ),
                ],
              ),
              if (variant != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _AddToCartBar(variant: variant),
                ),
            ],
          );
        },
      ),
    );
  }

  ProductVariant? _resolveSelectedVariant(ProductDetail detail) {
    if (detail.variants.isEmpty) return null;
    if (_selectedVariantId != null) {
      final match = detail.variants.where((v) => v.id == _selectedVariantId);
      if (match.isNotEmpty) return match.first;
    }
    return detail.variants.first;
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.images,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<ProductImage> images;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const AspectRatio(aspectRatio: 1, child: Icon(Icons.image_not_supported_outlined, size: 64));
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: images.length,
            itemBuilder: (context, index) => CachedNetworkImage(
              imageUrl: images[index].publicUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const ShimmerBox(),
              errorWidget: (context, url, error) => const Icon(Icons.image_not_supported_outlined),
            ),
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == currentIndex
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.variant});

  final ProductVariant variant;

  String _rupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final percentOff = variant.isOnSale
        ? (100 - (variant.currentPrice * 100 / variant.originalPrice)).round()
        : 0;
    return Row(
      children: [
        if (variant.isOnSale)
          Text(
            _rupees(variant.originalPrice),
            style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
          ),
        if (variant.isOnSale) const SizedBox(width: 8),
        Text(
          _rupees(variant.currentPrice),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (variant.isOnSale) ...[
          const SizedBox(width: 8),
          Text('$percentOff% off', style: const TextStyle(color: Colors.green)),
        ],
      ],
    );
  }
}

class _RelatedProducts extends ConsumerWidget {
  const _RelatedProducts({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedAsync = ref.watch(relatedProductsProvider(productId));
    return relatedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
      data: (related) {
        if (related.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You Might Also Like', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) => SizedBox(width: 160, child: ProductTile(product: related[index])),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Idle -> stepper -> out-of-stock states, matching the catalog tile's
/// interaction (02_catalog_tab.md §4 "Fixed Bottom CTA").
class _AddToCartBar extends ConsumerWidget {
  const _AddToCartBar({required this.variant});

  final ProductVariant variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(localCartStubProvider.select((m) => m[variant.id] ?? 0));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: variant.isOutOfStock
            ? const SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: null, child: Text('Out of Stock')),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: quantity == 0
                    ? SizedBox(
                        key: const ValueKey('add'),
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => addToCartStub(context, ref, variant),
                          child: Text('+ Add to Cart · ₹${(variant.currentPrice / 100).toStringAsFixed(0)}'),
                        ),
                      )
                    : Row(
                        key: const ValueKey('stepper'),
                        children: [
                          IconButton(
                            onPressed: () => ref.read(localCartStubProvider.notifier).decrement(variant.id),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Expanded(child: Center(child: Text('$quantity'))),
                          IconButton(
                            onPressed: () => addToCartStub(context, ref, variant),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }
}
