import 'package:flutter/material.dart';

import '../../data/models/product_variant.dart';

/// Out-of-stock variant: shown but greyed out with strikethrough, not
/// selectable (Planning docs/Architecture/02_catalog_tab.md §4).
class VariantChip extends StatelessWidget {
  const VariantChip({
    super.key,
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final ProductVariant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = variant.isOutOfStock;

    return ChoiceChip(
      label: Text(
        variant.name,
        style: disabled ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
      ),
      selected: selected && !disabled,
      onSelected: disabled ? null : (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      disabledColor: theme.colorScheme.surfaceContainerHighest,
    );
  }
}
