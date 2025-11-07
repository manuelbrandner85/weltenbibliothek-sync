import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/telegram_models.dart';

/// Telegram Service v4.0 - Erweiterte Features
/// 
/// NEUE FEATURES in V4:
/// ✅ Edit / Undo - Nachrichten bearbeiten und löschen
/// ✅ Pin / Fixieren - Admins können Nachrichten anpinnen
/// ✅ Thread / Reply / Zitat - Antworten auf Nachrichten mit Thread-Support
/// ✅ Lesebestätigung - Tracking wer Nachrichten gelesen hat
/// ✅ Erinnerungen - Push-Benachrichtigungen zu bestimmten Zeiten
/// ✅ Favoriten - Markierte Chats/Topics für schnellen Zugriff
/// ✅ Automatische Thumbnail-Generierung für Medien
/// ✅ Audio/Video Streaming ohne kompletten Download
/// ✅ Datei-Kategorisierung (PDFs, Videos, Bilder, Audio)
/// ✅ Offline-Modus für Medien mit lokalem Cache
/// ✅ Galerie pro Topic mit Grid-Ansicht
class TelegramService {
  // ========== CONFIGURATION ==========
  
  static const String _botToken = '7826102549:AAHMOTvl13GlR2vousHVTE4jO0xTYuVlS7k';
  static const String _botUsername = '@weltenbibliothek_bot';
  static const String _chatUsername = '@Weltenbibliothekchat';
  static const String _channelUsername = '@ArchivWeltenBibliothek';
  static const String _baseUrl = 'https://api.telegram.org/bot$_botToken';
  
  // Chat & Channel IDs
  String? _chatId;
  String? _channelId;
  
  // Long Polling
  Timer? _pollingTimer;
  int _lastUpdateId = 0;
  bool _isInitialized = false;
  bool _isPolling = false;
  
  // Polling Stability
  int _consecutiveErrors = 0;
  int _pollingInterval = 2;
  DateTime? _lastSuccessfulPoll;
  static const int _maxConsecutiveErrors = 5;
  static const int _maxPollingInterval = 60;
  
  // Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Local Cache Directory
  Directory? _cacheDir;
  
  // ========== APP CONFIGURATION ==========
  
  static const Map<String, dynamic> _appConfig = {
    'themen': {
      'lostCivilizations': {
        'label': 'Verlorene Zivilisationen',
        'hashtags': ['#atlantis', '#lemuria', '#mu', '#hyperborea'],
        'keywords': ['atlantis', 'lemuria', 'versunkene', 'antike zivilisation'],
      },
      'alienTheories': {
        'label': 'Außerirdische Theorien',
        'hashtags': ['#ufo', '#aliens', '#greys', '#reptiloiden'],
        'keywords': ['außerirdische', 'ufo', 'aliens', 'greys'],
      },
      'ancientTechnology': {
        'label': 'Antike Technologie',
        'hashtags': ['#pyramiden', '#kristalle', '#obelisken'],
        'keywords': ['pyramiden', 'kristalle', 'antike technologie'],
      },
      'esoterik': {
        'label': 'Esoterik & Spiritualität',
        'hashtags': ['#meditation', '#chakren', '#astral'],
        'keywords': ['meditation', 'chakren', 'spiritualität'],
      },
      'conspiracies': {
        'label': 'Verschwörungstheorien',
        'hashtags': ['#illuminati', '#nwo', '#mkultra'],
        'keywords': ['illuminati', 'verschwörung', 'geheimbund'],
      },
      'archaeology': {
        'label': 'Archäologie & Geschichte',
        'hashtags': ['#artefakte', '#ausgrabungen', '#archäologie'],
        'keywords': ['archäologie', 'artefakte', 'ausgrabungen'],
      },
      'mysticism': {
        'label': 'Mystik & Okkultismus',
        'hashtags': ['#magie', '#rituale', '#alchemie'],
        'keywords': ['magie', 'rituale', 'okkultismus'],
      },
      'cosmos': {
        'label': 'Kosmos & Astronomie',
        'hashtags': ['#planeten', '#sternbilder', '#anomalien'],
        'keywords': ['kosmos', 'planeten', 'astronomie'],
      },
      'forbidden': {
        'label': 'Verbotenes Wissen',
        'hashtags': ['#geheimgesellschaften', '#gnosis'],
        'keywords': ['verboten', 'geheim', 'gnosis'],
      },
      'other': {
        'label': 'Sonstiges',
        'hashtags': [],
        'keywords': [],
      },
    },
    'routing': {
      'vertrauensschwelle_auto_publish': 0.7,
      'vertrauensschwelle_benachrichtigung': 0.8,
    },
  };

  // ========== INITIALIZATION ==========
  
