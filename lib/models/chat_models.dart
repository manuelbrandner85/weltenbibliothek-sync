import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat Message Model
class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? imageUrl;  // Bild-URL (Phase 2)
  final Map<String, List<String>> reactions;  // Reactions {emoji: [userIds]} (Phase 2)
  
  // Reply/Quote Feature (Phase 5A)
  final String? replyToMessageId;  // ID der Nachricht auf die geantwortet wird
  final String? replyToText;  // Text der Original-Nachricht
  final String? replyToSenderName;  // Name des Original-Senders
  
  // Read Receipts (Phase 5A)
  final List<String> readBy;  // User-IDs die Nachricht gelesen haben
  final bool isEdited;  // Nachricht wurde bearbeitet (Phase 5C)
  
  // Voice Messages (Phase 5A)
  final String? audioUrl;  // Audio-Datei URL
  final int? audioDuration;  // Audio-Länge in Sekunden
  
  // Message Status (Phase 5B/5C)
  final bool isPinned;  // Nachricht ist angepinnt (Phase 5C)
  final bool isReported;  // Nachricht wurde gemeldet (Phase 5B)
  final DateTime? editedAt;  // Zeitpunkt der letzten Bearbeitung (Phase 5C)

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.imageUrl,
    this.reactions = const {},
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderName,
    this.readBy = const [],
    this.isEdited = false,
    this.audioUrl,  // Phase 5A
    this.audioDuration,  // Phase 5A
    this.isPinned = false,  // Phase 5C
    this.isReported = false,  // Phase 5B
    this.editedAt,  // Phase 5C
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String id) {
    // Parse reactions
    final reactionsData = data['reactions'] as Map<String, dynamic>? ?? {};
    final reactions = <String, List<String>>{};
    reactionsData.forEach((emoji, userIds) {
      reactions[emoji] = List<String>.from(userIds as List? ?? []);
    });

    return ChatMessage(
      id: id,
      chatRoomId: data['chatRoomId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Unbekannt',
      senderAvatar: data['senderAvatar'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      imageUrl: data['imageUrl'] as String?,
      reactions: reactions,
      replyToMessageId: data['replyToMessageId'] as String?,
      replyToText: data['replyToText'] as String?,
      replyToSenderName: data['replyToSenderName'] as String?,
      readBy: List<String>.from(data['readBy'] as List? ?? []),
      isEdited: data['isEdited'] as bool? ?? false,
      audioUrl: data['audioUrl'] as String?,  // Phase 5A
      audioDuration: data['audioDuration'] as int?,  // Phase 5A
      isPinned: data['isPinned'] as bool? ?? false,  // Phase 5C
      isReported: data['isReported'] as bool? ?? false,  // Phase 5B
      editedAt: data['editedAt'] != null ? (data['editedAt'] as Timestamp).toDate() : null,  // Phase 5C
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
      'reactions': reactions,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'replyToSenderName': replyToSenderName,
      'readBy': readBy,
      'isEdited': isEdited,
      'audioUrl': audioUrl,  // Phase 5A
      'audioDuration': audioDuration,  // Phase 5A
      'isPinned': isPinned,  // Phase 5C
      'isReported': isReported,  // Phase 5B
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,  // Phase 5C
    };
  }
  
  /// Prüft ob User bereits reagiert hat (NEU - Phase 2)
  bool hasReacted(String userId, String emoji) {
    return reactions[emoji]?.contains(userId) ?? false;
  }
  
  /// Zählt Reactions pro Emoji (NEU - Phase 2)
  int getReactionCount(String emoji) {
    return reactions[emoji]?.length ?? 0;
  }

  /// Zeitformatierung für Chat
  String get timeFormatted {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Gerade eben';
    } else if (difference.inHours < 1) {
      return 'Vor ${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return 'Vor ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Vor ${difference.inDays}d';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }
  
  /// Prüft ob dies eine Reply-Nachricht ist (Phase 5A)
  bool get isReply => replyToMessageId != null;
  
  /// Prüft ob User die Nachricht gelesen hat (Phase 5A)
  bool isReadBy(String userId) => readBy.contains(userId);
}

/// Chat Room Model
class ChatRoom {
  final String id;
  final String name;
  final String description;
  final String avatarUrl;
  final List<String> participants;
  final ChatMessage? lastMessage;
  final DateTime createdAt;
  final DateTime lastActivity;
  final int unreadCount;
  final ChatRoomType type;

  ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    this.avatarUrl = '',
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    required this.lastActivity,
    this.unreadCount = 0,
    this.type = ChatRoomType.community,
  });

  factory ChatRoom.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatRoom(
      id: id,
      name: data['name'] as String? ?? 'Chat',
      description: data['description'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] != null
          ? ChatMessage.fromFirestore(
              data['lastMessage'] as Map<String, dynamic>,
              data['lastMessageId'] as String? ?? '',
            )
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActivity: (data['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] as int? ?? 0,
      type: ChatRoomType.values.firstWhere(
        (e) => e.toString() == 'ChatRoomType.${data['type']}',
        orElse: () => ChatRoomType.community,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'participants': participants,
      'lastMessage': lastMessage?.toMap(),
      'lastMessageId': lastMessage?.id,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivity': Timestamp.fromDate(lastActivity),
      'unreadCount': unreadCount,
      'type': type.toString().split('.').last,
    };
  }
}

/// Message Types
enum MessageType {
  text,
  image,
  audio,      // Voice message (Phase 5A)
  video,      // Video message (Phase 5B)
  file,       // File attachment (Phase 5B)
  link,
  system,
}

/// Chat Room Types
enum ChatRoomType {
  community,    // Öffentlicher Community-Chat
  private,      // Privater 1:1 Chat
  group,        // Gruppen-Chat
  event,        // Event-bezogener Chat
}

/// Chat User Model
class ChatUser {
  final String id;
  final String displayName;
  final String avatarUrl;
  final bool isOnline;
  final DateTime lastSeen;

  ChatUser({
    required this.id,
    required this.displayName,
    this.avatarUrl = '',
    this.isOnline = false,
    required this.lastSeen,
  });

  factory ChatUser.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatUser(
      id: id,
      displayName: data['displayName'] as String? ?? 'User',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
    };
  }
}
