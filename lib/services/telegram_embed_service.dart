import 'package:flutter/foundation.dart';

/// v2.30.0 - Telegram Embed Service
/// 
/// Konstruiert Telegram-Links aus Firestore-Daten und stellt
/// Metadaten für Telegram Web Embeds bereit
class TelegramEmbedService {
  static final TelegramEmbedService _instance = TelegramEmbedService._internal();
  factory TelegramEmbedService() => _instance;
  TelegramEmbedService._internal();

  /// Konstruiere Telegram-Link aus channel_username und message_id
  String? constructTelegramUrl(Map<String, dynamic> data) {
    try {
      // Verschiedene Feld-Varianten unterstützen
      String? channelUsername = data['channel_username'];
      int? messageId = data['message_id'] ?? data['telegram_message_id'];
      
      // Für Videos: Verwende direkt video_url falls vorhanden
      if (data['video_url'] != null && data['video_url'].toString().startsWith('https://t.me/')) {
        return data['video_url'];
      }
      
      if (channelUsername == null || messageId == null) {
        debugPrint('⚠️  Fehlende Felder: channel_username=$channelUsername, message_id=$messageId');
        return null;
      }
      
      // Entferne @ falls vorhanden
      channelUsername = channelUsername.replaceAll('@', '');
      
      // Konstruiere Standard-Telegram-Link
      final telegramUrl = 'https://t.me/$channelUsername/$messageId';
      
      debugPrint('✅ Telegram URL konstruiert: $telegramUrl');
      return telegramUrl;
      
    } catch (e) {
      debugPrint('❌ Fehler beim Konstruieren der Telegram URL: $e');
      return null;
    }
  }

  /// Telegram Embed URL (für WebView)
  String getEmbedUrl(String telegramUrl) {
    // Telegram bietet einen Embed-Modus für Posts
    return '$telegramUrl?embed=1&mode=tme';
  }

  /// Extrahiere Display-Name aus verschiedenen Feldern
  String getDisplayName(Map<String, dynamic> data) {
    // Priorität: file_name > title > caption (erste Zeile) > message_id
    
    if (data['file_name'] != null && data['file_name'].toString().isNotEmpty) {
      return data['file_name'];
    }
    
    if (data['title'] != null && data['title'].toString().isNotEmpty) {
      return data['title'];
    }
    
    if (data['caption'] != null && data['caption'].toString().isNotEmpty) {
      final caption = data['caption'].toString();
      final firstLine = caption.split('\n').first;
      if (firstLine.length > 50) {
        return '${firstLine.substring(0, 50)}...';
      }
      return firstLine;
    }
    
    // Fallback
    if (data['media_type'] == 'photo') {
      return 'Bild ${data['message_id'] ?? ''}';
    }
    
    return 'Unbekannte Datei';
  }

  /// Extrahiere vollständige Beschreibung
  String getDescription(Map<String, dynamic> data) {
    final caption = data['caption'] ?? data['description'] ?? '';
    return caption.toString();
  }

  /// Hole Thumbnail URL
  String? getThumbnailUrl(Map<String, dynamic> data) {
    return data['thumbnail_url'];
  }

  /// Prüfe ob Telegram-Link verfügbar ist
  bool hasTelegramUrl(Map<String, dynamic> data) {
    return constructTelegramUrl(data) != null;
  }
}
