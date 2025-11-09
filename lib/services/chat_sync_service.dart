import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// 🔄 CHAT SYNCHRONISATION SERVICE
/// 
/// Dieser Service verwaltet die bidirektionale Synchronisation zwischen
/// Flutter-App und Telegram-Chat über Firestore.
/// 
/// Features:
/// ✅ Nachrichten senden (App → Firestore → Telegram)
/// ✅ Nachrichten empfangen (Telegram → Firestore → App)
/// ✅ Nachrichten bearbeiten (bidirektional)
/// ✅ Nachrichten löschen (bidirektional)
/// ✅ Real-time Updates via Firestore Listener
/// ✅ Telegram-Benutzernamen anzeigen
/// ✅ Medien-Support (Bilder, Videos, Audio)

class ChatSyncService {
  static final ChatSyncService _instance = ChatSyncService._internal();
  factory ChatSyncService() => _instance;
  ChatSyncService._internal();

  // Firestore Collection
  static const String _collectionName = 'chat_messages';
  
  // Firestore Instanz
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream Controller für Chat-Updates
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  
  /// Initialisiert den Chat-Service und startet den Listener
  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('🔄 ChatSyncService: Initialisierung gestartet');
    }
    
    // Listener für neue/aktualisierte Nachrichten
    _startMessagesListener();
    
    if (kDebugMode) {
      debugPrint('✅ ChatSyncService: Bereit für bidirektionale Synchronisation');
    }
  }
  
  /// Startet den Firestore Listener für Chat-Nachrichten
  void _startMessagesListener() {
    _messagesSubscription = _firestore
        .collection(_collectionName)
        .where('deleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
      if (kDebugMode) {
        debugPrint('🔄 ChatSyncService: ${snapshot.docs.length} Nachrichten empfangen');
      }
      
      // Stream-Updates werden automatisch an UI weitergeleitet
      // (Durch getMessagesStream())
    }, onError: (error) {
      if (kDebugMode) {
        debugPrint('❌ ChatSyncService Listener Fehler: $error');
      }
    });
  }
  
  /// Gibt einen Stream aller Chat-Nachrichten zurück (für UI-Binding)
  Stream<List<ChatMessage>> getMessagesStream() {
    return _firestore
        .collection(_collectionName)
        .where('deleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }
  
  /// Sendet eine neue Nachricht (App → Firestore → Telegram)
  Future<void> sendMessage({
    required String text,
    String? replyToId,
    String? mediaUrl,
    String? mediaType,
    required String currentUserId,
    required String currentUsername,
  }) async {
    try {
      // Firestore-Dokument erstellen
      final docRef = _firestore.collection(_collectionName).doc();
      
      final messageData = {
        'messageId': docRef.id,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'source': 'app',  // Von Flutter-App
        'edited': false,
        'deleted': false,
        'syncedToTelegram': false,  // Wird vom Python-Daemon auf true gesetzt
        'replyToId': replyToId,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        
        // App-Benutzer-Info (anstatt Telegram-User)
        'appUserId': currentUserId,
        'appUsername': currentUsername,
        
        // Telegram-User-Info (wird nach Sync gefüllt)
        'telegramUserId': null,
        'telegramUsername': null,
        'telegramMessageId': null,
      };
      
      await docRef.set(messageData);
      
      if (kDebugMode) {
        debugPrint('✅ Nachricht gesendet (App → Firestore): ${docRef.id}');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Senden der Nachricht: $e');
      }
      rethrow;
    }
  }
  
  /// Bearbeitet eine vorhandene Nachricht (App → Firestore → Telegram)
  Future<void> editMessage({
    required String messageId,
    required String newText,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(messageId).update({
        'text': newText,
        'edited': true,
        'editedAt': FieldValue.serverTimestamp(),
        'editSyncedToTelegram': false,  // Trigger für Python-Daemon
      });
      
      if (kDebugMode) {
        debugPrint('✅ Nachricht bearbeitet (App → Firestore): $messageId');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Bearbeiten der Nachricht: $e');
      }
      rethrow;
    }
  }
  
  /// Löscht eine Nachricht (App → Firestore → Telegram)
  Future<void> deleteMessage({
    required String messageId,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(messageId).update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deleteSyncedToTelegram': false,  // Trigger für Python-Daemon
      });
      
      if (kDebugMode) {
        debugPrint('✅ Nachricht gelöscht (App → Firestore): $messageId');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Löschen der Nachricht: $e');
      }
      rethrow;
    }
  }
  
  /// Lädt eine einzelne Nachricht nach ID
  Future<ChatMessage?> getMessage(String messageId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(messageId).get();
      
      if (!doc.exists) return null;
      
      return ChatMessage.fromFirestore(doc.data()!, doc.id);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden der Nachricht: $e');
      }
      return null;
    }
  }
  
  /// Stoppt den Service und räumt Ressourcen auf
  Future<void> dispose() async {
    await _messagesSubscription?.cancel();
    
    if (kDebugMode) {
      debugPrint('🛑 ChatSyncService gestoppt');
    }
  }
}

