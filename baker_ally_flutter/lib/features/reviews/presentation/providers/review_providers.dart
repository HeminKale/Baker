import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/models/review_eligibility.dart';
import '../../data/models/review_summary.dart';
import '../../data/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(dio: ref.watch(dioProvider));
});

/// First page of reviews + the live-averaged summary (00_common_architecture.md
/// §5a). autoDispose so it refreshes rather than showing a stale count after
/// a new review is submitted elsewhere.
final productReviewsProvider = FutureProvider.autoDispose.family<ReviewSummary, String>((ref, productId) async {
  return ref.watch(reviewRepositoryProvider).getReviews(productId);
});

final reviewEligibilityProvider = FutureProvider.autoDispose.family<ReviewEligibility, String>((ref, productId) async {
  return ref.watch(reviewRepositoryProvider).getEligibility(productId);
});
