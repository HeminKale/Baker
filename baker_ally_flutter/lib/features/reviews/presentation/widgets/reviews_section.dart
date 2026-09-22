import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../providers/review_providers.dart';
import 'add_review_sheet.dart';
import 'rating_rings.dart';
import 'review_card.dart';
import 'star_display.dart';

/// "Reviews & Ratings" -- below "You Might Also Like" on product detail
/// (00_common_architecture.md §5a). This page only owns the layout slot; the
/// actual list/eligibility/submit logic lives in `features/reviews/`.
class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(productReviewsProvider(productId));

    return summaryAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (summary) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reviews & Ratings', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (summary.reviewCount == 0)
              const Text('No reviews yet — be the first to review this product.')
            else ...[
              Row(
                children: [
                  Text(summary.overallRating.toStringAsFixed(1), style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(width: 8),
                  StarDisplay(rating: summary.overallRating),
                  const SizedBox(width: 8),
                  Text('${summary.reviewCount} reviews', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 12),
              RatingRings(averages: summary.categoryAverages),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: summary.reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ReviewCard(review: summary.reviews[index]),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _AddReviewButton(productId: productId),
          ],
        );
      },
    );
  }
}

class _AddReviewButton extends ConsumerWidget {
  const _AddReviewButton({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider.select((s) => s.isLoggedIn));
    if (!isLoggedIn) return const SizedBox.shrink();

    final eligibilityAsync = ref.watch(reviewEligibilityProvider(productId));
    return eligibilityAsync.maybeWhen(
      data: (eligibility) {
        if (!eligibility.canReview) return const SizedBox.shrink();
        return OutlinedButton(
          onPressed: () => AddReviewSheet.show(context, productId),
          child: const Text('Add Review'),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
