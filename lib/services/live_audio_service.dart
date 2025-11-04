import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Live Audio Chat Service
/// Manages live voice chat rooms with multiple participants
class LiveAudioService {
  static final LiveAudioService _instance = LiveAudioService._internal();
  factory LiveAudioService() => _instance;
  LiveAudioService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String get currentUserName => _auth.currentUser?.displayName ?? 'Unbekannt';

  /// Create Live Audio Room
  Future<String> createAudioRoom({
    required String name,
    required String description,
    int maxParticipants = 200, // ERHÖHT auf 200
  }) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    try {
      final roomDoc = await _firestore.collection('audio_rooms').add({
        'name': name,
        'description': description,
        'hostId': currentUserId,
        'hostName': currentUserName,
        'maxParticipants': maxParticipants,
        'activeParticipants': [currentUserId],
        'speakingUsers': <String>[],
        'mutedUsers': <String>[],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'startedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Audio Room created: ${roomDoc.id}');
      }

      return roomDoc.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating audio room: $e');
      }
      rethrow;
    }
  }

  /// Join Audio Room
  Future<void> joinAudioRoom(String roomId) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    try {
      await _firestore.collection('audio_rooms').doc(roomId).update({
        'activeParticipants': FieldValue.arrayUnion([currentUserId]),
      });

      // Add user to participants collection
      await _firestore
          .collection('audio_rooms')
          .doc(roomId)
          .collection('participants')
          .doc(currentUserId)
          .set({
        'userId': currentUserId,
        'userName': currentUserName,
        'joinedAt': FieldValue.serverTimestamp(),
        'isSpeaking': false,
        'isMuted': false,
        'isHandRaised': false,
      });

      if (kDebugMode) {
        debugPrint('✅ Joined audio room: $roomId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error joining audio room: $e');
      }
      rethrow;
    }
  }

  /// Leave Audio Room
  Future<void> leaveAudioRoom(String roomId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('audio_rooms').doc(roomId).update({
        'activeParticipants': FieldValue.arrayRemove([currentUserId]),
        'speakingUsers': FieldValue.arrayRemove([currentUserId]),
      });

      // Remove from participants
      await _firestore
          .collection('audio_rooms')
          .doc(roomId)
          .collection('participants')
          .doc(currentUserId)
          .delete();

      if (kDebugMode) {
        debugPrint('✅ Left audio room: $roomId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error leaving audio room: $e');
      }
    }
  }

  /// Toggle Speaking Status
  Future<void> toggleSpeaking(String roomId, bool isSpeaking) async {
    if (currentUserId == null) return;

    try {
      if (isSpeaking) {
        await _firestore.collection('audio_rooms').doc(roomId).update({
          'speakingUsers': FieldValue.arrayUnion([currentUserId]),
        });
      } else {
        await _firestore.collection('audio_rooms').doc(roomId).update({
          'speakingUsers': FieldValue.arrayRemove([currentUserId]),
        });
      }

      // Update participant status
      await _firestore
          .collection('audio_rooms')
          .doc(roomId)
          .collection('participants')
          .doc(currentUserId)
          .update({'isSpeaking': isSpeaking});

      if (kDebugMode) {
        debugPrint('✅ Speaking status: $isSpeaking');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error toggling speaking: $e');
      }
    }
  }

  /// Toggle Mute Status
  Future<void> toggleMute(String roomId, bool isMuted) async {
    if (currentUserId == null) return;

    try {
      if (isMuted) {
        await _firestore.collection('audio_rooms').doc(roomId).update({
          'mutedUsers': FieldValue.arrayUnion([currentUserId]),
          'speakingUsers': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        await _firestore.collection('audio_rooms').doc(roomId).update({
          'mutedUsers': FieldValue.arrayRemove([currentUserId]),
        });
      }

      // Update participant status
      await _firestore
          .collection('audio_rooms')
          .doc(roomId)
          .collection('participants')
          .doc(currentUserId)
          .update({'isMuted': isMuted, 'isSpeaking': false});

      if (kDebugMode) {
        debugPrint('✅ Mute status: $isMuted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error toggling mute: $e');
      }
    }
  }

  /// Raise Hand
  Future<void> raiseHand(String roomId, bool isRaised) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('audio_rooms')
          .doc(roomId)
          .collection('participants')
          .doc(currentUserId)
          .update({'isHandRaised': isRaised});

      if (kDebugMode) {
        debugPrint('✅ Hand raised: $isRaised');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error raising hand: $e');
      }
    }
  }

  /// Stream Active Audio Rooms
  Stream<List<Map<String, dynamic>>> getActiveAudioRooms() {
    return _firestore
        .collection('audio_rooms')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Stream Audio Room Details
  Stream<Map<String, dynamic>?> getAudioRoomStream(String roomId) {
    return _firestore
        .collection('audio_rooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      data?['id'] = snapshot.id;
      return data;
    });
  }

  /// Stream Room Participants
  Stream<List<Map<String, dynamic>>> getRoomParticipants(String roomId) {
    return _firestore
        .collection('audio_rooms')
        .doc(roomId)
        .collection('participants')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// End Audio Room (Host only)
  Future<void> endAudioRoom(String roomId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('audio_rooms').doc(roomId).update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Audio room ended: $roomId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error ending audio room: $e');
      }
    }
  }
}
