class Comment {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;
  final List<String> likes;
  final int likeCount;

  Comment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
    required this.likes,
    required this.likeCount,
  });

  /// Check if current user has liked this comment
  bool isLikedBy(String userId) {
    return likes.contains(userId);
  }

  /// Format time ago string (e.g., "2 hours ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'vor $years ${years == 1 ? "Jahr" : "Jahren"}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'vor $months ${months == 1 ? "Monat" : "Monaten"}';
    } else if (difference.inDays > 0) {
      return 'vor ${difference.inDays} ${difference.inDays == 1 ? "Tag" : "Tagen"}';
    } else if (difference.inHours > 0) {
      return 'vor ${difference.inHours} ${difference.inHours == 1 ? "Stunde" : "Stunden"}';
    } else if (difference.inMinutes > 0) {
      return 'vor ${difference.inMinutes} ${difference.inMinutes == 1 ? "Minute" : "Minuten"}';
    } else {
      return 'gerade eben';
    }
  }
}
