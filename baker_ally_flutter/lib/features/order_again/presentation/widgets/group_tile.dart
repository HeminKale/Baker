import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/providers/cart_providers.dart';
import '../../data/models/order_again_variant.dart';
import 'group_detail_sheet.dart';

String _rupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

/// Fixed-width card in the "Frequently Bought Together" horizontal scroll
/// (Phase_Plan_Business.md / Phase_Plan_Technical.md §5.4 mockup). "Add All
/// to Cart" is a one-tap shortcut that adds every item at qty 1 via the
/// batch endpoint; tapping elsewhere on the card opens [GroupDetailSheet]
/// for the per-item stepper / selective-add path the plan also calls for.
class GroupTile extends ConsumerStatefulWidget {
  const GroupTile({super.key, required this.group});

  final FrequentlyBoughtGroup group;

  @override
  ConsumerState<GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends ConsumerState<GroupTile> {
  bool _adding = false;

  int get _totalPrice => widget.group.items.fold(0, (sum, i) => sum + i.currentPrice);

  Future<void> _addAll() async {
    setState(() => _adding = true);
    try {
      final items = widget.group.items.map((i) => (variantId: i.variantId, quantity: 1)).toList();
      await ref.read(cartProvider.notifier).addBatch(items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add items: $e')));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final shown = group.items.take(2).toList();
    final extra = group.items.length - shown.length;

    return SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => GroupDetailSheet.show(context, group),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < shown.length; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(Icons.add, size: 14, color: Colors.grey),
                          ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _Thumb(url: shown[i].imageUrl),
                            if (i == shown.length - 1 && extra > 0)
                              Positioned(right: -6, top: -6, child: _ExtraBadge(count: extra)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _rupees(_totalPrice),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${group.items.length} items',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _adding ? null : _addAll,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                    child: _adding
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Add All to Cart', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExtraBadge extends StatelessWidget {
  const _ExtraBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
      child: Text('+$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
        image: url != null ? DecorationImage(image: CachedNetworkImageProvider(url!), fit: BoxFit.cover) : null,
      ),
      child: url == null ? const Icon(Icons.image_not_supported_outlined, size: 20, color: Colors.grey) : null,
    );
  }
}
