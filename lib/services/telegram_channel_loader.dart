import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/channel_content.dart';

/// Automatischer Telegram Channel Content Loader
/// 
/// Lädt Inhalte vom Telegram Channel, kategorisiert sie automatisch
/// und zeigt sie in der App an. Startet automatisch beim App-Start.
class TelegramChannelLoader {
  static const String _botToken = '7826102549:AAHMOTvl13GlR2vousHVTE4jO0xTYuVlS7k';
  static const String _channelUsername = '@Weltenbibliothekchat';
  static const String _baseUrl = 'https://api.telegram.org/bot$_botToken';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Singleton Pattern
  static final TelegramChannelLoader _instance = TelegramChannelLoader._internal();
  factory TelegramChannelLoader() => _instance;
  TelegramChannelLoader._internal();
  
  bool _isLoading = false;
  DateTime? _lastLoadTime;
  
  // Kategorien-Konfiguration
  static const Map<String, CategoryConfig> _categories = {
    'lostCivilizations': CategoryConfig(
      name: 'Verlorene Zivilisationen',
      icon: '🏛️',
      keywords: ['atlantis', 'lemuria', 'versunkene', 'antike zivilisation', 'mu', 'hyperborea'],
      hashtags: ['#atlantis', '#lemuria', '#mu', '#hyperborea'],
    ),
    'alienTheories': CategoryConfig(
      name: 'Außerirdische Theorien',
      icon: '👽',
      keywords: ['außerirdische', 'ufo', 'aliens', 'greys', 'reptiloiden', 'entführung'],
      hashtags: ['#ufo', '#aliens', '#greys', '#reptiloiden'],
    ),
    'ancientTechnology': CategoryConfig(
      name: 'Antike Technologie',
      icon: '⚙️',
      keywords: ['pyramiden', 'kristalle', 'antike technologie', 'artefakte', 'obelisken'],
      hashtags: ['#pyramiden', '#kristalle', '#obelisken', '#technologie'],
    ),
    'esoterik': CategoryConfig(
      name: 'Esoterik & Spiritualität',
      icon: '🔮',
      keywords: ['meditation', 'chakren', 'spiritualität', 'energie', 'aura'],
      hashtags: ['#meditation', '#chakren', '#astral', '#energie'],
    ),
    'conspiracies': CategoryConfig(
      name: 'Verschwörungstheorien',
      icon: '🕵️',
      keywords: ['illuminati', 'verschwörung', 'geheimbund', 'nwo', 'mkultra'],
      hashtags: ['#illuminati', '#nwo', '#mkultra', '#deepstate'],
    ),
    'archaeology': CategoryConfig(
      name: 'Archäologie & Geschichte',
      icon: '🏺',
      keywords: ['archäologie', 'artefakte', 'ausgrabungen', 'geschichte', 'fossil'],
      hashtags: ['#artefakte', '#ausgrabungen', '#archäologie'],
    ),
    'mysticism': CategoryConfig(
      name: 'Mystik & Okkultismus',
      icon: '🔯',
      keywords: ['magie', 'rituale', 'okkultismus', 'alchemie', 'hexerei'],
      hashtags: ['#magie', '#rituale', '#alchemie'],
    ),
    'cosmos': CategoryConfig(
      name: 'Kosmos & Astronomie',
      icon: '🌌',
      keywords: ['kosmos', 'planeten', 'astronomie', 'sterne', 'galaxie'],
      hashtags: ['#planeten', '#sternbilder', '#anomalien'],
    ),
    'forbidden': CategoryConfig(
      name: 'Verbotenes Wissen',
      icon: '📜',
      keywords: ['verboten', 'geheim', 'zensiert', 'unterdrückt', 'tabu'],
      hashtags: ['#verboten', '#geheim', '#zensiert'],
    ),
    'paranormal': CategoryConfig(
      name: 'Paranormale Phänomene',
      icon: '👻',
      keywords: ['geist', 'paranormal', 'phänomen', 'übernatürlich', 'spuk'],
      hashtags: ['#paranormal', '#geister', '#phänomene'],
    ),
  };
  
