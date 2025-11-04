import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Presence Service - Online-Status Tracking (Phase 3)
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  bool _isInitialized = false;

  /// Initialisiere Online-Status Tracking
  Future<void> initialize() async {
    if (_isInitialized || currentUserId == null) return;

    try {
      // Setze User als online
      await setOnline();

      // Update bei App-Lifecycle Changes (wird automatisch aufgerufen)
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('✅ Presence Service initialisiert');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler bei Presence Init: $e');
      }
    }
  }

  /// Setze User als online
  Future<void> setOnline() async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).set({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('✅ User ist online');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Online-Setzen: $e');
      }
    }
  }

  /// Setze User als offline
  Future<void> setOffline() async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).set({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('✅ User ist offline');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Offline-Setzen: $e');
      }
    }
  }

  /// Stream für Online-Status eines Users
  Stream<bool> getUserOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      return snapshot.data()?['isOnline'] as bool? ?? false;
    });
  }

  /// Prüfe ob User online ist (einmalig)
  Future<bool> isUserOnline(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      return doc.data()?['isOnline'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Hole letzten Seen-Zeitpunkt
  Future<DateTime?> getLastSeen(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      final timestamp = doc.data()?['lastSeen'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      return null;
    }
  }

  /// Update Presence (für periodic refresh)
  Future<void> updatePresence() async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Presence Update: $e');
      }
    }
  }

  /// Cleanup beim App-Close
  Future<void> dispose() async {
    await setOffline();
    _isInitialized = false;
  }
}
