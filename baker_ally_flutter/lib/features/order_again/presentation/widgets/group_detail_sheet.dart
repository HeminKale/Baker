import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/providers/cart_providers.dart';
import '../../data/models/order_again_variant.dart';

String _rupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

/// Bottom sheet opened from [GroupTile] -- per-item checkbox + stepper, then
/// "Add Selected Items to Cart" batches everything checked into one
/// `POST /cart/items/batch` call via `cartProvider.addBatch`.
class GroupDetailSheet extends ConsumerStatefulWidget {
  const GroupDetailSheet({super.key, required this.group});

  final FrequentlyBoughtGroup group;

  static Future<void> show(BuildContext context, FrequentlyBoughtGroup group) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GroupDetailSheet(group: group),
    );
  }

  @override
  ConsumerState<GroupDetailSheet> createState() => _GroupDetailSheetState();
}

class _GroupDetailSheetState extends ConsumerState<GroupDetailSheet> {
  late final Map<String, int> _quantities = {
    for (final item in widget.group.items)
      if (!item.isOutOfStock) item.variantId: 1,
  };
  bool _adding = false;

  Future<void> _addSelected() async {
    final items = _quantities.entries
        .where((e) => e.value > 0)
        .map((e) => (variantId: e.key, quantity: e.value))
        .toList();
    if (items.isEmpty) return;

    setState(() => _adding = true);
    try {
      await ref.read(cartProvider.notifier).addBatch(items);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _adding = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add items: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _quantities.values.where((q) => q > 0).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ordered together ${widget.group.orderCount}×', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.group.items.length,
                itemBuilder: (context, index) {
                  final item = widget.group.items[index];
                  return _GroupItemRow(
                    item: item,
                    quantity: _quantities[item.variantId] ?? 0,
                    onChanged: (qty) => setState(() => _quantities[item.variantId] = qty),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_adding || selectedCount == 0) ? null : _addSelected,
                    child: _adding
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Add Selected Items to Cart ($selectedCount)'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GroupItemRow extends StatelessWidget {
  const _GroupItemRow({required this.item, required this.quantity, required this.onChanged});

  final OrderAgainVariant item;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;
    return Opacity(
      opacity: item.isOutOfStock ? 0.5 : 1,
      child: ListTile(
        leading: Checkbox(
          value: selected,
          onChanged: item.isOutOfStock ? null : (v) => onChanged(v == true ? 1 : 0),
        ),
        title: Text(item.productName),
        subtitle: Text(
          item.isOutOfStock ? 'Out of stock' : '${item.variantName} · ${_rupees(item.currentPrice)}',
        ),
        trailing: selected && !item.isOutOfStock
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
                  ),
                  Text('$quantity'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: quantity < item.stockQty ? () => onChanged(quantity + 1) : null,
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