  /// Startet automatischen Content-Import beim App-Start
  Future<void> initialize() async {
    if (_isLoading) {
      debugPrint('⚠️ Channel-Loader läuft bereits');
      return;
    }
    
    try {
      debugPrint('🚀 Starte Telegram Channel Content Loader...');
      await loadChannelContent();
      debugPrint('✅ Channel Content erfolgreich geladen');
    } catch (e) {
      debugPrint('❌ Fehler beim Laden des Channel Contents: $e');
    }
  }
  
  /// Lädt alle Inhalte vom Telegram Channel
  Future<void> loadChannelContent({int limit = 100}) async {
    if (_isLoading) {
      debugPrint('⚠️ Content wird bereits geladen');
      return;
    }
    
    _isLoading = true;
    
    try {
      // 1. Hole Channel-Info und ID
      final channelInfo = await _getChannelInfo();
      if (channelInfo == null) {
        debugPrint('❌ Channel nicht gefunden: $_channelUsername');
        return;
      }
      
      final channelId = channelInfo['id'].toString();
      debugPrint('✅ Channel gefunden: $channelId');
      
      // 2. Lade die letzten N Nachrichten
      final messages = await _getChannelMessages(channelId, limit);
      debugPrint('📥 ${messages.length} Nachrichten geladen');
      
      // 3. Verarbeite und kategorisiere die Nachrichten
      int savedCount = 0;
      for (var message in messages) {
        try {
          final content = await _processMessage(message, channelId);
          if (content != null) {
            await _saveToFirestore(content);
            savedCount++;
          }
        } catch (e) {
          debugPrint('⚠️ Fehler beim Verarbeiten der Nachricht: $e');
        }
      }
      
      debugPrint('✅ $savedCount Inhalte in Firestore gespeichert');
      _lastLoadTime = DateTime.now();
      
    } catch (e) {
      debugPrint('❌ Fehler beim Laden des Channel Contents: $e');
    } finally {
      _isLoading = false;
    }
  }
  
