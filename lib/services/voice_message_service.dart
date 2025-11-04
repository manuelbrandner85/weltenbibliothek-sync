import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Voice Message Service - Audio Upload und Management (Phase 5A)
class VoiceMessageService {
  static final VoiceMessageService _instance = VoiceMessageService._internal();
  factory VoiceMessageService() => _instance;
  VoiceMessageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String get currentUserName => _auth.currentUser?.displayName ?? 'Anonym';

  /// Upload Audio-Datei zu Firebase Storage
  Future<String> uploadAudio(String filePath, String chatRoomId) async {
    try {
      final file = File(filePath);
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storageRef = _storage.ref().child('voice_messages/$chatRoomId/$fileName');

      if (kDebugMode) {
        debugPrint('📤 Uploading audio: $fileName');
      }

      // Upload file
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        debugPrint('✅ Audio uploaded: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Audio upload error: $e');
      }
      rethrow;
    }
  }

  /// Sende Voice Message
  Future<void> sendVoiceMessage({
    required String chatRoomId,
    required String audioUrl,
    required int duration,
  }) async {
    if (currentUserId == null) return;

    try {
      final message = {
        'chatRoomId': chatRoomId,
        'senderId': currentUserId,
        'senderName': currentUserName,
        'senderAvatar': _auth.currentUser?.photoURL ?? '',
        'text': '🎤 Sprachnachricht ($duration Sek.)',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'type': 'audio',
        'audioUrl': audioUrl,
        'audioDuration': duration,
        'reactions': {},
        'readBy': [],
        'isEdited': false,
        'isPinned': false,
        'isReported': false,
      };

      // Add message to Firestore
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(message);

      // Update last activity
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'lastActivity': Timestamp.now(),
        'lastMessage': '🎤 Sprachnachricht',
      });

      if (kDebugMode) {
        debugPrint('✅ Voice message sent: $duration seconds');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending voice message: $e');
      }
      rethrow;
    }
  }

  /// Format Audio-Dauer
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
