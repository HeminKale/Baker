class Review {
  const Review({
    required this.id,
    required this.overallRating,
    required this.createdAt,
    this.qualityRating,
    this.valueRating,
    this.packagingRating,
    this.accuracyRating,
    this.comment,
    this.tags = const [],
    this.userFullName,
  });

  final String id;
  final int overallRating;
  final int? qualityRating;
  final int? valueRating;
  final int? packagingRating;
  final int? accuracyRating;
  final String? comment;
  final List<String> tags;
  final DateTime createdAt;
  final String? userFullName;

  String get authorLabel {
    if (userFullName == null || userFullName!.trim().isEmpty) return 'Customer';
    final parts = userFullName!.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first;
    return '${parts.first} ${parts.last[0]}.';
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      overallRating: json['overallRating'] as int,
      qualityRating: json['qualityRating'] as int?,
      valueRating: json['valueRating'] as int?,
      packagingRating: json['packagingRating'] as int?,
      accuracyRating: json['accuracyRating'] as int?,
      comment: json['comment'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      userFullName: json['userFullName'] as String?,
    );
  }
}