/// 💬 CHAT MESSAGE MODEL
/// 
/// Repräsentiert eine Chat-Nachricht mit allen Metadaten
class ChatMessage {
  final String messageId;
  final String text;
  final DateTime? timestamp;
  final String source;  // "telegram" oder "app"
  final bool edited;
  final bool deleted;
  
  // Telegram-Benutzer (falls von Telegram)
  final String? telegramUserId;
  final String? telegramUsername;
  final String? telegramFirstName;
  final String? telegramLastName;
  
  // App-Benutzer (falls von App)
  final String? appUserId;
  final String? appUsername;
  
  // Medien
  final String? mediaUrl;
  final String? mediaType;
  
  // Reply
  final String? replyToId;
  
  // Sync-Status
  final bool? syncedToTelegram;
  final DateTime? syncedAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  
  ChatMessage({
    required this.messageId,
    required this.text,
    this.timestamp,
    required this.source,
    required this.edited,
    required this.deleted,
    this.telegramUserId,
    this.telegramUsername,
    this.telegramFirstName,
    this.telegramLastName,
    this.appUserId,
    this.appUsername,
    this.mediaUrl,
    this.mediaType,
    this.replyToId,
    this.syncedToTelegram,
    this.syncedAt,
    this.editedAt,
    this.deletedAt,
  });
  
  /// Erstellt eine ChatMessage aus Firestore-Daten
  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatMessage(
      messageId: id,
      text: data['text'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      source: data['source'] as String? ?? 'unknown',
      edited: data['edited'] as bool? ?? false,
      deleted: data['deleted'] as bool? ?? false,
      
      // Telegram-User
      telegramUserId: data['telegramUserId'] as String?,
      telegramUsername: data['telegramUsername'] as String?,
      telegramFirstName: data['telegramFirstName'] as String?,
      telegramLastName: data['telegramLastName'] as String?,
      
      // App-User
      appUserId: data['appUserId'] as String?,
      appUsername: data['appUsername'] as String?,
      
      // Medien
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String?,
      
      // Reply
      replyToId: data['replyToId'] as String?,
      
      // Sync-Status
      syncedToTelegram: data['syncedToTelegram'] as bool?,
      syncedAt: (data['syncedAt'] as Timestamp?)?.toDate(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
    );
  }
  
  /// Gibt den Anzeigenamen des Absenders zurück
  String get displayName {
    if (source == 'telegram') {
      // Telegram-Benutzer
      if (telegramUsername != null) return '@$telegramUsername';
      if (telegramFirstName != null) {
        return telegramLastName != null 
            ? '$telegramFirstName $telegramLastName' 
            : telegramFirstName!;
      }
      return 'Telegram User $telegramUserId';
    } else {
      // App-Benutzer
      return appUsername ?? 'App User $appUserId';
    }
  }
  
  /// Gibt einen kurzen Anzeigenamen zurück
  String get shortName {
    if (source == 'telegram') {
      return telegramUsername ?? telegramFirstName ?? 'User';
    } else {
      return appUsername ?? 'You';
    }
  }
  
  /// Prüft ob die Nachricht Medien enthält
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
  
  /// Gibt eine kopierte Version mit geänderten Werten zurück
  ChatMessage copyWith({
    String? text,
    bool? edited,
    bool? deleted,
    String? mediaUrl,
    String? mediaType,
  }) {
    return ChatMessage(
      messageId: messageId,
      text: text ?? this.text,
      timestamp: timestamp,
      source: source,
      edited: edited ?? this.edited,
      deleted: deleted ?? this.deleted,
      telegramUserId: telegramUserId,
      telegramUsername: telegramUsername,
      telegramFirstName: telegramFirstName,
      telegramLastName: telegramLastName,
      appUserId: appUserId,
      appUsername: appUsername,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      replyToId: replyToId,
      syncedToTelegram: syncedToTelegram,
      syncedAt: syncedAt,
      editedAt: editedAt,
      deletedAt: deletedAt,
    );
  }
}