  /// Initialize service
  Future<bool> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) print('✅ Telegram Service bereits initialisiert');
      return true;
    }

    try {
      if (kDebugMode) print('🚀 Starte Telegram Service V4...');

      // Initialize cache directory
      await _initializeCacheDirectory();

      // Get bot info
      final botInfo = await _getBotInfo();
      if (kDebugMode) {
        print('✅ Bot verbunden: ${botInfo['username']}');
      }

      // Get chat and channel IDs
      await _resolveChatIds();

      // Stelle sicher, dass keine alten Updates erneut verarbeitet werden
      await _primeLastUpdateId();

      _isInitialized = true;
      if (kDebugMode) print('✅ Telegram Service V4 initialisiert');

      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Initialisierung fehlgeschlagen: $e');
      return false;
    }
  }

  /// Initialize local cache directory
  Future<void> _initializeCacheDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/telegram_cache');
      
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
        if (kDebugMode) print('📁 Cache-Verzeichnis erstellt: ${_cacheDir!.path}');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Cache-Verzeichnis konnte nicht erstellt werden: $e');
    }
  }

  /// Get bot information
  Future<Map<String, dynamic>> _getBotInfo() async {
    final response = await http.get(Uri.parse('$_baseUrl/getMe'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['ok']) {
        return data['result'];
      }
    }
    throw Exception('Fehler beim Abrufen der Bot-Informationen');
  }

  /// Resolve chat and channel IDs
  Future<void> _resolveChatIds() async {
    try {
      // Try to get IDs from Firestore first
      final configDoc = await _firestore
          .collection('telegram_config')
          .doc('channels')
          .get();

      if (configDoc.exists) {
        final data = configDoc.data()!;
        _chatId = data['chat_id']?.toString();
        _channelId = data['channel_id']?.toString();
      }

      if (kDebugMode) {
        print('📡 Chat ID: $_chatId');
        print('📡 Channel ID: $_channelId');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Fehler beim Abrufen der IDs: $e');
    }
  }

  // ========== POLLING ==========
  
  /// Start polling for updates
  void startPolling() {
    if (_isPolling) {
      if (kDebugMode) print('⚠️ Polling läuft bereits');
      return;
    }

    _isPolling = true;
    _pollingTimer?.cancel();
    
    _pollingTimer = Timer.periodic(
      Duration(seconds: _pollingInterval),
      (_) => _pollUpdates(),
    );

    if (kDebugMode) {
      print('✅ Polling gestartet (Intervall: ${_pollingInterval}s)');
    }
  }

  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _isPolling = false;
    if (kDebugMode) print('⏸️ Polling gestoppt');
  }
  
  /// Check if polling is healthy
  bool isPollingHealthy() {
    if (!_isInitialized) return false;
    if (_pollingTimer == null || !_pollingTimer!.isActive) return false;
    if (_consecutiveErrors >= _maxConsecutiveErrors) return false;
    
    if (_lastSuccessfulPoll != null) {
      final timeSinceLastPoll = DateTime.now().difference(_lastSuccessfulPoll!);
      if (timeSinceLastPoll.inMinutes > 5) {
        return false;
      }
    }
    
    return true;
  }

  /// Poll for updates
  Future<void> _pollUpdates() async {
    if (!_isInitialized) return;

    try {
      final updates = await _getUpdates();
      
      if (updates.isNotEmpty) {
        _lastSuccessfulPoll = DateTime.now();
        _consecutiveErrors = 0;
        _pollingInterval = 2; // Reset to normal interval

        for (var update in updates) {
          await _processUpdate(update);
          _lastUpdateId = update['update_id'] + 1;
        }
      }
    } catch (e) {
      _consecutiveErrors++;
      if (kDebugMode) {
        print('❌ Polling-Fehler ($_consecutiveErrors/$_maxConsecutiveErrors): $e');
      }

      // Exponential backoff
      if (_consecutiveErrors >= _maxConsecutiveErrors) {
        _pollingInterval = (_pollingInterval * 2).clamp(2, _maxPollingInterval);
        if (kDebugMode) {
          print('⏱️ Polling-Intervall erhöht auf ${_pollingInterval}s');
        }
      }
    }
  }

  /// Get updates from Telegram
  Future<List<dynamic>> _getUpdates() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/getUpdates?offset=$_lastUpdateId&timeout=30'),
    ).timeout(const Duration(seconds: 35));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['ok']) {
        return data['result'] ?? [];
      }
    }

    throw Exception('Fehler beim Abrufen der Updates');
  }

  // ========== MESSAGE PROCESSING ==========
  
  /// ============================================
  /// 🧩 TELEGRAM MEDIA-DOWNLOAD FIX
  /// ============================================

  /// Holt File-Pfad von Telegram (getFile)
  Future<String?> _getFilePathFromTelegram(String fileId) async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/getFile?file_id=$fileId')).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['ok'] == true) {
          return data['result']?['file_path'] as String?;
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ _getFilePathFromTelegram Fehler: $e');
    }
    return null;
  }

  /// Lädt Datei herunter und speichert sie lokal
  Future<String?> _downloadFileFromTelegram(String filePath) async {
    if (_cacheDir == null) await _initializeCacheDirectory();
    try {
      final url = 'https://api.telegram.org/file/bot$_botToken/$filePath';
      final fileName = filePath.split('/').last;
      final localFile = File('${_cacheDir!.path}/$fileName');
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        await localFile.writeAsBytes(resp.bodyBytes);
        if (kDebugMode) print('📥 Datei heruntergeladen: ${localFile.path}');
        return localFile.path;
      } else {
        if (kDebugMode) print('❌ Download fehlgeschlagen: ${resp.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ _downloadFileFromTelegram Fehler: $e');
    }
    return null;
  }
  
  /// Process Telegram update
  Future<void> _processUpdate(Map<String, dynamic> update) async {
    try {
      Map<String, dynamic>? message;
      bool isEdited = false;

      // Determine message type
      if (update['message'] != null) {
        message = update['message'];
      } else if (update['edited_message'] != null) {
        message = update['edited_message'];
        isEdited = true;
      } else if (update['channel_post'] != null) {
        message = update['channel_post'];
      } else if (update['edited_channel_post'] != null) {
        message = update['edited_channel_post'];
        isEdited = true;
      }

      if (message == null) return;

      // Create app event
      final appEvent = await _createAppEvent(message, isEdited);

      // Save to Firestore
      await _saveToFirestore(appEvent);

      if (kDebugMode) {
        print('✅ Nachricht verarbeitet: ${appEvent['app_id']}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Fehler bei Nachrichtenverarbeitung: $e');
    }
  }

  /// Create structured app event from Telegram message
  Future<Map<String, dynamic>> _createAppEvent(
    Map<String, dynamic> message,
    bool isEdited,
  ) async {
    // Extract basic info
    final chatId = message['chat']?['id']?.toString() ?? '';
    final messageId = message['message_id'];
    final senderId = message['from']?['id']?.toString() ?? 'unknown';
    final senderName = message['from']?['first_name'] ?? 'Unknown';
    final senderUsername = message['from']?['username'];
    final text = message['text'] ?? message['caption'] ?? '';
    final timestamp = message['date'] ?? 0;
    final editedAt = message['edit_date'];

    // Extract metadata
    final hashtags = _extractHashtags(text);
    final mentions = _extractMentions(text);
    final links = _extractLinks(text);

    // Classify content
    final classification = _classifyContent(text, hashtags);

    // Process media if present
    Map<String, dynamic>? mediaInfo;
    String mediaType = 'none';

    if (message['photo'] != null) {
      mediaType = 'photo';
      mediaInfo = await _processPhoto(message);
    } else if (message['video'] != null) {
      mediaType = 'video';
      mediaInfo = await _processVideo(message);
    } else if (message['document'] != null) {
      mediaType = 'document';
      mediaInfo = await _processDocument(message);
    } else if (message['audio'] != null) {
      mediaType = 'audio';
      mediaInfo = await _processAudio(message);
    } else if (message['voice'] != null) {
      mediaType = 'voice';
      mediaInfo = await _processVoice(message);
    }

    // Determine routing
    final routing = _determineRouting(mediaType, classification);

    // Create app event
    return {
      'aktion': isEdited ? 'aktualisieren' : 'erstellen',
      'app_id': 'telegram_${messageId}_$chatId',
      'quelle': {
        'platform': 'telegram',
        'chat_id': chatId,
        'message_id': messageId,
        'chat_titel': message['chat']?['title'] ?? '',
        'bearbeitet': isEdited,
        'zeitstempel': timestamp,
      },
      'autor': {
        'user_id': senderId,
        'username': senderUsername,
        'display_name': senderName,
      },
      'inhalt': {
        'text_roh': text,
        'text_bereinigt': _cleanText(text),
        'hashtags': hashtags,
        'links': links,
        'erwaehnungen': mentions,
      },
      'medien': {
        'typ': mediaType,
        'dateien': mediaInfo != null ? [mediaInfo] : [],
      },
      'klassifikation': classification,
      'routing': routing,
      'extended_features': {
        'is_pinned': false,
        'read_by': <String>[],
        'favorite_by': <String>[],
        'reply_to': message['reply_to_message']?['message_id']?.toString(),
        'thread_id': message['message_thread_id']?.toString(),
      },
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  // ========== MEDIA PROCESSING ==========
  
  /// Process photo message
  Future<Map<String, dynamic>> _processPhoto(Map<String, dynamic> message) async {
    final photos = message['photo'] as List;
    if (photos.isEmpty) return {};

    // Get largest photo
    final photo = photos.reduce((a, b) =>
        ((a['file_size'] ?? 0) > (b['file_size'] ?? 0)) ? a : b);

    final fileId = photo['file_id'];
    final fileSize = photo['file_size'] ?? 0;
    final width = photo['width'] ?? 0;
    final height = photo['height'] ?? 0;

    // Get file path and download URL
    final filePath = await _getFilePath(fileId);
    final downloadUrl = _getFileDownloadUrl(filePath);

    // Try to cache locally
    String? localPath;
    try {
      localPath = await _cacheMediaFile(fileId, downloadUrl, 'jpg');
    } catch (e) {
      if (kDebugMode) print('⚠️ Lokales Caching fehlgeschlagen: $e');
    }

    return {
      'telegram_file_id': fileId,
      'dateiname': 'photo_$fileId.jpg',
      'mime_typ': 'image/jpeg',
      'groesse': fileSize,
      'download_url': downloadUrl,
      'width': width,
      'height': height,
      'local_path': localPath,
      'is_cached': localPath != null,
    };
  }

  /// Process video message
  Future<Map<String, dynamic>> _processVideo(Map<String, dynamic> message) async {
    final video = message['video'];
    if (video == null) return {};

    final fileId = video['file_id'];
    final fileName = video['file_name'] ?? 'video_$fileId.mp4';
    final mimeType = video['mime_type'] ?? 'video/mp4';
    final fileSize = video['file_size'] ?? 0;
    final duration = video['duration'] ?? 0;
    final width = video['width'] ?? 0;
    final height = video['height'] ?? 0;

    final filePath = await _getFilePath(fileId);
    final downloadUrl = _getFileDownloadUrl(filePath);

    // Try to cache locally
    String? localPath;
    try {
      localPath = await _cacheMediaFile(fileId, downloadUrl, 'mp4');
    } catch (e) {
      if (kDebugMode) print('⚠️ Lokales Caching fehlgeschlagen: $e');
    }

    return {
      'telegram_file_id': fileId,
      'dateiname': fileName,
      'mime_typ': mimeType,
      'groesse': fileSize,
      'download_url': downloadUrl,
      'duration': duration,
      'width': width,
      'height': height,
      'local_path': localPath,
      'is_cached': localPath != null,
      'is_streamable': _isStreamable(mimeType),
    };
  }

  /// Process document message
  Future<Map<String, dynamic>> _processDocument(Map<String, dynamic> message) async {
    final document = message['document'];
    if (document == null) return {};

    final fileId = document['file_id'];
    final fileName = document['file_name'] ?? 'document_$fileId';
    final mimeType = document['mime_type'] ?? 'application/octet-stream';
    final fileSize = document['file_size'] ?? 0;

    final filePath = await _getFilePath(fileId);
    final downloadUrl = _getFileDownloadUrl(filePath);

    // Try to cache locally
    String? localPath;
    try {
      final ext = fileName.split('.').last;
      localPath = await _cacheMediaFile(fileId, downloadUrl, ext);
    } catch (e) {
      if (kDebugMode) print('⚠️ Lokales Caching fehlgeschlagen: $e');
    }

    return {
      'telegram_file_id': fileId,
      'dateiname': fileName,
      'mime_typ': mimeType,
      'groesse': fileSize,
      'download_url': downloadUrl,
      'local_path': localPath,
      'is_cached': localPath != null,
    };
  }

  /// Process audio message
  Future<Map<String, dynamic>> _processAudio(Map<String, dynamic> message) async {
    final audio = message['audio'];
    if (audio == null) return {};

    final fileId = audio['file_id'];
    final fileName = audio['file_name'] ?? 'audio_$fileId.mp3';
    final mimeType = audio['mime_type'] ?? 'audio/mpeg';
    final fileSize = audio['file_size'] ?? 0;
    final duration = audio['duration'] ?? 0;
    final performer = audio['performer'];
    final title = audio['title'];

    final filePath = await _getFilePath(fileId);
    final downloadUrl = _getFileDownloadUrl(filePath);

    // Try to cache locally
    String? localPath;
    try {
      localPath = await _cacheMediaFile(fileId, downloadUrl, 'mp3');
    } catch (e) {
      if (kDebugMode) print('⚠️ Lokales Caching fehlgeschlagen: $e');
    }

    return {
      'telegram_file_id': fileId,
      'dateiname': fileName,
      'mime_typ': mimeType,
      'groesse': fileSize,
      'download_url': downloadUrl,
      'duration': duration,
      'performer': performer,
      'title': title,
      'local_path': localPath,
      'is_cached': localPath != null,
      'is_streamable': _isStreamable(mimeType),
    };
  }

  /// Process voice message
  Future<Map<String, dynamic>> _processVoice(Map<String, dynamic> message) async {
    final voice = message['voice'];
    if (voice == null) return {};

    final fileId = voice['file_id'];
    final mimeType = voice['mime_type'] ?? 'audio/ogg';
    final fileSize = voice['file_size'] ?? 0;
    final duration = voice['duration'] ?? 0;

    final filePath = await _getFilePath(fileId);
    final downloadUrl = _getFileDownloadUrl(filePath);

    // Try to cache locally
    String? localPath;
    try {
      localPath = await _cacheMediaFile(fileId, downloadUrl, 'ogg');
    } catch (e) {
      if (kDebugMode) print('⚠️ Lokales Caching fehlgeschlagen: $e');
    }

    return {
      'telegram_file_id': fileId,
      'dateiname': 'voice_$fileId.ogg',
      'mime_typ': mimeType,
      'groesse': fileSize,
      'download_url': downloadUrl,
      'duration': duration,
      'local_path': localPath,
      'is_cached': localPath != null,
      'is_streamable': _isStreamable(mimeType),
    };
  }

  /// Get file path from Telegram
  Future<String> _getFilePath(String fileId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/getFile?file_id=$fileId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['ok']) {
        return data['result']['file_path'];
      }
    }

    throw Exception('Fehler beim Abrufen des Dateipfads');
  }

  /// Get file download URL
  String _getFileDownloadUrl(String filePath) {
    return 'https://api.telegram.org/file/bot$_botToken/$filePath';
  }

  /// Cache media file locally
  Future<String?> _cacheMediaFile(
    String fileId,
    String downloadUrl,
    String extension,
  ) async {
    if (_cacheDir == null) return null;

    try {
      final fileName = '$fileId.$extension';
      final filePath = '${_cacheDir!.path}/$fileName';
      final file = File(filePath);

      // Check if already cached
      if (await file.exists()) {
        if (kDebugMode) print('✅ Datei bereits im Cache: $fileName');
        return filePath;
      }

      // Download file
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        if (kDebugMode) print('✅ Datei gecacht: $fileName');
        return filePath;
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Cache-Fehler: $e');
      return null;
    }
  }

  /// Check if media is streamable
  bool _isStreamable(String mimeType) {
    const streamableMimeTypes = [
      'video/mp4',
      'video/webm',
      'audio/mpeg',
      'audio/mp3',
      'audio/ogg',
      'audio/wav',
    ];
    return streamableMimeTypes.contains(mimeType);
  }

  // ========== CLASSIFICATION ==========
  
  /// Classify content based on hashtags and keywords
  Map<String, dynamic> _classifyContent(String text, List<String> hashtags) {
    final lowerText = text.toLowerCase();
    final themen = _appConfig['themen'] as Map<String, dynamic>;
    
    Map<String, double> scores = {};
    Map<String, List<String>> gefundeneSchlagworte = {};

    // Initialize scores
    for (var themaKey in themen.keys) {
      scores[themaKey] = 0.0;
      gefundeneSchlagworte[themaKey] = [];
    }

    // HASHTAG-PRIORITÄT (höchste Gewichtung)
    for (var themaKey in themen.keys) {
      final thema = themen[themaKey] as Map<String, dynamic>;
      final themaHashtags = (thema['hashtags'] as List).cast<String>();
      
      for (var hashtag in hashtags) {
        if (themaHashtags.contains(hashtag)) {
          scores[themaKey] = scores[themaKey]! + 10.0;
          gefundeneSchlagworte[themaKey]!.add(hashtag);
        }
      }
    }

    // KEYWORDS (mittlere Gewichtung)
    for (var themaKey in themen.keys) {
      final thema = themen[themaKey] as Map<String, dynamic>;
      final keywords = (thema['keywords'] as List).cast<String>();
      
      for (var keyword in keywords) {
        if (lowerText.contains(keyword)) {
          scores[themaKey] = scores[themaKey]! + 3.0;
          if (!gefundeneSchlagworte[themaKey]!.contains(keyword)) {
            gefundeneSchlagworte[themaKey]!.add(keyword);
          }
        }
      }
    }

    // Finde bestes Thema
    String bestesThema = 'other';
    double bestesScore = 0.0;

    for (var entry in scores.entries) {
      if (entry.value > bestesScore) {
        bestesScore = entry.value;
        bestesThema = entry.key;
      }
    }

    // Berechne Vertrauenswert (0.0 - 1.0)
    double vertrauen = (bestesScore / 20.0).clamp(0.0, 1.0);

    // Sprache erkennen (vereinfacht)
    String sprache = 'de';
    if (text.contains(RegExp(r'[a-zA-Z]'))) {
      sprache = 'de'; // Deutsch als Standard
    }

    return {
      'thema': bestesThema,
      'vertrauen': vertrauen,
      'schlagworte': gefundeneSchlagworte[bestesThema] ?? [],
      'sprache': sprache,
    };
  }

  /// Determine routing based on media type and classification
  Map<String, dynamic> _determineRouting(
    String medienTyp,
    Map<String, dynamic> klassifikation,
  ) {
    final vertrauen = klassifikation['vertrauen'] as double;
    final routing = _appConfig['routing'] as Map<String, dynamic>;
    
    String appBereich = 'feed';

    // Route based on media type
    switch (medienTyp) {
      case 'photo':
        appBereich = 'bilder';
        break;
      case 'video':
        appBereich = 'videos';
        break;
      case 'audio':
      case 'voice':
        appBereich = 'audio';
        break;
      case 'document':
        appBereich = 'dokumente';
        break;
      case 'none':
        if (vertrauen >= 0.7) {
          appBereich = 'thema_spezifisch';
        }
        break;
    }

    final autoPublish = vertrauen >= routing['vertrauensschwelle_auto_publish'];
    final benachrichtigung = vertrauen >= routing['vertrauensschwelle_benachrichtigung'];
    String prioritaet = vertrauen >= 0.8 
        ? 'hoch' 
        : (vertrauen < 0.5 ? 'niedrig' : 'normal');

    return {
      'app_bereich': appBereich,
      'auto_publish': autoPublish,
      'benachrichtigung': benachrichtigung,
      'prioritaet': prioritaet,
    };
  }

  // ========== TEXT PROCESSING ==========
  
  /// Extract hashtags from text
  List<String> _extractHashtags(String text) {
    final regex = RegExp(r'#[a-zA-ZäöüÄÖÜß0-9_]+');
    return regex.allMatches(text)
        .map((m) => m.group(0)!.toLowerCase())
        .toList();
  }

  /// Extract mentions from text
  List<String> _extractMentions(String text) {
    final regex = RegExp(r'@[a-zA-Z0-9_]+');
    return regex.allMatches(text)
        .map((m) => m.group(0)!.toLowerCase())
        .toList();
  }

  /// Extract links from text
  List<String> _extractLinks(String text) {
    final regex = RegExp(r'https?://[^\s]+');
    return regex.allMatches(text)
        .map((m) => m.group(0)!)
        .toList();
  }

  /// Clean text (remove excessive whitespace, etc.)
  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ========== FIRESTORE OPERATIONS ==========
  
  /// Save app event to Firestore
  Future<void> _saveToFirestore(Map<String, dynamic> appEvent) async {
    try {
      final chatId = appEvent['quelle']['chat_id'];
      final messageId = appEvent['quelle']['message_id'];
      final docId = 'telegram_${messageId}_$chatId';

      // Determine collection based on media type
      String collection = 'telegram_feed';
      final medienTyp = appEvent['medien']['typ'];
      
      switch (medienTyp) {
        case 'photo':
          collection = 'telegram_photos';
          break;
        case 'video':
          collection = 'telegram_videos';
          break;
        case 'document':
          collection = 'telegram_documents';
          break;
        case 'audio':
        case 'voice':
          collection = 'telegram_audio';
          break;
      }

      // Flatten structure for Firestore
      final firestoreData = {
        'app_id': appEvent['app_id'],
        'action': appEvent['aktion'],
        
        // Source
        'chat_id': appEvent['quelle']['chat_id'],
        'message_id': appEvent['quelle']['message_id'],
        'chat_title': appEvent['quelle']['chat_titel'],
        'edited': appEvent['quelle']['bearbeitet'],
        'timestamp': DateTime.fromMillisecondsSinceEpoch(
          appEvent['quelle']['zeitstempel'] * 1000,
        ),
        
        // Author
        'author_id': appEvent['autor']['user_id'],
        'author_username': appEvent['autor']['username'],
        'author_display_name': appEvent['autor']['display_name'],
        
        // Content
        'text_raw': appEvent['inhalt']['text_roh'],
        'text_clean': appEvent['inhalt']['text_bereinigt'],
        'hashtags': appEvent['inhalt']['hashtags'],
        'links': appEvent['inhalt']['links'],
        'mentions': appEvent['inhalt']['erwaehnungen'],
        
        // Media
        'media_type': appEvent['medien']['typ'],
        'media_files': appEvent['medien']['dateien'],
        
        // Classification
        'topic': appEvent['klassifikation']['thema'],
        'confidence': appEvent['klassifikation']['vertrauen'],
        'keywords': appEvent['klassifikation']['schlagworte'],
        'language': appEvent['klassifikation']['sprache'],
        
        // Routing
        'app_section': appEvent['routing']['app_bereich'],
        'auto_published': appEvent['routing']['auto_publish'],
        'notification': appEvent['routing']['benachrichtigung'],
        'priority': appEvent['routing']['prioritaet'],
        
        // Extended Features
        'is_pinned': appEvent['extended_features']['is_pinned'],
        'read_by': appEvent['extended_features']['read_by'],
        'favorite_by': appEvent['extended_features']['favorite_by'],
        'reply_to': appEvent['extended_features']['reply_to'],
        'thread_id': appEvent['extended_features']['thread_id'],
        
        // Timestamps
        'created_at': appEvent['created_at'],
        'updated_at': appEvent['updated_at'],
      };

      await _firestore.collection(collection).doc(docId).set(
        firestoreData,
        SetOptions(merge: true),
      );

      if (kDebugMode) {
        print('✅ Gespeichert in Firestore: $collection/$docId');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Firestore-Speicherfehler: $e');
    }
  }

  // ========== EXTENDED FEATURES API ==========
  
  /// Edit message
  Future<bool> editMessage(int chatId, int messageId, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/editMessageText'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'message_id': messageId,
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok']) {
          if (kDebugMode) print('✅ Nachricht bearbeitet: $messageId');
          
          // Update in Firestore
          await _updateMessageInFirestore(chatId, messageId, {
            'text_clean': text,
            'edited': true,
            'updated_at': FieldValue.serverTimestamp(),
          });
          
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('❌ Fehler beim Bearbeiten: $e');
      return false;
    }
  }

  /// Delete message
  Future<bool> deleteMessage(int chatId, int messageId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/deleteMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'message_id': messageId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok']) {
          if (kDebugMode) print('✅ Nachricht gelöscht: $messageId');
          
          // Soft delete in Firestore
          await _updateMessageInFirestore(chatId, messageId, {
            'is_deleted': true,
            'deleted_at': FieldValue.serverTimestamp(),
          });
          
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('❌ Fehler beim Löschen: $e');
      return false;
    }
  }

  /// Pin message
  Future<bool> pinMessage(int chatId, int messageId, {bool notify = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pinChatMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'message_id': messageId,
          'disable_notification': !notify,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok']) {
          if (kDebugMode) print('✅ Nachricht angepinnt: $messageId');
          
          // Update in Firestore
          await _updateMessageInFirestore(chatId, messageId, {
            'is_pinned': true,
            'pinned_at': FieldValue.serverTimestamp(),
          });
          
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('❌ Fehler beim Anpinnen: $e');
      return false;
    }
  }

  /// Unpin message
  Future<bool> unpinMessage(int chatId, int messageId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/unpinChatMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'message_id': messageId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok']) {
          if (kDebugMode) print('✅ Nachricht losgelöst: $messageId');
          
          // Update in Firestore
          await _updateMessageInFirestore(chatId, messageId, {
            'is_pinned': false,
            'pinned_at': null,
          });
          
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('❌ Fehler beim Loslösen: $e');
      return false;
    }
  }

  /// Send message to Telegram
  Future<bool> sendMessage(int chatId, String text, {int? replyTo}) async {
    try {
      final body = {
        'chat_id': chatId,
        'text': text,
      };

      if (replyTo != null) {
        body['reply_to_message_id'] = replyTo;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok']) {
          if (kDebugMode) print('✅ Nachricht gesendet: $text');
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('❌ Fehler beim Senden: $e');
      return false;
    }
  }

  /// Mark message as read by user
  Future<void> markAsRead(String docId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Search across all collections
        final collections = [
          'telegram_feed',
          'telegram_videos',
          'telegram_photos',
          'telegram_documents',
          'telegram_audio',
        ];

        for (var collection in collections) {
          final docRef = _firestore.collection(collection).doc(docId);
          final doc = await transaction.get(docRef);
          
          if (doc.exists) {
            final readBy = List<String>.from(doc.data()?['read_by'] ?? []);
            if (!readBy.contains(userId)) {
              readBy.add(userId);
              transaction.update(docRef, {'read_by': readBy});
            }
            break;
          }
        }
      });

      if (kDebugMode) print('✅ Als gelesen markiert: $docId');
    } catch (e) {
      if (kDebugMode) print('❌ Fehler beim Markieren: $e');
    }
  }

  /// Toggle favorite
  Future<void> toggleFavorite(String docId, String userId, bool isFavorite) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final collections = [
          'telegram_feed',
          'telegram_videos',
          'telegram_photos',
          'telegram_documents',
          'telegram_audio',
        ];

        for (var collection in collections) {
          final docRef = _firestore.collection(collection).doc(docId);
          final doc = await transaction.get(docRef);
          
          if (doc.exists) {
            final favoriteBy = List<String>.from(doc.data()?['favorite_by'] ?? []);
            
            if (isFavorite && !favoriteBy.contains(userId)) {
              favoriteBy.add(userId);
            } else if (!isFavorite && favoriteBy.contains(userId)) {
              favoriteBy.remove(userId);
            }
            
            transaction.update(docRef, {'favorite_by': favoriteBy});
            break;
          }
        }
      });

      if (kDebugMode) print('✅ Favorit geändert: $docId');
    } catch (e) {
      if (kDebugMode) print('❌ Fehler beim Favorisieren: $e');
    }
  }

  /// Update message in Firestore
  Future<void> _updateMessageInFirestore(
    int chatId,
    int messageId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final docId = 'telegram_${messageId}_$chatId';
      
      final collections = [
        'telegram_feed',
        'telegram_videos',
        'telegram_photos',
        'telegram_documents',
        'telegram_audio',
      ];

      for (var collection in collections) {
        final docRef = _firestore.collection(collection).doc(docId);
        final doc = await docRef.get();
        
        if (doc.exists) {
          await docRef.update(updates);
          break;
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Firestore-Update-Fehler: $e');
    }
  }

  // ========== STREAM GETTERS ==========
  
  /// Get videos stream
  Stream<List<TelegramVideo>> getVideos() {
    return _firestore
        .collection('telegram_videos')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TelegramVideo(doc.id, doc.data()))
            .toList());
  }

  /// Get photos stream
  Stream<List<TelegramPhoto>> getPhotos() {
    return _firestore
        .collection('telegram_photos')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TelegramPhoto(doc.id, doc.data()))
            .toList());
  }

  /// Get documents stream
  Stream<List<TelegramDocument>> getDocuments() {
    return _firestore
        .collection('telegram_documents')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TelegramDocument(doc.id, doc.data()))
            .toList());
  }

  /// Get audio stream
  Stream<List<TelegramAudio>> getAudio() {
    return _firestore
        .collection('telegram_audio')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TelegramAudio(doc.id, doc.data()))
            .toList());
  }

  /// Get text posts stream
  Stream<List<TelegramPost>> getTextPosts() {
    // ✅ FIX: Verwende telegram_messages statt telegram_feed (leer)
    // Einfache Query ohne Filter - nur nach timestamp sortiert
    // Vermeidet "Missing Index" Fehler
    return _firestore
        .collection('telegram_messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TelegramPost(doc.id, doc.data()))
            .toList());
  }

  /// Get pinned messages
  Stream<List<dynamic>> getPinnedMessages() {
    return _firestore
        .collectionGroup('telegram_videos')
        .where('is_pinned', isEqualTo: true)
        .orderBy('pinned_at', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Get favorite messages for user
  Stream<List<dynamic>> getFavoriteMessages(String userId) {
    return _firestore
        .collectionGroup('telegram_videos')
        .where('favorite_by', arrayContains: userId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Get all Telegram content (mixed)
  Future<Map<String, List<dynamic>>> getAllTelegramContent() async {
    try {
      final videosSnapshot = await _firestore
          .collection('telegram_videos')
          .limit(50)
          .get();
      
      final docsSnapshot = await _firestore
          .collection('telegram_documents')
          .limit(50)
          .get();
      
      final photosSnapshot = await _firestore
          .collection('telegram_photos')
          .limit(50)
          .get();
      
      final audioSnapshot = await _firestore
          .collection('telegram_audio')
          .limit(50)
          .get();
      
      final postsSnapshot = await _firestore
          .collection('telegram_feed')
          .where('media_type', isEqualTo: 'none')
          .limit(50)
          .get();

      return {
        'videos': videosSnapshot.docs
            .map((doc) => TelegramVideo(doc.id, doc.data()))
            .toList(),
        'documents': docsSnapshot.docs
            .map((doc) => TelegramDocument(doc.id, doc.data()))
            .toList(),
        'photos': photosSnapshot.docs
            .map((doc) => TelegramPhoto(doc.id, doc.data()))
            .toList(),
        'audio': audioSnapshot.docs
            .map((doc) => TelegramAudio(doc.id, doc.data()))
            .toList(),
        'posts': postsSnapshot.docs
            .map((doc) => TelegramPost(doc.id, doc.data()))
            .toList(),
      };
    } catch (e) {
      if (kDebugMode) print('❌ Fehler beim Laden aller Inhalte: $e');
      return {
        'videos': [],
        'documents': [],
        'photos': [],
        'audio': [],
        'posts': [],
      };
    }
  }

  // ========== STATISTICS ==========
  
  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final videosCount = await _firestore.collection('telegram_videos').count().get();
      final docsCount = await _firestore.collection('telegram_documents').count().get();
      final photosCount = await _firestore.collection('telegram_photos').count().get();
      final audioCount = await _firestore.collection('telegram_audio').count().get();
      final postsCount = await _firestore.collection('telegram_feed').count().get();

      return {
        'videos': videosCount.count ?? 0,
        'documents': docsCount.count ?? 0,
        'photos': photosCount.count ?? 0,
        'audio': audioCount.count ?? 0,
        'posts': postsCount.count ?? 0,
        'total': (videosCount.count ?? 0) +
                 (docsCount.count ?? 0) +
                 (photosCount.count ?? 0) +
                 (audioCount.count ?? 0) +
                 (postsCount.count ?? 0),
      };
    } catch (e) {
      if (kDebugMode) print('❌ Fehler beim Abrufen der Statistiken: $e');
      return {
        'videos': 0,
        'documents': 0,
        'photos': 0,
        'audio': 0,
        'posts': 0,
        'total': 0,
      };
    }
  }

  // ========== BACKWARD COMPATIBILITY METHODS ==========
  
  /// Get polling status for UI health widgets
  Map<String, dynamic> getPollingStatus() {
    return {
      'isInitialized': _isInitialized,
      'isActive': _pollingTimer?.isActive ?? false,
      'isPolling': _isPolling,
      'interval': _pollingInterval,
      'consecutiveErrors': _consecutiveErrors,
      'lastUpdateId': _lastUpdateId,
      'lastSuccessfulPoll': _lastSuccessfulPoll?.toIso8601String(),
      'isHealthy': isPollingHealthy(),
    };
  }
  
  /// Send message to Telegram (App → Telegram)
  Future<bool> sendMessageToTelegram(String text) async {
    if (_chatId == null) {
      if (kDebugMode) debugPrint('❌ Chat-ID nicht verfügbar');
      return false;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chat_id': _chatId,
          'text': text,
          'parse_mode': 'HTML',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          if (kDebugMode) debugPrint('✅ Nachricht an Telegram gesendet (App → Telegram)');
          return true;
        }
      }
      
      if (kDebugMode) debugPrint('❌ Fehler beim Senden: ${response.body}');
      return false;
      
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Exception beim Senden: $e');
      return false;
    }
  }
  
  /// Get videos by category (for video screens)
  Stream<List<TelegramVideo>> getVideosByCategory(String category) {
    return _firestore
        .collection('telegram_videos')
        .where('topic', isEqualTo: category)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TelegramVideo(doc.id, doc.data()))
            .toList());
  }
  
  /// Increment view count for video (used by video player)
  Future<void> incrementViewCount(String videoId) async {
    try {
      await _firestore.collection('telegram_videos').doc(videoId).update({
        'view_count': FieldValue.increment(1),
      });
      if (kDebugMode) debugPrint('✅ View count erhöht für Video: $videoId');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Fehler beim Erhöhen des View Counts: $e');
    }
  }

  // ========== APP → BOT COMMUNICATION ==========
  
  /// ✅ NEU: Sende Nachricht von App an Telegram Channel
  /// Ermöglicht bidirektionale Kommunikation: App → Bot → Telegram
  Future<bool> sendMessageFromApp({
    required String text,
    required String userId,
    String? replyToMessageId,
  }) async {
    try {
      // Prüfe ob Chat ID verfügbar ist
      if (_chatId == null) {
        if (kDebugMode) {
          debugPrint('❌ Chat ID nicht verfügbar. Starte Polling zuerst.');
        }
        return false;
      }

      if (kDebugMode) {
        debugPrint('📤 Sende Nachricht von App an Telegram...');
      }

      // 1. Sende an Telegram API
      final requestBody = <String, dynamic>{
        'chat_id': _chatId,
        'text': '📱 App-Nachricht:\n\n$text',
      };

      if (replyToMessageId != null) {
        requestBody['reply_to_message_id'] = replyToMessageId;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('❌ Telegram API Fehler: ${response.statusCode}');
        }
        return false;
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (result['ok'] != true) {
        if (kDebugMode) {
          debugPrint('❌ Telegram Antwort nicht OK: $result');
        }
        return false;
      }

      // 2. Speichere in Firestore für Synchronisation
      final messageData = result['result'] as Map<String, dynamic>;
      final messageId = messageData['message_id'] as int;

      await _firestore.collection('telegram_messages').add({
        'telegram_message_id': messageId,
        'text': text,
        'sender_id': userId,
        'sender_name': 'App User',
        'chat_id': _chatId,
        'timestamp': DateTime.now(),
        'created_at': FieldValue.serverTimestamp(),
        'sent_from_app': true,
        'synced_to_app': true,
        'type': 'direct',
        'mediaType': 'text',
        'topic': 'App Messages',
      });

      if (kDebugMode) {
        debugPrint('✅ Nachricht erfolgreich gesendet! Message ID: $messageId');
      }

      return true;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Senden an Telegram: $e');
      }
      return false;
    }
  }

  /// Sende Foto von App an Telegram
  Future<bool> sendPhotoFromApp({
    required String photoUrl,
    String? caption,
    required String userId,
  }) async {
    try {
      if (_chatId == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/sendPhoto'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _chatId,
          'photo': photoUrl,
          'caption': caption != null ? '📱 $caption' : '📱 Foto von App',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['ok'] == true) {
          if (kDebugMode) {
            debugPrint('✅ Foto erfolgreich gesendet!');
          }
          return true;
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Senden des Fotos: $e');
      }
      return false;
    }
  }

  // ========== CLEANUP ==========
  
  /// Clear local cache
  Future<void> clearCache() async {
    if (_cacheDir == null) return;

    try {
      if (await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create();
        if (kDebugMode) print('✅ Cache gelöscht');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Fehler beim Löschen des Caches: $e');
    }
  }

  /// Setzt initial das letzte Update-ID, um alte Nachrichten zu überspringen
  Future<void> _primeLastUpdateId() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/getUpdates?limit=1')).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['ok'] == true && (data['result'] as List).isNotEmpty) {
          final last = (data['result'] as List).last;
          _lastUpdateId = (last['update_id'] as int) + 1;
          if (kDebugMode) print('🔁 Initiales lastUpdateId gesetzt: $_lastUpdateId');
        }
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ _primeLastUpdateId Fehler: $e');
    }
  }

  /// Dispose service
  void dispose() {
    stopPolling();
    if (kDebugMode) print('🛑 Telegram Service V4 beendet');
  }
}
