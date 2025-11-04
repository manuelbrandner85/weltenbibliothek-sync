class Rating {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final int stars; // 1-5
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.stars,
    required this.createdAt,
  });

  /// Validate star rating (1-5)
  bool get isValid => stars >= 1 && stars <= 5;
}

/// Aggregate rating statistics for an event
class RatingStats {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> starDistribution; // {1: 5, 2: 3, 3: 10, 4: 15, 5: 20}

  RatingStats({
    required this.averageRating,
    required this.totalRatings,
    required this.starDistribution,
  });

  /// Get percentage for a specific star rating
  double getPercentage(int stars) {
    if (totalRatings == 0) return 0;
    final count = starDistribution[stars] ?? 0;
    return (count / totalRatings) * 100;
  }

  /// Check if user can rate (has ratings)
  bool get hasRatings => totalRatings > 0;

  /// Format average rating for display
  String get formattedAverage => averageRating.toStringAsFixed(1);
}
