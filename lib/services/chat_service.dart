import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';

/// Chat Service für Firebase Realtime Chat
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String get currentUserName => _auth.currentUser?.displayName ?? 'Anonym';

  /// Stream aller Chat-Räume (OHNE Index-Anforderung)
  Stream<List<ChatRoom>> getChatRooms() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // GEÄNDERT: Nur where(), kein orderBy() → kein Index nötig!
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      // Sortierung im Code statt in Firestore
      final chatRooms = snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Nach lastActivity sortieren
      chatRooms.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      
      return chatRooms;
    });
  }

  /// Stream aller öffentlichen Community-Chats (OHNE Index-Anforderung)
  Stream<List<ChatRoom>> getCommunityChatRooms() {
    // GEÄNDERT: Nur where(), kein orderBy() → kein Index nötig!
    return _firestore
        .collection('chat_rooms')
        .where('type', isEqualTo: 'community')
        .snapshots()
        .map((snapshot) {
      // Sortierung im Code statt in Firestore
      final chatRooms = snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Nach lastActivity sortieren
      chatRooms.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      
      // Limit auf 20 im Code
      return chatRooms.take(20).toList();
    });
  }

  /// One-time fetch aller Chat-Räume (für Forward-Dialog)
  Future<List<ChatRoom>> getChatRoomsOnce() async {
    if (currentUserId == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('chat_rooms')
          .where('participants', arrayContains: currentUserId)
          .get();
      
      final chatRooms = snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc.data(), doc.id))
          .toList();
      
      chatRooms.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      
      return chatRooms;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden der Chat-Räume: $e');
      }
      return [];
    }
  }

  /// Stream von Nachrichten für einen Chat-Raum
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Nachricht senden
  Future<void> sendMessage({
    required String chatRoomId,
    required String text,
    MessageType type = MessageType.text,
    String? replyToMessageId,  // NEU Phase 5A
    String? replyToText,  // NEU Phase 5A
    String? replyToSenderName,  // NEU Phase 5A
  }) async {
    if (currentUserId == null || text.trim().isEmpty) return;

    try {
      final message = ChatMessage(
        id: '',
        chatRoomId: chatRoomId,
        senderId: currentUserId!,
        senderName: currentUserName,
        senderAvatar: _auth.currentUser?.photoURL ?? '',
        text: text.trim(),
        timestamp: DateTime.now(),
        type: type,
        replyToMessageId: replyToMessageId,  // NEU Phase 5A
        replyToText: replyToText,  // NEU Phase 5A
        replyToSenderName: replyToSenderName,  // NEU Phase 5A
      );

      // Nachricht speichern
      final docRef = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(message.toMap());

      // Chat-Raum aktualisieren
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'lastActivity': Timestamp.now(),
        'lastMessage': message.toMap(),
        'lastMessageId': docRef.id,
      });

      if (kDebugMode) {
        debugPrint('✅ Nachricht gesendet: $text');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Senden: $e');
      }
      rethrow;
    }
  }

  /// Reply auf eine Nachricht senden (Phase 5A)
  Future<void> sendReply({
    required String chatRoomId,
    required String text,
    required String replyToMessageId,
    required String replyToText,
    required String replyToSenderName,
  }) async {
    return sendMessage(
      chatRoomId: chatRoomId,
      text: text,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderName: replyToSenderName,
    );
  }

  /// Chat-Raum erstellen
  Future<String> createChatRoom({
    required String name,
    required String description,
    ChatRoomType type = ChatRoomType.community,
    List<String>? participants,
  }) async {
    if (currentUserId == null) {
      throw Exception('Nicht angemeldet');
    }

    try {
      final chatRoom = ChatRoom(
        id: '',
        name: name,
        description: description,
        participants: participants ?? [currentUserId!],
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        type: type,
      );

      final docRef = await _firestore
          .collection('chat_rooms')
          .add(chatRoom.toMap());

      if (kDebugMode) {
        debugPrint('✅ Chat-Raum erstellt: $name');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Erstellen: $e');
      }
      rethrow;
    }
  }

  /// Chat-Raum beitreten
  Future<void> joinChatRoom(String chatRoomId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'participants': FieldValue.arrayUnion([currentUserId!]),
      });

      if (kDebugMode) {
        debugPrint('✅ Chat-Raum beigetreten: $chatRoomId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Beitreten: $e');
      }
      rethrow;
    }
  }

  /// Nachrichten als gelesen markieren
  Future<void> markMessagesAsRead(String chatRoomId) async {
    if (currentUserId == null) return;

    try {
      final snapshot = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Markieren: $e');
      }
    }
  }

  /// Nachricht löschen (NEU - Phase 1)
  Future<void> deleteMessage({
    required String chatRoomId,
    required String messageId,
  }) async {
    if (currentUserId == null) return;

    try {
      // Hole Nachricht um Berechtigung zu prüfen
      final messageDoc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Nachricht nicht gefunden');
      }

      final message = ChatMessage.fromFirestore(messageDoc.data()!, messageDoc.id);

      // Prüfe ob User der Sender ist
      if (message.senderId != currentUserId) {
        throw Exception('Nur der Sender kann diese Nachricht löschen');
      }

      // Lösche die Nachricht
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();

      if (kDebugMode) {
        debugPrint('✅ Nachricht gelöscht: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Löschen: $e');
      }
      rethrow;
    }
  }

  /// Private 1:1 Chat erstellen oder finden (NEU - Phase 1)
  Future<String> getOrCreatePrivateChat(String otherUserId) async {
    if (currentUserId == null) {
      throw Exception('Nicht angemeldet');
    }

    if (otherUserId == currentUserId) {
      throw Exception('Kann keinen Chat mit sich selbst erstellen');
    }

    try {
      // Suche nach existierendem Private Chat
      final sortedIds = [currentUserId!, otherUserId]..sort();
      final privateChatId = 'private_${sortedIds[0]}_${sortedIds[1]}';

      final chatDoc = await _firestore
          .collection('chat_rooms')
          .doc(privateChatId)
          .get();

      if (chatDoc.exists) {
        if (kDebugMode) {
          debugPrint('✅ Existierender Private Chat gefunden: $privateChatId');
        }
        return privateChatId;
      }

      // Hole User-Daten des anderen Users
      final otherUserDoc = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();

      final otherUserName = otherUserDoc.exists
          ? (otherUserDoc.data()?['displayName'] ?? 'User')
          : 'User';

      // Erstelle neuen Private Chat
      final chatRoom = ChatRoom(
        id: privateChatId,
        name: otherUserName,
        description: 'Private Konversation',
        participants: [currentUserId!, otherUserId],
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        type: ChatRoomType.private,
        avatarUrl: otherUserDoc.data()?['photoURL'] ?? '',
      );

      await _firestore
          .collection('chat_rooms')
          .doc(privateChatId)
          .set(chatRoom.toMap());

      if (kDebugMode) {
        debugPrint('✅ Neuer Private Chat erstellt: $privateChatId');
      }

      return privateChatId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Private Chat: $e');
      }
      rethrow;
    }
  }

  /// Hole User-Daten für Profile (NEU - Phase 1)
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return null;
      }

      return userDoc.data();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden von User-Daten: $e');
      }
      return null;
    }
  }

  /// Stream von Private Chats (NEU - Phase 1)
  Stream<List<ChatRoom>> getPrivateChatRooms() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chat_rooms')
        .where('type', isEqualTo: 'private')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final chatRooms = snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc.data(), doc.id))
          .toList();

      // Nach lastActivity sortieren
      chatRooms.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

      return chatRooms;
    });
  }

  /// Initialisiere Standard-Chat-Räume
  Future<void> initializeDefaultChatRooms() async {
    try {
      // Prüfe ob Community-Chats existieren
      final snapshot = await _firestore
          .collection('chat_rooms')
          .where('type', isEqualTo: 'community')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // Erstelle Standard-Community-Chats
        await _createDefaultCommunityChats();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler bei Initialisierung: $e');
      }
    }
  }

  Future<void> _createDefaultCommunityChats() async {
    final defaultChats = [
      {
        'name': '🌍 Allgemeiner Chat',
        'description': 'Allgemeine Diskussionen über Mysterien und Verschwörungen',
        'avatarUrl': '',
      },
      {
        'name': '👽 UFO-Sichtungen',
        'description': 'Teile deine UFO-Sichtungen und Erfahrungen',
        'avatarUrl': '',
      },
      {
        'name': '🌊 Erdveränderungen',
        'description': 'Erdbeben, Vulkane und geologische Phänomene',
        'avatarUrl': '',
      },
      {
        'name': '⚡ Schumann-Resonanz',
        'description': 'Diskussionen über Erdfrequenzen und ihre Bedeutung',
        'avatarUrl': '',
      },
      {
        'name': '🔮 Esoterisches Wissen',
        'description': 'Spirituelle Themen und altes Wissen',
        'avatarUrl': '',
      },
    ];

    for (final chatData in defaultChats) {
      await createChatRoom(
        name: chatData['name']!,
        description: chatData['description']!,
        type: ChatRoomType.community,
        participants: [],
      );
    }

    if (kDebugMode) {
      debugPrint('✅ Standard-Community-Chats erstellt');
    }
  }

  // ========================================
  // PHASE 2: ERWEITERTE FEATURES
  // ========================================

  /// Bild hochladen zu Firebase Storage (NEU - Phase 2)
  Future<String> uploadImage(String filePath, String chatRoomId) async {
    if (currentUserId == null) {
      throw Exception('Nicht angemeldet');
    }

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${currentUserId}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(chatRoomId)
          .child(fileName);

      // Web-Unterstützung
      final file = File(filePath);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      if (kDebugMode) {
        debugPrint('✅ Bild hochgeladen: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Upload: $e');
      }
      rethrow;
    }
  }

  /// Nachricht mit Bild senden (NEU - Phase 2)
  Future<void> sendImageMessage({
    required String chatRoomId,
    required String imageUrl,
    String text = '',
  }) async {
    if (currentUserId == null) return;

    try {
      final message = ChatMessage(
        id: '',
        chatRoomId: chatRoomId,
        senderId: currentUserId!,
        senderName: currentUserName,
        senderAvatar: _auth.currentUser?.photoURL ?? '',
        text: text,
        timestamp: DateTime.now(),
        type: MessageType.image,
        imageUrl: imageUrl,
      );

      final docRef = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(message.toMap());

      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'lastActivity': Timestamp.now(),
        'lastMessage': message.toMap(),
        'lastMessageId': docRef.id,
      });

      if (kDebugMode) {
        debugPrint('✅ Bild-Nachricht gesendet');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Senden: $e');
      }
      rethrow;
    }
  }

  /// Reaction zu Nachricht hinzufügen/entfernen (NEU - Phase 2)
  Future<void> toggleReaction({
    required String chatRoomId,
    required String messageId,
    required String emoji,
  }) async {
    if (currentUserId == null) return;

    try {
      final messageRef = _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId);

      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) return;

      final message = ChatMessage.fromFirestore(messageDoc.data()!, messageDoc.id);
      final reactions = Map<String, List<String>>.from(message.reactions);

      // Toggle: User hinzufügen oder entfernen
      if (reactions[emoji]?.contains(currentUserId) ?? false) {
        reactions[emoji]!.remove(currentUserId);
        if (reactions[emoji]!.isEmpty) {
          reactions.remove(emoji);
        }
      } else {
        reactions[emoji] = [...(reactions[emoji] ?? []), currentUserId!];
      }

      await messageRef.update({'reactions': reactions});

      if (kDebugMode) {
        debugPrint('✅ Reaction aktualisiert: $emoji');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler bei Reaction: $e');
      }
      rethrow;
    }
  }

  /// Gruppen-Chat erstellen (NEU - Phase 2)
  Future<String> createGroupChat({
    required String name,
    required String description,
    required List<String> memberIds,
  }) async {
    if (currentUserId == null) {
      throw Exception('Nicht angemeldet');
    }

    try {
      // Creator ist automatisch Teilnehmer
      final participants = [currentUserId!, ...memberIds];

      final chatRoom = ChatRoom(
        id: '',
        name: name,
        description: description,
        participants: participants.toSet().toList(), // Duplikate entfernen
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        type: ChatRoomType.group,
      );

      final docRef = await _firestore
          .collection('chat_rooms')
          .add(chatRoom.toMap());

      // System-Nachricht: Gruppe erstellt
      await sendMessage(
        chatRoomId: docRef.id,
        text: '${currentUserName} hat die Gruppe "$name" erstellt.',
      );

      if (kDebugMode) {
        debugPrint('✅ Gruppen-Chat erstellt: $name');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Erstellen: $e');
      }
      rethrow;
    }
  }

  /// Stream von Gruppen-Chats (NEU - Phase 2)
  Stream<List<ChatRoom>> getGroupChatRooms() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chat_rooms')
        .where('type', isEqualTo: 'group')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final chatRooms = snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc.data(), doc.id))
          .toList();

      chatRooms.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

      return chatRooms;
    });
  }

  /// Stream für ungelesene Nachrichten Count (Badge)
  Stream<int> getUnreadMessagesCount() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = data['unreadCount_$currentUserId'] as int? ?? 0;
        totalUnread += unreadCount;
      }
      
      return totalUnread;
    });
  }

  /// Nachricht als gelesen markieren (Phase 5A - Read Receipts)
  Future<void> markMessageAsRead({
    required String chatRoomId,
    required String messageId,
  }) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([currentUserId!]),
      });

      if (kDebugMode) {
        debugPrint('✅ Nachricht als gelesen markiert: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Markieren als gelesen: $e');
      }
    }
  }

  /// Nachricht bearbeiten (Phase 5C)
  Future<void> editMessage({
    required String chatRoomId,
    required String messageId,
    required String newText,
  }) async {
    if (currentUserId == null || newText.trim().isEmpty) return;

    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'text': newText.trim(),
        'isEdited': true,
        'editedAt': Timestamp.now(),
      });

      if (kDebugMode) {
        debugPrint('✅ Nachricht bearbeitet: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Bearbeiten: $e');
      }
      rethrow;
    }
  }

  /// Nachricht anpinnen/entpinnen (Phase 5C)
  Future<void> togglePinMessage({
    required String chatRoomId,
    required String messageId,
    required bool isPinned,
  }) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'isPinned': isPinned});

      if (kDebugMode) {
        debugPrint('✅ Nachricht ${isPinned ? "angepinnt" : "entpinnt"}: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Pinnen: $e');
      }
      rethrow;
    }
  }

  /// Nachricht melden (Phase 5B)
  Future<void> reportMessage({
    required String chatRoomId,
    required String messageId,
    required String reason,
  }) async {
    if (currentUserId == null) return;

    try {
      // Nachricht als gemeldet markieren
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'isReported': true});

      // Report-Eintrag erstellen
      await _firestore.collection('reports').add({
        'chatRoomId': chatRoomId,
        'messageId': messageId,
        'reportedBy': currentUserId,
        'reason': reason,
        'timestamp': Timestamp.now(),
        'status': 'pending',
      });

      if (kDebugMode) {
        debugPrint('✅ Nachricht gemeldet: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Melden: $e');
      }
      rethrow;
    }
  }

  /// User blockieren (Phase 5B)
  Future<void> blockUser(String userId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([userId]),
      });

      if (kDebugMode) {
        debugPrint('✅ User blockiert: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Blockieren: $e');
      }
      rethrow;
    }
  }

  /// User entblocken (Phase 5B)
  Future<void> unblockUser(String userId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([userId]),
      });

      if (kDebugMode) {
        debugPrint('✅ User entblockt: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Entblocken: $e');
      }
      rethrow;
    }
  }

  /// Prüfe ob User blockiert ist (Phase 5B)
  Future<bool> isUserBlocked(String userId) async {
    if (currentUserId == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final blockedUsers = List<String>.from(userDoc.data()?['blockedUsers'] as List? ?? []);
      return blockedUsers.contains(userId);
    } catch (e) {
      return false;
    }
  }

  /// Nachricht weiterleiten (Phase 5C)
  Future<void> forwardMessage({
    required String targetChatRoomId,
    required ChatMessage originalMessage,
  }) async {
    if (currentUserId == null) return;

    try {
      final forwardedMessage = ChatMessage(
        id: '',
        chatRoomId: targetChatRoomId,
        senderId: currentUserId!,
        senderName: currentUserName,
        senderAvatar: _auth.currentUser?.photoURL ?? '',
        text: originalMessage.text,
        timestamp: DateTime.now(),
        type: originalMessage.type,
        imageUrl: originalMessage.imageUrl,
        audioUrl: originalMessage.audioUrl,
        audioDuration: originalMessage.audioDuration,
      );

      await _firestore
          .collection('chat_rooms')
          .doc(targetChatRoomId)
          .collection('messages')
          .add(forwardedMessage.toMap());

      // Update last activity
      await _firestore.collection('chat_rooms').doc(targetChatRoomId).update({
        'lastActivity': Timestamp.now(),
      });

      if (kDebugMode) {
        debugPrint('✅ Nachricht weitergeleitet');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Weiterleiten: $e');
      }
      rethrow;
    }
  }

  /// Suche Nachrichten (Phase 5A)
  Future<List<ChatMessage>> searchMessages({
    required String chatRoomId,
    required String query,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(500)
          .get();

      final allMessages = snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc.data(), doc.id))
          .toList();

      // Client-side search (case-insensitive)
      final searchQuery = query.toLowerCase();
      final results = allMessages.where((msg) {
        return msg.text.toLowerCase().contains(searchQuery) ||
               msg.senderName.toLowerCase().contains(searchQuery);
      }).toList();

      if (kDebugMode) {
        debugPrint('🔍 Gefunden: ${results.length} Nachrichten für "$query"');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler bei der Suche: $e');
      }
      return [];
    }
  }

  /// Hole angepinnte Nachrichten (Phase 5C)
  Stream<List<ChatMessage>> getPinnedMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('isPinned', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Prüfe ob User Admin/Moderator ist (Phase 5B)
  Future<bool> isUserModerator(String userId, String chatRoomId) async {
    try {
      final chatRoomDoc = await _firestore.collection('chat_rooms').doc(chatRoomId).get();
      final moderators = List<String>.from(chatRoomDoc.data()?['moderators'] as List? ?? []);
      final creator = chatRoomDoc.data()?['createdBy'] as String?;

      // Creator ist immer Moderator
      if (creator == userId) return true;

      // Prüfe Moderator-Liste
      return moderators.contains(userId);
    } catch (e) {
      return false;
    }
  }

  /// Füge Moderator hinzu (Phase 5B)
  Future<void> addModerator({
    required String chatRoomId,
    required String userId,
  }) async {
    if (currentUserId == null) return;

    // Nur Creator oder bestehende Moderatoren können neue Mods hinzufügen
    final isMod = await isUserModerator(currentUserId!, chatRoomId);
    if (!isMod) {
      throw Exception('Keine Berechtigung');
    }

    try {
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'moderators': FieldValue.arrayUnion([userId]),
      });

      if (kDebugMode) {
        debugPrint('✅ Moderator hinzugefügt: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Hinzufügen: $e');
      }
      rethrow;
    }
  }

  /// Entferne Moderator (Phase 5B)
  Future<void> removeModerator({
    required String chatRoomId,
    required String userId,
  }) async {
    if (currentUserId == null) return;

    final isMod = await isUserModerator(currentUserId!, chatRoomId);
    if (!isMod) {
      throw Exception('Keine Berechtigung');
    }

    try {
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'moderators': FieldValue.arrayRemove([userId]),
      });

      if (kDebugMode) {
        debugPrint('✅ Moderator entfernt: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Entfernen: $e');
      }
      rethrow;
    }
  }

  /// Moderator löscht fremde Nachricht (Phase 5B)
  Future<void> moderatorDeleteMessage({
    required String chatRoomId,
    required String messageId,
  }) async {
    if (currentUserId == null) return;

    // Prüfe Moderator-Rechte
    final isMod = await isUserModerator(currentUserId!, chatRoomId);
    if (!isMod) {
      throw Exception('Keine Berechtigung - nur Moderatoren können fremde Nachrichten löschen');
    }

    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();

      if (kDebugMode) {
        debugPrint('🛡️ Moderator hat Nachricht gelöscht: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Löschen: $e');
      }
      rethrow;
    }
  }

  /// Delete Chat Room (Ersteller only)
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      // Delete all messages first
      final messagesSnapshot = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .get();
      
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete typing indicators
      final typingSnapshot = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('typing')
          .get();
      
      for (var doc in typingSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete chat room itself
      await _firestore.collection('chat_rooms').doc(chatRoomId).delete();

      if (kDebugMode) {
        debugPrint('✅ Chat-Raum gelöscht: $chatRoomId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Löschen des Chat-Raums: $e');
      }
      rethrow;
    }
  }
}
