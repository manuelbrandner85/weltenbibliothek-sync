/// Telegram Model-Klassen für intelligente Sync-Funktion v3.0
/// 
/// Diese Klassen wrappen die strukturierten App-Events aus Firestore
/// und bieten eine saubere API für die UI-Layer.

class TelegramVideo {
  final String id;
  final Map<String, dynamic> data;
  
  TelegramVideo(this.id, this.data);
  
  // Basis-Felder (kompatibel mit alter und neuer Struktur)
  String get title => data['text_clean'] ?? data['title'] ?? 'Untitled';
  String get description => data['text_clean'] ?? data['description'] ?? '';
  
  // Medien-Felder (neue Struktur)
  String? get thumbnailUrl {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['download_url'];
    }
    return data['thumbnail_url']; // Fallback alte Struktur
  }
  
  String? get videoUrl {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['download_url'];
    }
    return data['video_url']; // Fallback alte Struktur
  }
  
  int get duration {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['duration'] ?? 0;
    }
    return data['duration'] ?? 0; // Fallback alte Struktur
  }
  
  // Neue Intelligente Sync Felder
  String get category => data['topic'] ?? data['category'] ?? 'other';
  double get confidence => (data['confidence'] ?? 0.5).toDouble();
  List<String> get keywords => List<String>.from(data['keywords'] ?? []);
  String? get language => data['language'];
  String get appSection => data['app_section'] ?? 'videos';
  bool get autoPublished => data['auto_published'] ?? false;
  String get priority => data['priority'] ?? 'normal';
  
  // Meta
  int get viewCount => data['view_count'] ?? 0;
  DateTime? get createdAt {
    if (data['timestamp'] != null) {
      return (data['timestamp'] as dynamic).toDate();
    }
    if (data['created_at'] != null) {
      return (data['created_at'] as dynamic).toDate();
    }
    return null;
  }
  
  // Fehlende UI-Getter (für telegram_content_screen.dart)
  int get fileSize {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['groesse'] ?? 0;
    }
    return data['file_size'] ?? 0;
  }
  
  String get telegramUrl {
    final chatId = data['chat_id'];
    final messageId = data['message_id'];
    if (chatId != null && messageId != null) {
      // Entferne '-100' Prefix für öffentliche Links
      final cleanChatId = chatId.toString().replaceFirst('-100', '');
      return 'https://t.me/c/$cleanChatId/$messageId';
    }
    return data['telegram_url'] ?? data['video_url'] ?? '';
  }
  
  // Quelle (neue Struktur)
  String? get chatId => data['chat_id'];
  String? get chatTitle => data['chat_title'];
  String? get authorName => data['author_display_name'];
  bool get isEdited => data['edited'] ?? false;
}

class TelegramDocument {
  final String id;
  final Map<String, dynamic> data;
  
  TelegramDocument(this.id, this.data);
  
  // Basis-Felder
  String get title => data['text_clean'] ?? data['title'] ?? 'Untitled';
  String get description => data['text_clean'] ?? data['description'] ?? '';
  
  // Datei-Felder
  String get fileName {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['dateiname'];
    }
    return data['file_name'] ?? 'document';
  }
  
  int get fileSize {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['groesse'];
    }
    return data['file_size'] ?? 0;
  }
  
  String? get downloadUrl {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['download_url'];
    }
    return data['download_url'];
  }
  
  String get mimeType {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['mime_typ'];
    }
    return data['mime_type'] ?? 'application/octet-stream';
  }
  
  // Intelligente Sync Felder
  String get category => data['topic'] ?? data['category'] ?? 'other';
  double get confidence => (data['confidence'] ?? 0.5).toDouble();
  List<String> get keywords => List<String>.from(data['keywords'] ?? []);
  String? get language => data['language'];
  String get appSection => data['app_section'] ?? 'dokumente';
  bool get autoPublished => data['auto_published'] ?? false;
  String get priority => data['priority'] ?? 'normal';
  
  // Meta
  int get downloadCount => data['download_count'] ?? 0;
  int get viewCount => data['view_count'] ?? 0;
  DateTime? get createdAt {
    if (data['timestamp'] != null) {
      return (data['timestamp'] as dynamic).toDate();
    }
    if (data['created_at'] != null) {
      return (data['created_at'] as dynamic).toDate();
    }
    return null;
  }
  
  // Fehlende UI-Getter
  String get docType {
    final mime = mimeType.toLowerCase();
    if (mime.contains('pdf')) return 'PDF';
    if (mime.contains('word') || mime.contains('doc')) return 'Word';
    if (mime.contains('excel') || mime.contains('sheet')) return 'Excel';
    if (mime.contains('powerpoint') || mime.contains('presentation')) return 'PowerPoint';
    if (mime.contains('zip') || mime.contains('rar') || mime.contains('7z')) return 'Archiv';
    if (mime.contains('text')) return 'Text';
    return 'Dokument';
  }
  
  String get telegramUrl {
    final chatId = data['chat_id'];
    final messageId = data['message_id'];
    if (chatId != null && messageId != null) {
      final cleanChatId = chatId.toString().replaceFirst('-100', '');
      return 'https://t.me/c/$cleanChatId/$messageId';
    }
    return data['telegram_url'] ?? downloadUrl ?? '';
  }
  
  // Quelle
  String? get chatId => data['chat_id'];
  String? get chatTitle => data['chat_title'];
  String? get authorName => data['author_display_name'];
}

class TelegramPhoto {
  final String id;
  final Map<String, dynamic> data;
  
  TelegramPhoto(this.id, this.data);
  
  // Basis-Felder
  String get title => data['text_clean'] ?? data['title'] ?? 'Untitled';
  String get description => data['text_clean'] ?? data['description'] ?? '';
  
