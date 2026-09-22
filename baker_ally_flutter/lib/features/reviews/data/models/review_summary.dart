import 'review.dart';

class CategoryAverages {
  const CategoryAverages({this.quality, this.value, this.packaging, this.accuracy});

  final double? quality;
  final double? value;
  final double? packaging;
  final double? accuracy;

  factory CategoryAverages.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    return CategoryAverages(
      quality: asDouble(json['quality']),
      value: asDouble(json['value']),
      packaging: asDouble(json['packaging']),
      accuracy: asDouble(json['accuracy']),
    );
  }
}

class ReviewSummary {
  const ReviewSummary({
    required this.overallRating,
    required this.reviewCount,
    required this.categoryAverages,
    required this.reviews,
  });

  final double overallRating;
  final int reviewCount;
  final CategoryAverages categoryAverages;
  final List<Review> reviews;

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    return ReviewSummary(
      overallRating: (summary['overallRating'] as num).toDouble(),
      reviewCount: summary['reviewCount'] as int,
      categoryAverages: CategoryAverages.fromJson(summary['categoryAverages'] as Map<String, dynamic>),
      reviews: (json['reviews'] as List).map((e) => Review.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
