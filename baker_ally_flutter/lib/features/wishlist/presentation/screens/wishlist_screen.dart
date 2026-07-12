import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/wishlist_item.dart';
import '../providers/wishlist_provider.dart';

/// `/wishlist` (06_profile_and_account.md Your Wishlist). Grid of saved
/// items; filled-heart tiles remove on tap. Filters the full-data
/// `wishlistItemsProvider` list against the live `wishlistIdsProvider` set so
/// a heart-tap removes the tile instantly without waiting on a re-fetch.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(wishlistItemsProvider);
    final ids = ref.watch(wishlistIdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Wishlist')),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load wishlist: $e')),
        data: (items) {
          final visible = items.where((i) => ids.contains(i.variantId)).toList();
          if (visible.isEmpty) {
            return const Center(child: Text('No saved items yet'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.62,
            ),
            itemCount: visible.length,
            itemBuilder: (context, index) => _WishlistTile(item: visible[index]),
          );
        },
      ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  const _WishlistTile({required this.item});

  final WishlistItem item;

  String _rupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/product/${item.productId}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.imageUrl != null)
                    CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover)
                  else
                    const Icon(Icons.image_not_supported_outlined),
                  Positioned(top: 4, right: 4, child: _RemoveHeartButton(item: item)),
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
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      item.variantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(_rupees(item.currentPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemoveHeartButton extends ConsumerWidget {
  const _RemoveHeartButton({required this.item});

  final WishlistItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
      child: IconButton(
        icon: const Icon(Icons.favorite, color: Colors.red),
        iconSize: 20,
        onPressed: () => ref.read(wishlistIdsProvider.notifier).toggle(
              variantId: item.variantId,
              productId: item.productId,
              productName: item.productName,
              variantName: item.variantName,
              currentPrice: item.currentPrice,
              imageUrl: item.imageUrl,
            ),
      ),
    );
  }
}