  // Bild-Felder
  String? get imageUrl {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['download_url'];
    }
    return data['image_url'];
  }
  
  // Intelligente Sync Felder
  String get category => data['topic'] ?? data['category'] ?? 'other';
  double get confidence => (data['confidence'] ?? 0.5).toDouble();
  List<String> get keywords => List<String>.from(data['keywords'] ?? []);
  String? get language => data['language'];
  String get appSection => data['app_section'] ?? 'bilder';
  bool get autoPublished => data['auto_published'] ?? false;
  String get priority => data['priority'] ?? 'normal';
  
  // Meta
  int get viewCount => data['view_count'] ?? 0;
  DateTime? get createdAt {
    if (data['timestamp'] != null) {
      return (data['timestamp'] as dynamic).toDate();
    }
    if (data['created_at'] != null) {
      return (data['created_at'] as dynamic).toDate();
    }
    return null;
  }
  
  // Fehlende UI-Getter
  String get telegramUrl {
    final chatId = data['chat_id'];
    final messageId = data['message_id'];
    if (chatId != null && messageId != null) {
      final cleanChatId = chatId.toString().replaceFirst('-100', '');
      return 'https://t.me/c/$cleanChatId/$messageId';
    }
    return data['telegram_url'] ?? imageUrl ?? '';
  }
  
  int? get width {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['width'];
    }
    return data['width'];
  }
  
  int? get height {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['height'];
    }
    return data['height'];
  }
  
  // Quelle
  String? get chatId => data['chat_id'];
  String? get chatTitle => data['chat_title'];
  String? get authorName => data['author_display_name'];
}

class TelegramAudio {
  final String id;
  final Map<String, dynamic> data;
  
  TelegramAudio(this.id, this.data);
  
  // Basis-Felder
  String get title => data['text_clean'] ?? data['title'] ?? 'Untitled';
  String get description => data['text_clean'] ?? data['description'] ?? '';
  
  // Audio-Felder
  String? get downloadUrl {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['download_url'];
    }
    return data['download_url'];
  }
  
  int get duration {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['duration'] ?? 0;
    }
    return data['duration'] ?? 0;
  }
  
  // Intelligente Sync Felder
  String get category => data['topic'] ?? data['category'] ?? 'other';
  double get confidence => (data['confidence'] ?? 0.5).toDouble();
  List<String> get keywords => List<String>.from(data['keywords'] ?? []);
  String? get language => data['language'];
  String get appSection => data['app_section'] ?? 'audio';
  bool get autoPublished => data['auto_published'] ?? false;
  String get priority => data['priority'] ?? 'normal';
  
  // Meta
  int get viewCount => data['view_count'] ?? 0;
  DateTime? get createdAt {
    if (data['timestamp'] != null) {
      return (data['timestamp'] as dynamic).toDate();
    }
    if (data['created_at'] != null) {
      return (data['created_at'] as dynamic).toDate();
    }
    return null;
  }
  
  // Fehlende UI-Getter
  String get telegramUrl {
    final chatId = data['chat_id'];
    final messageId = data['message_id'];
    if (chatId != null && messageId != null) {
      final cleanChatId = chatId.toString().replaceFirst('-100', '');
      return 'https://t.me/c/$cleanChatId/$messageId';
    }
    return data['telegram_url'] ?? downloadUrl ?? '';
  }
  
  String? get performer {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['performer'];
    }
    return data['performer'] ?? data['author_display_name'];
  }
  
  int get fileSize {
    if (data['media_files'] != null && (data['media_files'] as List).isNotEmpty) {
      return (data['media_files'] as List).first['groesse'] ?? 0;
    }
    return data['file_size'] ?? 0;
  }
  
  // Quelle
  String? get chatId => data['chat_id'];
  String? get chatTitle => data['chat_title'];
  String? get authorName => data['author_display_name'];
}

class TelegramPost {
  final String id;
  final Map<String, dynamic> data;
  
  TelegramPost(this.id, this.data);
  
  // Basis-Felder
  String get title => data['text_clean'] ?? data['title'] ?? 'Untitled';
  String get content => data['text_clean'] ?? data['content'] ?? '';
  
  // Intelligente Sync Felder
  String get category => data['topic'] ?? data['category'] ?? 'other';
  double get confidence => (data['confidence'] ?? 0.5).toDouble();
  List<String> get keywords => List<String>.from(data['keywords'] ?? []);
  String? get language => data['language'];
  String get appSection => data['app_section'] ?? 'feed';
  bool get autoPublished => data['auto_published'] ?? false;
  String get priority => data['priority'] ?? 'normal';
  
  // Inhalt-Analyse
  List<String> get hashtags => List<String>.from(data['hashtags'] ?? []);
  List<String> get links => List<String>.from(data['links'] ?? []);
  List<String> get mentions => List<String>.from(data['mentions'] ?? []);
  
  // Meta
  int get viewCount => data['view_count'] ?? 0;
  DateTime? get createdAt {
    if (data['timestamp'] != null) {
      return (data['timestamp'] as dynamic).toDate();
    }
    if (data['created_at'] != null) {
      return (data['created_at'] as dynamic).toDate();
    }
    return null;
  }
  
  // Fehlende UI-Getter
  String get telegramUrl {
    final chatId = data['chat_id'];
    final messageId = data['message_id'];
    if (chatId != null && messageId != null) {
      final cleanChatId = chatId.toString().replaceFirst('-100', '');
      return 'https://t.me/c/$cleanChatId/$messageId';
    }
    return data['telegram_url'] ?? '';
  }
  
  // Quelle
  String? get chatId => data['chat_id'];
  String? get chatTitle => data['chat_title'];
  String? get authorName => data['author_display_name'];
}
