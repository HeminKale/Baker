class ReviewEligibility {
  const ReviewEligibility({required this.canReview, this.reason});

  final bool canReview;
  final String? reason; // 'not_purchased' | 'not_delivered' | 'already_reviewed'

  factory ReviewEligibility.fromJson(Map<String, dynamic> json) {
    return ReviewEligibility(canReview: json['canReview'] as bool, reason: json['reason'] as String?);
  }
}
