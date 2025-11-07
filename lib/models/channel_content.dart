import 'package:cloud_firestore/cloud_firestore.dart';

/// Content-Typ Enum
enum ContentType {
  text,
  photo,
  video,
  document,
  audio,
  voice,
}

/// Channel Content Model
/// 
/// Repräsentiert einen Post/Nachricht aus dem Telegram Channel
class ChannelContent {
  final String id;
  final String messageId;
  final String channelId;
  final String text;
  final String category;
  final ContentType contentType;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final DateTime date;
  final String telegramLink;
  final Map<String, dynamic>? mediaInfo;
  
  // Zusätzliche Metadaten
  final int? views;
  final int? forwards;
  final bool? isPinned;
  
  ChannelContent({
    required this.id,
    required this.messageId,
    required this.channelId,
    required this.text,
    required this.category,
    required this.contentType,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.date,
    required this.telegramLink,
    this.mediaInfo,
    this.views,
    this.forwards,
    this.isPinned,
  });
  
  /// Von Firestore
  factory ChannelContent.fromFirestore(Map<String, dynamic> data) {
    return ChannelContent(
      id: data['id'] as String,
      messageId: data['messageId'] as String,
      channelId: data['channelId'] as String,
      text: data['text'] as String? ?? '',
      category: data['category'] as String? ?? 'general',
      contentType: ContentType.values.firstWhere(
        (e) => e.toString() == 'ContentType.${data['contentType']}',
        orElse: () => ContentType.text,
      ),
      mediaUrl: data['mediaUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      date: (data['date'] as Timestamp).toDate(),
      telegramLink: data['telegramLink'] as String,
      mediaInfo: data['mediaInfo'] as Map<String, dynamic>?,
      views: data['views'] as int?,
      forwards: data['forwards'] as int?,
      isPinned: data['isPinned'] as bool?,
    );
  }
  
  /// Zu Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'messageId': messageId,
      'channelId': channelId,
      'text': text,
      'category': category,
      'contentType': contentType.toString().split('.').last,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'date': Timestamp.fromDate(date),
      'telegramLink': telegramLink,
      'mediaInfo': mediaInfo,
      'views': views,
      'forwards': forwards,
      'isPinned': isPinned,
    };
  }
  
  /// Copy with
  ChannelContent copyWith({
    String? id,
    String? messageId,
    String? channelId,
    String? text,
    String? category,
    ContentType? contentType,
    String? mediaUrl,
    String? thumbnailUrl,
    DateTime? date,
    String? telegramLink,
    Map<String, dynamic>? mediaInfo,
    int? views,
    int? forwards,
    bool? isPinned,
  }) {
    return ChannelContent(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      channelId: channelId ?? this.channelId,
      text: text ?? this.text,
      category: category ?? this.category,
      contentType: contentType ?? this.contentType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      date: date ?? this.date,
      telegramLink: telegramLink ?? this.telegramLink,
      mediaInfo: mediaInfo ?? this.mediaInfo,
      views: views ?? this.views,
      forwards: forwards ?? this.forwards,
      isPinned: isPinned ?? this.isPinned,
    );
  }
  
  /// Ist Video?
  bool get isVideo => contentType == ContentType.video;
  
  /// Ist Foto?
  bool get isPhoto => contentType == ContentType.photo;
  
  /// Hat Medien?
  bool get hasMedia => mediaUrl != null;
  
  /// Videodauer (falls vorhanden)
  int? get videoDuration {
    if (mediaInfo != null && isVideo) {
      return mediaInfo!['duration'] as int?;
    }
    return null;
  }
  
  /// Datei-Größe (falls vorhanden)
  int? get fileSize {
    if (mediaInfo != null) {
      return mediaInfo!['file_size'] as int?;
    }
    return null;
  }
  
  /// Formatierte Dateigröße
  String? get formattedFileSize {
    final size = fileSize;
    if (size == null) return null;
    
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  /// Formatierte Videodauer
  String? get formattedDuration {
    final duration = videoDuration;
    if (duration == null) return null;
    
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')} Min';
    } else {
      return '$seconds Sek';
    }
  }
}

/// Content-Statistiken
class ContentStats {
  final int totalCount;
  final int videoCount;
  final int photoCount;
  final int textCount;
  final Map<String, int> categoryCount;
  final DateTime? latestUpdate;
  
  ContentStats({
    required this.totalCount,
    required this.videoCount,
    required this.photoCount,
    required this.textCount,
    required this.categoryCount,
    this.latestUpdate,
  });
  
  factory ContentStats.empty() {
    return ContentStats(
      totalCount: 0,
      videoCount: 0,
      photoCount: 0,
      textCount: 0,
      categoryCount: {},
    );
  }
}
