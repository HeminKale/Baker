import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../data/models/order_again_variant.dart';
import '../providers/order_again_providers.dart';
import '../widgets/group_tile.dart';

String _rupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

const _kMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String _formatLastOrdered(DateTime dt) => 'Last: ${dt.day} ${_kMonths[dt.month - 1]}';

/// `/order-again` (06_profile_and_account.md / Milestone 5 plan). A bottom
/// nav tab, so the route itself stays unprotected -- but both endpoints need
/// login (they're computed from the user's own order history), so guests see
/// an inline prompt instead of a redirect.
class OrderAgainScreen extends ConsumerWidget {
  const OrderAgainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider.select((s) => s.isLoggedIn));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Again')),
      body: isLoggedIn ? const _OrderAgainBody() : const _LoggedOutPrompt(),
    );
  }
}

class _LoggedOutPrompt extends StatelessWidget {
  const _LoggedOutPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.replay, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Log in to see items you\'ve ordered before', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.push('/login'), child: const Text('Log In')),
          ],
        ),
      ),
    );
  }
}

class _OrderAgainBody extends ConsumerWidget {
  const _OrderAgainBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frequentAsync = ref.watch(frequentlyBoughtProvider);
    final previousAsync = ref.watch(previouslyBoughtProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(frequentlyBoughtProvider);
        ref.invalidate(previouslyBoughtProvider);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Frequently Bought Together', style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          frequentAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Could not load: $e')),
            data: (groups) => groups.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Order 2+ items together twice and they\'ll show up here'),
                  )
                : SizedBox(
                    height: 210,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: groups.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => GroupTile(group: groups[index]),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Previously Bought', style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: previousAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Could not load: $e'),
              data: (items) =>
                  items.isEmpty ? const Text('No previous orders yet') : _PreviouslyBoughtSection(firstPage: items),
            ),
          ),
        ],
      ),
    );
  }
}

/// `previouslyBoughtProvider` only fetches page 1 -- this appends further
/// pages locally on "Load More" rather than adding pagination state to the
/// provider layer, since a plain widget list is enough to satisfy the Phase
/// 6 checkpoint ("Previously Bought paginated") without a second source of
/// truth for the same data.
class _PreviouslyBoughtSection extends ConsumerStatefulWidget {
  const _PreviouslyBoughtSection({required this.firstPage});

  final List<PreviouslyBoughtItem> firstPage;

  @override
  ConsumerState<_PreviouslyBoughtSection> createState() => _PreviouslyBoughtSectionState();
}

class _PreviouslyBoughtSectionState extends ConsumerState<_PreviouslyBoughtSection> {
  static const _limit = 20;
  final List<PreviouslyBoughtItem> _extraPages = [];
  int _nextPage = 2;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void didUpdateWidget(covariant _PreviouslyBoughtSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.firstPage != widget.firstPage) {
      // A pull-to-refresh reset page 1 -- drop any extra pages so the list
      // doesn't show stale items appended after a fresh first page.
      _extraPages.clear();
      _nextPage = 2;
      _hasMore = true;
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final items = await ref.read(orderAgainRepositoryProvider).getPreviouslyBought(page: _nextPage, limit: _limit);
      setState(() {
        _extraPages.addAll(items);
        _nextPage++;
        _hasMore = items.length == _limit;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load more: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [...widget.firstPage, ..._extraPages];
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.64,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _PreviousItemTile(item: items[index]),
        ),
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _loadingMore
                ? const CircularProgressIndicator()
                : OutlinedButton(onPressed: _loadMore, child: const Text('Load More')),
          ),
      ],
    );
  }
}

/// One tile in the Previously Bought grid -- "+ Add to Cart" adds one unit
/// via the regular single-item `cartProvider.addItem`; once it's in the
/// cart, the button becomes a +/- stepper (same interaction as the catalog
/// tile), rather than the mockup's static "+ Add to Cart" that never
/// reflects an already-added state.
class _PreviousItemTile extends ConsumerWidget {
  const _PreviousItemTile({required this.item});

  final PreviouslyBoughtItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = item.variant;
    final quantity = ref.watch(cartProvider.select((s) => s.quantityOf(variant.variantId)));

    void add() => ref.read(cartProvider.notifier).addItem(
          variantId: variant.variantId,
          productId: variant.productId,
          productName: variant.productName,
          variantName: variant.variantName,
          currentPrice: variant.currentPrice,
          originalPrice: variant.originalPrice,
          stockQty: variant.stockQty,
          imageUrl: variant.imageUrl,
        );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: variant.imageUrl != null
                ? CachedNetworkImage(imageUrl: variant.imageUrl!, fit: BoxFit.cover)
                : Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined)),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    variant.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    variant.variantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(_rupees(variant.currentPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    _formatLastOrdered(item.lastOrderedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: variant.isOutOfStock
                        ? const OutlinedButton(
                            onPressed: null,
                            child: Text('Out of Stock', style: TextStyle(fontSize: 11)),
                          )
                        : quantity == 0
                            ? FilledButton(
                                onPressed: add,
                                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                                child: const Text('+ Add to Cart', style: TextStyle(fontSize: 11)),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => ref.read(cartProvider.notifier).decrement(variant.variantId),
                                  ),
                                  Text('$quantity'),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.add),
                                    onPressed: add,
                                  ),
                                ],
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