  /// Hole Channel-Informationen
  Future<Map<String, dynamic>?> _getChannelInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/getChat?chat_id=$_channelUsername'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return data['result'];
        }
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Abrufen der Channel-Info: $e');
    }
    return null;
  }
  
  /// Lade Nachrichten vom Channel
  Future<List<Map<String, dynamic>>> _getChannelMessages(
    String channelId,
    int limit,
  ) async {
    final List<Map<String, dynamic>> messages = [];
    
    try {
      // Verwende getUpdates für öffentliche Channels
      final response = await http.get(
        Uri.parse('$_baseUrl/getUpdates?limit=$limit&allowed_updates=["channel_post"]'),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true && data['result'] is List) {
          for (var update in data['result']) {
            if (update['channel_post'] != null) {
              messages.add(update['channel_post']);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Channel-Nachrichten: $e');
    }
    
    return messages;
  }
  
  /// Verarbeite einzelne Nachricht und kategorisiere sie
  Future<ChannelContent?> _processMessage(
    Map<String, dynamic> message,
    String channelId,
  ) async {
    try {
      final messageId = message['message_id'].toString();
      final text = message['text'] ?? message['caption'] ?? '';
      final date = DateTime.fromMillisecondsSinceEpoch(
        (message['date'] as int) * 1000,
      );
      
      // Bestimme Content-Typ
      ContentType contentType = ContentType.text;
      String? mediaUrl;
      String? thumbnailUrl;
      Map<String, dynamic>? mediaInfo;
      
      if (message['video'] != null) {
        contentType = ContentType.video;
        mediaInfo = message['video'];
        final fileId = mediaInfo?['file_id'];
        if (fileId != null) {
          mediaUrl = await _getFileUrl(fileId);
        }
        
        // Thumbnail
        if (mediaInfo?['thumb'] != null) {
          final thumbId = mediaInfo?['thumb']['file_id'];
          if (thumbId != null) {
            thumbnailUrl = await _getFileUrl(thumbId);
          }
        }
      } else if (message['photo'] != null) {
        contentType = ContentType.photo;
        final photos = message['photo'] as List;
        if (photos.isNotEmpty) {
          final largestPhoto = photos.last;
          final fileId = largestPhoto['file_id'];
          if (fileId != null) {
            mediaUrl = await _getFileUrl(fileId);
            thumbnailUrl = mediaUrl;
          }
        }
      } else if (message['document'] != null) {
        contentType = ContentType.document;
        mediaInfo = message['document'];
        final fileId = mediaInfo?['file_id'];
        if (fileId != null) {
          mediaUrl = await _getFileUrl(fileId);
        }
      } else if (message['audio'] != null) {
        contentType = ContentType.audio;
        mediaInfo = message['audio'];
        final fileId = mediaInfo?['file_id'];
        if (fileId != null) {
          mediaUrl = await _getFileUrl(fileId);
        }
      } else if (message['voice'] != null) {
        contentType = ContentType.voice;
        mediaInfo = message['voice'];
        final fileId = mediaInfo?['file_id'];
        if (fileId != null) {
          mediaUrl = await _getFileUrl(fileId);
        }
      }
      
      // Automatische Kategorisierung
      final category = _categorizeContent(text);
      
      // Telegram-Link zur Nachricht
      final telegramLink = 'https://t.me/${_channelUsername.replaceAll('@', '')}/$messageId';
      
      return ChannelContent(
        id: '${channelId}_$messageId',
        messageId: messageId,
        channelId: channelId,
        text: text,
        category: category,
        contentType: contentType,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        date: date,
        telegramLink: telegramLink,
        mediaInfo: mediaInfo,
      );
      
    } catch (e) {
      debugPrint('❌ Fehler beim Verarbeiten der Nachricht: $e');
      return null;
    }
  }
  
  /// Hole File-URL von Telegram
  Future<String?> _getFileUrl(String fileId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/getFile?file_id=$fileId'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true && data['result']['file_path'] != null) {
          final filePath = data['result']['file_path'];
          return 'https://api.telegram.org/file/bot$_botToken/$filePath';
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fehler beim Abrufen der File-URL: $e');
    }
    return null;
  }
  
  /// Kategorisiere Content automatisch basierend auf Text
  String _categorizeContent(String text) {
    final textLower = text.toLowerCase();
    
    // Zähle Matches für jede Kategorie
    final Map<String, int> categoryScores = {};
    
    for (var entry in _categories.entries) {
      int score = 0;
      final config = entry.value;
      
      // Prüfe Keywords
      for (var keyword in config.keywords) {
        if (textLower.contains(keyword.toLowerCase())) {
          score += 2;
        }
      }
      
      // Prüfe Hashtags (höhere Gewichtung)
      for (var hashtag in config.hashtags) {
        if (textLower.contains(hashtag.toLowerCase())) {
          score += 3;
        }
      }
      
      if (score > 0) {
        categoryScores[entry.key] = score;
      }
    }
    
    // Finde Kategorie mit höchstem Score
    if (categoryScores.isNotEmpty) {
      var maxEntry = categoryScores.entries.first;
      for (var entry in categoryScores.entries) {
        if (entry.value > maxEntry.value) {
          maxEntry = entry;
        }
      }
      return maxEntry.key;
    }
    
    // Fallback: Allgemein
    return 'general';
  }
  
  /// Speichere Content in Firestore
  Future<void> _saveToFirestore(ChannelContent content) async {
    try {
      await _firestore
          .collection('channel_content')
          .doc(content.id)
          .set(content.toFirestore(), SetOptions(merge: true));
      
      debugPrint('✅ Content gespeichert: ${content.id}');
    } catch (e) {
      debugPrint('❌ Fehler beim Speichern in Firestore: $e');
    }
  }
  
  /// Stream für Content nach Kategorie
  Stream<List<ChannelContent>> getContentByCategory(String category) {
    return _firestore
        .collection('channel_content')
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChannelContent.fromFirestore(doc.data()))
          .toList();
    });
  }
  
  /// Stream für alle Inhalte
  Stream<List<ChannelContent>> getAllContent() {
    return _firestore
        .collection('channel_content')
        .orderBy('date', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChannelContent.fromFirestore(doc.data()))
          .toList();
    });
  }
  
  /// Hole Kategorien-Info
  static CategoryConfig? getCategoryConfig(String categoryId) {
    return _categories[categoryId];
  }
  
  /// Alle Kategorien
  static Map<String, CategoryConfig> get categories => _categories;
}

/// Kategorien-Konfiguration
class CategoryConfig {
  final String name;
  final String icon;
  final List<String> keywords;
  final List<String> hashtags;
  
  const CategoryConfig({
    required this.name,
    required this.icon,
    required this.keywords,
    required this.hashtags,
  });
}
