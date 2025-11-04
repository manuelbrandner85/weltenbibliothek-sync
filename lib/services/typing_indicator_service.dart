import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Typing Indicator Service - Zeigt an wenn User tippt (Phase 5A)
class TypingIndicatorService {
  static final TypingIndicatorService _instance = TypingIndicatorService._internal();
  factory TypingIndicatorService() => _instance;
  TypingIndicatorService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String get currentUserName => _auth.currentUser?.displayName ?? 'Anonym';

  /// Setze Typing-Status für einen Chat
  Future<void> setTyping(String chatRoomId, bool isTyping) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('typing')
          .doc(currentUserId)
          .set({
        'userId': currentUserId,
        'userName': currentUserName,
        'isTyping': isTyping,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Auto-remove nach 5 Sekunden wenn vergessen zu clearen
      if (isTyping) {
        Future.delayed(const Duration(seconds: 5), () {
          setTyping(chatRoomId, false);
        });
      }
    } catch (e) {
      // Silent fail - nicht kritisch
    }
  }

  /// Stream von tippenden Usern (außer current user)
  Stream<List<String>> getTypingUsers(String chatRoomId) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('typing')
        .where('isTyping', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final typingUsers = <String>[];
      
      for (var doc in snapshot.docs) {
        final userId = doc.data()['userId'] as String?;
        final userName = doc.data()['userName'] as String?;
        final timestamp = doc.data()['timestamp'] as Timestamp?;
        
        // Nur andere User, nicht sich selbst
        if (userId != currentUserId && userName != null) {
          // Prüfe ob timestamp nicht älter als 5 Sekunden
          if (timestamp != null) {
            final age = DateTime.now().difference(timestamp.toDate());
            if (age.inSeconds < 5) {
              typingUsers.add(userName);
            }
          }
        }
      }
      
      return typingUsers;
    });
  }

  /// Formatiere Typing-Anzeige Text
  String formatTypingText(List<String> typingUsers) {
    if (typingUsers.isEmpty) return '';
    
    if (typingUsers.length == 1) {
      return '${typingUsers.first} tippt...';
    } else if (typingUsers.length == 2) {
      return '${typingUsers[0]} und ${typingUsers[1]} tippen...';
    } else {
      return '${typingUsers.length} Personen tippen...';
    }
  }
}
