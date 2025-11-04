import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// User Profile and Favorites Service
/// Manages user data, settings, and favorites in Firestore
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUserId == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Update user display name
  Future<void> updateDisplayName(String displayName) async {
    if (currentUserId == null) return;
    
    await _firestore.collection('users').doc(currentUserId).update({
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await _auth.currentUser?.updateDisplayName(displayName);
  }

  /// Update user settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    if (currentUserId == null) return;
    
    await _firestore.collection('users').doc(currentUserId).update({
      'settings': settings,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add event to favorites
  Future<void> addFavorite(String eventId) async {
    if (currentUserId == null) return;
    
    await _firestore.collection('users').doc(currentUserId).update({
      'favorites': FieldValue.arrayUnion([eventId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove event from favorites
  Future<void> removeFavorite(String eventId) async {
    if (currentUserId == null) return;
    
    await _firestore.collection('users').doc(currentUserId).update({
      'favorites': FieldValue.arrayRemove([eventId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if event is favorited
  Future<bool> isFavorite(String eventId) async {
    if (currentUserId == null) return false;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      final data = doc.data();
      final favorites = List<String>.from(data?['favorites'] ?? []);
      return favorites.contains(eventId);
    } catch (e) {
      return false;
    }
  }

  /// Get all user favorites
  Future<List<String>> getFavorites() async {
    if (currentUserId == null) return [];
    
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      final data = doc.data();
      return List<String>.from(data?['favorites'] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Stream of user favorites (real-time updates)
  Stream<List<String>> favoritesStream() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      return List<String>.from(data?['favorites'] ?? []);
    });
  }

  /// Get favorites count
  Future<int> getFavoritesCount() async {
    final favorites = await getFavorites();
    return favorites.length;
  }
}
