import 'package:flutter/material.dart';

import '../../data/models/review_summary.dart';

/// The 4 category "rings" on product detail (00_common_architecture.md §5a) --
/// live averages of each optional sub-rating across all reviews.
class RatingRings extends StatelessWidget {
  const RatingRings({super.key, required this.averages});

  final CategoryAverages averages;

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Quality', averages.quality),
      ('Value', averages.value),
      ('Packaging', averages.packaging),
      ('Accuracy', averages.accuracy),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: entries.map((e) => _Ring(label: e.$1, value: e.$2)).toList(),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: value != null ? scheme.primary : scheme.outlineVariant, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            value != null ? value!.toStringAsFixed(1) : '–',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}
