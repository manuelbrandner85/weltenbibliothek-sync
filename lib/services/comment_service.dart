import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment.dart';

/// Service for managing event comments in Firestore
class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserName => _auth.currentUser?.displayName ?? 'Anonymer Benutzer';

  /// Add a comment to an event
  Future<void> addComment({
    required String eventId,
    required String text,
  }) async {
    if (currentUserId == null) {
      throw Exception('Benutzer muss angemeldet sein um zu kommentieren');
    }

    if (text.trim().isEmpty) {
      throw Exception('Kommentar darf nicht leer sein');
    }

    await _firestore.collection('comments').add({
      'eventId': eventId,
      'userId': currentUserId!,
      'userName': currentUserName!,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'likes': [],
      'likeCount': 0,
    });
  }

  /// Get comments for a specific event (real-time stream)
  Stream<List<Comment>> getCommentsForEvent(String eventId) {
    return _firestore
        .collection('comments')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
      // Convert documents to Comment objects
      final comments = snapshot.docs.map((doc) {
        final data = doc.data();
        return Comment(
          id: doc.id,
          eventId: data['eventId'] as String,
          userId: data['userId'] as String,
          userName: data['userName'] as String,
          text: data['text'] as String,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          likes: List<String>.from(data['likes'] ?? []),
          likeCount: data['likeCount'] as int? ?? 0,
        );
      }).toList();
      
      // Sort in memory (no index required)
      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return comments;
    });
  }

  /// Like a comment
  Future<void> likeComment(String commentId) async {
    if (currentUserId == null) return;

    final commentRef = _firestore.collection('comments').doc(commentId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(commentRef);
      
      if (!snapshot.exists) return;

      final likes = List<String>.from(snapshot.data()?['likes'] ?? []);
      
      if (!likes.contains(currentUserId)) {
        likes.add(currentUserId!);
        transaction.update(commentRef, {
          'likes': likes,
          'likeCount': likes.length,
        });
      }
    });
  }

  /// Unlike a comment
  Future<void> unlikeComment(String commentId) async {
    if (currentUserId == null) return;

    final commentRef = _firestore.collection('comments').doc(commentId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(commentRef);
      
      if (!snapshot.exists) return;

      final likes = List<String>.from(snapshot.data()?['likes'] ?? []);
      
      if (likes.contains(currentUserId)) {
        likes.remove(currentUserId);
        transaction.update(commentRef, {
          'likes': likes,
          'likeCount': likes.length,
        });
      }
    });
  }

  /// Delete a comment (only by author)
  Future<void> deleteComment(String commentId, String commentUserId) async {
    if (currentUserId == null) {
      throw Exception('Benutzer muss angemeldet sein');
    }

    if (currentUserId != commentUserId) {
      throw Exception('Nur der Autor kann seinen Kommentar löschen');
    }

    await _firestore.collection('comments').doc(commentId).delete();
  }

  /// Get comment count for an event
  Future<int> getCommentCount(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('comments')
          .where('eventId', isEqualTo: eventId)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
