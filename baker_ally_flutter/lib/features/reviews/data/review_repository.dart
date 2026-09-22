import 'package:dio/dio.dart';

import 'models/review_eligibility.dart';
import 'models/review_summary.dart';

/// Reviews are product-detail-only, not Drift-cached -- mirrors product
/// detail's own "not cached" precedent (00_common_architecture.md §15).
class ReviewRepository {
  ReviewRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<ReviewSummary> getReviews(String productId, {int page = 1, int limit = 10}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/products/$productId/reviews',
      queryParameters: {'page': page, 'limit': limit},
    );
    return ReviewSummary.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<ReviewEligibility> getEligibility(String productId) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/products/$productId/reviews/eligibility');
    return ReviewEligibility.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> submitReview(
    String productId, {
    required int overallRating,
    int? qualityRating,
    int? valueRating,
    int? packagingRating,
    int? accuracyRating,
    String? comment,
    List<String>? tags,
  }) async {
    await _dio.post<void>(
      '/v1/products/$productId/reviews',
      data: {
        'overallRating': overallRating,
        if (qualityRating != null) 'qualityRating': qualityRating,
        if (valueRating != null) 'valueRating': valueRating,
        if (packagingRating != null) 'packagingRating': packagingRating,
        if (accuracyRating != null) 'accuracyRating': accuracyRating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      },
    );
  }
}
