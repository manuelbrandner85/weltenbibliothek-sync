import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rating.dart';

/// Service for managing event ratings in Firestore
class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserName => _auth.currentUser?.displayName ?? 'Anonymer Benutzer';

  /// Add or update a rating for an event
  Future<void> rateEvent({
    required String eventId,
    required int stars,
  }) async {
    if (currentUserId == null) {
      throw Exception('Benutzer muss angemeldet sein um zu bewerten');
    }

    if (stars < 1 || stars > 5) {
      throw Exception('Bewertung muss zwischen 1 und 5 Sternen sein');
    }

    // Check if user already rated this event
    final existingRating = await _firestore
        .collection('ratings')
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: currentUserId)
        .limit(1)
        .get();

    if (existingRating.docs.isNotEmpty) {
      // Update existing rating
      await existingRating.docs.first.reference.update({
        'stars': stars,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Create new rating
      await _firestore.collection('ratings').add({
        'eventId': eventId,
        'userId': currentUserId!,
        'userName': currentUserName!,
        'stars': stars,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get user's rating for an event
  Future<int?> getUserRating(String eventId) async {
    if (currentUserId == null) return null;

    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return snapshot.docs.first.data()['stars'] as int?;
    } catch (e) {
      return null;
    }
  }

  /// Get rating statistics for an event (stream for real-time updates)
  Stream<RatingStats> getRatingStats(String eventId) {
    return _firestore
        .collection('ratings')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return RatingStats(
          averageRating: 0,
          totalRatings: 0,
          starDistribution: {},
        );
      }

      // Calculate statistics
      final ratings = snapshot.docs.map((doc) => doc.data()['stars'] as int).toList();
      final totalRatings = ratings.length;
      final sum = ratings.fold<int>(0, (prev, stars) => prev + stars);
      final averageRating = sum / totalRatings;

      // Calculate star distribution
      final Map<int, int> starDistribution = {};
      for (int i = 1; i <= 5; i++) {
        starDistribution[i] = ratings.where((s) => s == i).length;
      }

      return RatingStats(
        averageRating: averageRating,
        totalRatings: totalRatings,
        starDistribution: starDistribution,
      );
    });
  }

  /// Get all ratings for an event (for displaying list)
  Stream<List<Rating>> getRatingsForEvent(String eventId) {
    return _firestore
        .collection('ratings')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
      final ratings = snapshot.docs.map((doc) {
        final data = doc.data();
        return Rating(
          id: doc.id,
          eventId: data['eventId'] as String,
          userId: data['userId'] as String,
          userName: data['userName'] as String,
          stars: data['stars'] as int,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      // Sort by stars (highest first)
      ratings.sort((a, b) => b.stars.compareTo(a.stars));

      return ratings;
    });
  }

  /// Delete user's rating
  Future<void> deleteRating(String eventId) async {
    if (currentUserId == null) {
      throw Exception('Benutzer muss angemeldet sein');
    }

    final snapshot = await _firestore
        .collection('ratings')
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: currentUserId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    }
  }
}
