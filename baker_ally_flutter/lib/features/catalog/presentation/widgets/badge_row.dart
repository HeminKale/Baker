import 'package:flutter/material.dart';

import '../../data/models/product.dart';

/// Colour + label per Planning docs/Architecture/02_catalog_tab.md §5. Caller
/// is expected to have already applied the priority/max-2 rule via
/// `Product.badges`.
class BadgeRow extends StatelessWidget {
  const BadgeRow({super.key, required this.badges});

  final List<ProductBadge> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      children: badges.map((b) => _badgeChip(b)).toList(),
    );
  }

  Widget _badgeChip(ProductBadge badge) {
    final (label, color) = switch (badge) {
      ProductBadge.outOfStock => ('Out of Stock', Colors.red),
      ProductBadge.lowStock => ('Low Stock', Colors.orange),
      ProductBadge.sale => ('Sale', Colors.green),
      ProductBadge.trending => ('Trending', Colors.amber),
      ProductBadge.newArrival => ('New', Colors.blue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
