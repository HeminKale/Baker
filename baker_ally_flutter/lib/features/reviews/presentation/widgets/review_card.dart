import 'package:flutter/material.dart';

import '../../data/models/review.dart';
import 'star_display.dart';

/// One review card, horizontal-scroll row (same card pattern as product
/// tiles -- 00_common_architecture.md §5a).
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final Review review;

  String _relativeTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays >= 60) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays >= 30) return '1 month ago';
    if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return 'Today';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 14, child: Text(review.authorLabel.isNotEmpty ? review.authorLabel[0] : '?')),
              const SizedBox(width: 8),
              Expanded(
                child: Text(review.authorLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              StarDisplay(rating: review.overallRating.toDouble(), size: 12),
            ],
          ),
          const SizedBox(height: 2),
          Text(_relativeTime(review.createdAt), style: Theme.of(context).textTheme.bodySmall),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Expanded(
              child: Text(review.comment!, maxLines: 4, overflow: TextOverflow.ellipsis),
            ),
          ],
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: review.tags
                  .map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
