import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/data/models/cart_item.dart';
import '../../../cart/presentation/providers/cart_providers.dart';

/// One row in the checkout items list (05_cart_and_checkout.md §4). Inline
/// stepper drives cartProvider directly; qty 0 removes the line.
class CartItemRow extends ConsumerWidget {
  const CartItemRow({super.key, required this.item});

  final CartItem item;

  String _rupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    final atMax = item.quantity >= item.stockQty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) => const Icon(Icons.image_not_supported_outlined),
                    )
                  : const Icon(Icons.image_not_supported_outlined),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(item.variantName,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item.isOnSale) ...[
                      Text(_rupees(item.originalPrice),
                          style: const TextStyle(
                              decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 6),
                    ],
                    Text(_rupees(item.currentPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Stepper(
            quantity: item.quantity,
            atMax: atMax,
            onDecrement: () => notifier.decrement(item.variantId),
            onIncrement: atMax ? null : () => notifier.setQuantity(item.variantId, item.quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.quantity,
    required this.atMax,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final bool atMax;
  final VoidCallback onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDecrement,
            icon: const Icon(Icons.remove, size: 18),
          ),
          Text('$quantity'),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onIncrement,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}
