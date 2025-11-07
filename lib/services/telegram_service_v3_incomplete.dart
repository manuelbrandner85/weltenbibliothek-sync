import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/telegram_models.dart';

/// Telegram Service v3.0 - Intelligente Synchronisation
/// 
/// ZWECK:
/// Verarbeitet eingehende Telegram-Updates, klassifiziert sie nach Themen und Dateitypen,
/// und bereitet sie für die nahtlose Integration in die App-Bereiche vor.
/// 
/// FEATURES:
/// - Intelligente Themen-Klassifikation (Hashtag-Priorität → Keywords → Fallback)
/// - Smart Routing (Medientyp → Thema → App-Bereich)
/// - Bidirektionale Chat-Synchronisation (Telegram ↔ App)
/// - Strukturierte App-Events für nahtlose Integration
/// - Auto-Publikations-Status basierend auf Vertrauenswert
class TelegramService {
  // ========== CONFIGURATION ==========
  
  static const String _botToken = '7826102549:AAHMOTvl13GlR2vousHVTE4jO0xTYuVlS7k';
  static const String _botUsername = '@weltenbibliothek_bot';
  static const String _chatUsername = '@Weltenbibliothekchat';
  static const String _channelUsername = '@ArchivWeltenBibliothek';
  static const String _baseUrl = 'https://api.telegram.org/bot$_botToken';
  
  // Gruppen & Channels
  static const String _targetGroupTitle = 'Weltenbibliothekchat';
  static const bool _syncAllGroups = false;
  
  // Chat & Channel IDs
  String? _chatId;
  String? _channelId;
  
  // Long Polling
  Timer? _pollingTimer;
  int _lastUpdateId = 0;
  bool _isInitialized = false;
  
  // Polling Stability
  int _consecutiveErrors = 0;
  int _pollingInterval = 2;
  bool _isPolling = false;
  DateTime? _lastSuccessfulPoll;
  static const int _maxConsecutiveErrors = 5;
  static const int _maxPollingInterval = 60;
  
  // Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ========== APP CONFIGURATION ==========
  
  /// App-Konfiguration für intelligente Klassifikation und Routing
  static const Map<String, dynamic> _appConfig = {
    'themen': {
      'lostCivilizations': {
        'label': 'Verlorene Zivilisationen',
        'hashtags': ['#atlantis', '#lemuria', '#mu', '#hyperborea'],
        'keywords': ['atlantis', 'lemuria', 'versunkene', 'antike zivilisation'],
        'prioritaet': 'hoch',
      },
      'alienContact': {
        'label': 'Außerirdischer Kontakt',
        'hashtags': ['#alien', '#ufo', '#extraterrestrisch', '#kontakt'],
        'keywords': ['alien', 'außerirdisch', 'ufo', 'entführung', 'kontakt'],
        'prioritaet': 'hoch',
      },
      'conspiracy': {
        'label': 'Verschwörungstheorien',
        'hashtags': ['#verschwörung', '#conspiracy', '#geheim'],
        'keywords': ['verschwörung', 'geheim', 'illuminati', 'deep state'],
        'prioritaet': 'normal',
      },
      'ancientTech': {
        'label': 'Antike Technologie',
        'hashtags': ['#antike technologie', '#vimana', '#kristallschädel'],
        'keywords': ['antike technologie', 'vimana', 'kristall', 'artefakt'],
        'prioritaet': 'hoch',
      },
      'paranormal': {
        'label': 'Paranormales',
        'hashtags': ['#paranormal', '#geister', '#übernatürlich'],
        'keywords': ['paranormal', 'geister', 'übernatürlich', 'spuk'],
        'prioritaet': 'normal',
      },
      'esotericism': {
        'label': 'Esoterik',
        'hashtags': ['#esoterik', '#spirituell', '#mystik'],
        'keywords': ['esoterik', 'spirituell', 'mystik', 'meditation'],
        'prioritaet': 'normal',
      },
      'secretSocieties': {
        'label': 'Geheimgesellschaften',
        'hashtags': ['#geheimgesellschaft', '#freimaurer', '#templer'],
        'keywords': ['geheimgesellschaft', 'freimaurer', 'templer', 'orden'],
        'prioritaet': 'normal',
      },
      'prophecies': {
        'label': 'Prophezeiungen',
        'hashtags': ['#prophezeiung', '#vorhersage', '#apokalypse'],
        'keywords': ['prophezeiung', 'vorhersage', 'apokalypse', 'nostradamus'],
        'prioritaet': 'normal',
      },
      'cryptozoology': {
        'label': 'Kryptozoologie',
        'hashtags': ['#kryptozoologie', '#bigfoot', '#nessie'],
        'keywords': ['kryptozoologie', 'bigfoot', 'yeti', 'seeungeheuer'],
        'prioritaet': 'niedrig',
      },
      'other': {
        'label': 'Sonstiges',
        'hashtags': [],
        'keywords': [],
        'prioritaet': 'niedrig',
      },
    },
    'routing': {
      'vertrauensschwelle_auto_publish': 0.7,
      'vertrauensschwelle_benachrichtigung': 0.8,
    },
  };
  
  // ========== SINGLETON ==========
  
  static final TelegramService _instance = TelegramService._internal();
  factory TelegramService() => _instance;
  TelegramService._internal();
  
  // ========== INITIALIZATION ==========
  
  /// Initialisiert den Telegram Service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ TelegramService bereits initialisiert');
      return;
    }
    
    try {
      debugPrint('🔄 TelegramService v3.0: Initialisierung startet...');
      
      // 1. Bot-Info abrufen
      await _getBotInfo();
      
      // 2. Chat & Channel IDs auflösen
      await _getChatId();
      await _getChannelId();
      
      // 3. Long Polling starten
      _startPolling();
      
      _isInitialized = true;
      debugPrint('✅ TelegramService v3.0 erfolgreich initialisiert');
      
    } catch (e, stackTrace) {
      debugPrint('❌ TelegramService Initialisierungsfehler: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
  
  /// Ruft Bot-Informationen ab
  Future<void> _getBotInfo() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/getMe'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          final botInfo = data['result'];
          debugPrint('✅ Bot verbunden: @${botInfo['username']}');
          debugPrint('   Bot Name: ${botInfo['first_name']}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fehler beim Abrufen der Bot-Info: $e');
    }
  }
  
  /// Ruft Chat-ID für @Weltenbibliothekchat ab
  Future<void> _getChatId() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/getChat?chat_id=$_chatUsername'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          _chatId = data['result']['id'].toString();
          debugPrint('✅ Chat-ID aufgelöst: $_chatUsername → $_chatId');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fehler beim Auflösen der Chat-ID: $e');
    }
  }
  
  /// Ruft Channel-ID für @ArchivWeltenBibliothek ab
  Future<void> _getChannelId() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/getChat?chat_id=$_channelUsername'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          _channelId = data['result']['id'].toString();
          debugPrint('✅ Channel-ID aufgelöst: $_channelUsername → $_channelId');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fehler beim Auflösen der Channel-ID: $e');
    }
  }
  
  // ========== LONG POLLING ==========
  
  /// Startet Long Polling
  void _startPolling() {
    _pollingTimer?.cancel();
    
    _pollingTimer = Timer.periodic(Duration(seconds: _pollingInterval), (timer) {
      _pollUpdates();
    });
    
    debugPrint('✅ Polling gestartet (Intervall: ${_pollingInterval}s)');
  }
  
  /// Pollt für neue Updates
  static Future<void> pollForUpdates() async {
    final instance = TelegramService();
    await instance._pollUpdates();
  }
  
  Future<void> _pollUpdates() async {
    if (_isPolling) {
      debugPrint('⏭️ Polling bereits aktiv, überspringe...');
      return;
    }
    
    _isPolling = true;
    
    try {
      final offset = _lastUpdateId == 0 ? 0 : _lastUpdateId + 1;
      
      final response = await http.get(
        Uri.parse('$_baseUrl/getUpdates?offset=$offset&timeout=30&allowed_updates=["message","channel_post","edited_message","edited_channel_post"]'),
      ).timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          throw TimeoutException('Telegram API Timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          final updates = data['result'] as List;
          
          if (updates.isNotEmpty) {
            debugPrint('📬 Neue Updates empfangen: ${updates.length} Updates');
            
            for (var update in updates) {
              await _processUpdateIntelligent(update);
              _lastUpdateId = update['update_id'];
            }
          }
          
          _onPollSuccess();
          
        } else {
          debugPrint('⚠️ Telegram API Fehler: ${data['description']}');
          _onPollError(data['description']);
        }
      } else {
        debugPrint('❌ HTTP Fehler: ${response.statusCode}');
        _onPollError('HTTP ${response.statusCode}');
      }
      
    } on TimeoutException catch (e) {
      debugPrint('⏱️ Timeout: $e');
      _onPollError('Timeout');
      
    } catch (e) {
      debugPrint('❌ Polling-Fehler: $e');
      _onPollError(e.toString());
      
    } finally {
      _isPolling = false;
    }
  }
  
  /// Behandelt erfolgreichen Poll
  void _onPollSuccess() {
    _lastSuccessfulPoll = DateTime.now();
    
    if (_consecutiveErrors > 0) {
      debugPrint('✅ Verbindung wiederhergestellt!');
      _consecutiveErrors = 0;
    }
    
    if (_pollingInterval > 2) {
      _pollingInterval = 2;
      _restartPollingWithNewInterval();
    }
  }
  
  /// Behandelt Polling-Fehler mit Exponential Backoff
  void _onPollError(String error) {
    _consecutiveErrors++;
    
    debugPrint('⚠️ Fehler #$_consecutiveErrors: $error');
    
    if (_consecutiveErrors >= 2) {
      final newInterval = (_pollingInterval * 2).clamp(2, _maxPollingInterval);
      
      if (newInterval != _pollingInterval) {
        _pollingInterval = newInterval;
        debugPrint('🔄 Polling-Intervall erhöht auf ${_pollingInterval}s');
        _restartPollingWithNewInterval();
      }
    }
    
    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      debugPrint('🚨 WARNUNG: $_consecutiveErrors aufeinanderfolgende Fehler!');
    }
  }
  
  /// Startet Polling mit neuem Intervall neu
  void _restartPollingWithNewInterval() {
    _pollingTimer?.cancel();
    
    _pollingTimer = Timer.periodic(Duration(seconds: _pollingInterval), (timer) {
      _pollUpdates();
    });
  }
  
  /// Health-Check
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
  
  /// Gibt Polling-Status zurück
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
  
  // ========== INTELLIGENTE UPDATE-VERARBEITUNG ==========
  
  /// Verarbeitet Telegram Update intelligent nach neuer Spezifikation
  Future<void> _processUpdateIntelligent(Map<String, dynamic> update) async {
    try {
      final updateId = update['update_id'];
      
      // 1. VALIDIERUNG: Ignoriere System-Nachrichten
      if (!_isValidUpdate(update)) {
        debugPrint('⏭️ Update #$updateId: System-Nachricht ignoriert');
        return;
      }
      
      // 2. Extrahiere Message oder Channel-Post
      Map<String, dynamic>? message;
      bool isEdited = false;
      
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
      
      if (message == null) {
        debugPrint('⏭️ Update #$updateId: Keine verwertbare Nachricht');
        return;
      }
      
      // 3. ERSTELLE APP-EVENT
      final appEvent = await _createAppEvent(message, isEdited);
      
      debugPrint('📊 App-Event erstellt:');
      debugPrint('   Aktion: ${appEvent['aktion']}');
      debugPrint('   Thema: ${appEvent['klassifikation']['thema']}');
      debugPrint('   Vertrauen: ${appEvent['klassifikation']['vertrauen']}');
      debugPrint('   Routing: ${appEvent['routing']['app_bereich']}');
      
      // 4. VERARBEITE basierend auf Aktion
      if (appEvent['aktion'] == 'erstellen') {
        await _storeAppEvent(appEvent);
      } else if (appEvent['aktion'] == 'aktualisieren') {
        await _updateAppEvent(appEvent);
      } else {
        debugPrint('⏭️ Aktion "ignorieren" - Event nicht gespeichert');
      }
      
      // 5. BIDIREKTIONALE CHAT-SYNCHRONISATION (ZWINGEND)
      await _syncToAppChat(message);
      
    } catch (e, stackTrace) {
      debugPrint('❌ Fehler bei intelligenter Update-Verarbeitung: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
  
  /// Validiert ob Update verarbeitet werden soll
  bool _isValidUpdate(Map<String, dynamic> update) {
    // Ignoriere Updates ohne Nachrichten-Content
    if (update['message'] == null && 
        update['edited_message'] == null && 
        update['channel_post'] == null && 
        update['edited_channel_post'] == null) {
      return false;
    }
    
    // Ignoriere System-Nachrichten (neue Mitglieder, etc.)
    final message = update['message'] ?? 
                   update['edited_message'] ?? 
                   update['channel_post'] ?? 
                   update['edited_channel_post'];
    
    if (message['new_chat_members'] != null ||
        message['left_chat_member'] != null ||
        message['new_chat_title'] != null) {
      return false;
    }
    
    return true;
  }
  
  // ========== APP-EVENT ERSTELLUNG ==========
  
  /// Erstellt strukturiertes App-Event aus Telegram-Nachricht
  Future<Map<String, dynamic>> _createAppEvent(
    Map<String, dynamic> message,
    bool isEdited,
  ) async {
    // 1. BASIS-METADATEN extrahieren
    final chat = message['chat'];
    final from = message['from'];
    final messageId = message['message_id'];
    final date = message['date'];
    
    final chatId = chat['id'].toString();
    final chatTitle = chat['title'] ?? chat['username'] ?? 'Private Chat';
    final chatType = chat['type'];
    
    final userId = from != null ? from['id'].toString() : 'unknown';
    final username = from != null ? (from['username'] ?? '') : '';
    final displayName = from != null ? (from['first_name'] ?? 'Unbekannt') : 'System';
    
    // 2. TEXTINHALT analysieren
    final textRoh = message['text'] ?? message['caption'] ?? '';
    final textBereinigt = _cleanText(textRoh);
    final hashtags = _extractHashtags(textRoh);
    final links = _extractLinks(textRoh);
    final erwaehnungen = _extractMentions(textRoh);
    
    // 3. MEDIEN verarbeiten
    final medienInfo = await _processMedia(message);
    
    // 4. KLASSIFIZIERUNG (Hashtag-Priorität → Keywords → Fallback)
    final klassifikation = _classifyContent(textRoh, hashtags);
    
    // 5. ROUTING bestimmen
    final routing = _determineRouting(medienInfo['typ'], klassifikation);
    
    // 6. AKTION bestimmen
    String aktion = 'erstellen';
    if (isEdited) {
      aktion = 'aktualisieren';
    }
    
    // 7. APP-ID generieren
    final appId = 'telegram_${chatId}_$messageId';
    
    // 8. STRUKTURIERTES APP-EVENT
    return {
      'aktion': aktion,
      'app_id': appId,
      'quelle': {
        'plattform': 'telegram',
        'chat_id': chatId,
        'message_id': messageId.toString(),
        'chat_titel': chatTitle,
        'bearbeitet': isEdited,
        'zeitstempel': DateTime.fromMillisecondsSinceEpoch(date * 1000).toIso8601String(),
      },
      'autor': {
        'user_id': userId,
        'username': username,
        'display_name': displayName,
      },
      'inhalt': {
        'text_roh': textRoh,
        'text_bereinigt': textBereinigt,
        'hashtags': hashtags,
        'links': links,
        'erwaehnungen': erwaehnungen,
      },
      'medien': medienInfo,
      'klassifikation': klassifikation,
      'routing': routing,
    };
  }
  
  // ========== TEXT-ANALYSE ==========
  
  /// Bereinigt Text von Formatierung
  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTML-Tags
        .replaceAll(RegExp(r'\s+'), ' ') // Mehrfache Leerzeichen
        .trim();
  }
  
  /// Extrahiert Hashtags
  List<String> _extractHashtags(String text) {
    final regex = RegExp(r'#\w+');
    return regex.allMatches(text).map((m) => m.group(0)!.toLowerCase()).toList();
  }
  
  /// Extrahiert Links
  List<String> _extractLinks(String text) {
    final regex = RegExp(r'https?://[^\s]+');
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }
  
  /// Extrahiert Erwähnungen
  List<String> _extractMentions(String text) {
    final regex = RegExp(r'@\w+');
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }
  
  // ========== MEDIEN-VERARBEITUNG ==========
  
  /// Verarbeitet Medien und erstellt Medien-Info
  Future<Map<String, dynamic>> _processMedia(Map<String, dynamic> message) async {
    String medienTyp = 'text';
    List<Map<String, dynamic>> dateien = [];
    
    // Video
    if (message['video'] != null) {
      medienTyp = 'video';
      final video = message['video'];
      dateien.add({
        'telegram_file_id': video['file_id'],
        'dateiname': video['file_name'] ?? 'video.mp4',
        'mime_typ': video['mime_type'] ?? 'video/mp4',
        'groesse': video['file_size'] ?? 0,
        'download_url': await _getFileUrl(video['file_id']),
      });
    }
    
    // Dokument
    else if (message['document'] != null) {
      medienTyp = 'dokument';
      final doc = message['document'];
      dateien.add({
        'telegram_file_id': doc['file_id'],
        'dateiname': doc['file_name'] ?? 'document',
        'mime_typ': doc['mime_type'] ?? 'application/octet-stream',
        'groesse': doc['file_size'] ?? 0,
        'download_url': await _getFileUrl(doc['file_id']),
      });
    }
    
    // Foto
    else if (message['photo'] != null) {
      medienTyp = 'bild';
      final photos = message['photo'] as List;
      if (photos.isNotEmpty) {
        final photo = photos.last; // Höchste Auflösung
        dateien.add({
          'telegram_file_id': photo['file_id'],
          'dateiname': 'photo.jpg',
          'mime_typ': 'image/jpeg',
          'groesse': photo['file_size'] ?? 0,
          'download_url': await _getFileUrl(photo['file_id']),
        });
      }
    }
    
    // Audio
    else if (message['audio'] != null) {
      medienTyp = 'audio';
      final audio = message['audio'];
      dateien.add({
        'telegram_file_id': audio['file_id'],
        'dateiname': audio['file_name'] ?? audio['title'] ?? 'audio.mp3',
        'mime_typ': audio['mime_type'] ?? 'audio/mpeg',
        'groesse': audio['file_size'] ?? 0,
        'download_url': await _getFileUrl(audio['file_id']),
      });
    }
    
    return {
      'typ': medienTyp,
      'dateien': dateien,
    };
  }
  
  /// Holt File-URL von Telegram
  Future<String?> _getFileUrl(String fileId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/getFile?file_id=$fileId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          final filePath = data['result']['file_path'];
          return 'https://api.telegram.org/file/bot$_botToken/$filePath';
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fehler beim Abrufen der File-URL: $e');
    }
    return null;
  }
  
  // FORTSETZUNG FOLGT... (zu lang für einen Response)
  // ========== KLASSIFIKATION ==========
  
  /// Klassifiziert Inhalt intelligent
  /// Hierarchie: 1. Hashtag-Priorität → 2. Keywords → 3. Fallback
  Map<String, dynamic> _classifyContent(String text, List<String> hashtags) {
    final lowerText = text.toLowerCase();
    final themen = _appConfig['themen'] as Map<String, dynamic>;
    
    // SCORING-SYSTEM
    Map<String, double> scores = {};
    Map<String, List<String>> gefundeneSchlagworte = {};
    
    for (var themaKey in themen.keys) {
      scores[themaKey] = 0.0;
      gefundeneSchlagworte[themaKey] = [];
      
      final thema = themen[themaKey] as Map<String, dynamic>;
      
      // 1. HASHTAG-PRIORITÄT (Höchste Gewichtung)
      final themaHashtags = (thema['hashtags'] as List).cast<String>();
      for (var hashtag in hashtags) {
        if (themaHashtags.contains(hashtag)) {
          scores[themaKey] = scores[themaKey]! + 10.0; // Starke Gewichtung
          gefundeneSchlagworte[themaKey]!.add(hashtag);
        }
      }
      
      // 2. KEYWORDS (Mittlere Gewichtung)
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
    
    // FINDE THEMA MIT HÖCHSTEM SCORE
    String bestesThema = 'other';
    double bestesScore = 0.0;
    
    scores.forEach((thema, score) {
      if (score > bestesScore) {
        bestesScore = score;
        bestesThema = thema;
      }
    });
    
    // BERECHNE VERTRAUENSWERT (0.0 - 1.0)
    double vertrauen = 0.5; // Fallback
    if (bestesScore > 0) {
      // Je mehr Matches, desto höher das Vertrauen
      vertrauen = (bestesScore / 20.0).clamp(0.0, 1.0);
    }
    
    // SPRACH-ERKENNUNG (einfach)
    String? sprache;
    if (RegExp(r'[äöüß]').hasMatch(lowerText)) {
      sprache = 'de';
    } else if (RegExp(r'[a-z]').hasMatch(lowerText)) {
      sprache = 'en';
    }
    
    return {
      'thema': bestesThema,
      'vertrauen': vertrauen,
      'schlagworte': gefundeneSchlagworte[bestesThema] ?? [],
      'sprache': sprache,
    };
  }
  
  // ========== ROUTING ==========
  
  /// Bestimmt App-Routing basierend auf Medientyp und Klassifikation
  Map<String, dynamic> _determineRouting(
    String medienTyp,
    Map<String, dynamic> klassifikation,
  ) {
    final vertrauen = klassifikation['vertrauen'] as double;
    final routingConfig = _appConfig['routing'] as Map<String, dynamic>;
    
    // APP-BEREICH basierend auf Medientyp
    String appBereich = 'feed'; // Default
    
    switch (medienTyp) {
      case 'bild':
        appBereich = 'bilder';
        break;
      case 'video':
        appBereich = 'videos';
        break;
      case 'audio':
        appBereich = 'audio';
        break;
      case 'dokument':
        appBereich = 'dokumente';
        break;
      case 'text':
        // Bei hohem Vertrauen: Thema-spezifischer Bereich
        if (vertrauen >= 0.7) {
          appBereich = 'thema_spezifisch';
        } else {
          appBereich = 'feed';
        }
        break;
    }
    
    // AUTO-PUBLISH basierend auf Vertrauenswert
    final autoPublish = vertrauen >= routingConfig['vertrauensschwelle_auto_publish'];
    
    // BENACHRICHTIGUNG bei hohem Vertrauen
    final benachrichtigung = vertrauen >= routingConfig['vertrauensschwelle_benachrichtigung'];
    
    // PRIORITÄT basierend auf Vertrauen
    String prioritaet = 'normal';
    if (vertrauen >= 0.8) {
      prioritaet = 'hoch';
    } else if (vertrauen < 0.5) {
      prioritaet = 'niedrig';
    }
    
    return {
      'app_bereich': appBereich,
      'auto_publish': autoPublish,
      'benachrichtigung': benachrichtigung,
      'prioritaet': prioritaet,
    };
  }
  
  // ========== STORAGE ==========
  
  /// Speichert App-Event in Firestore
  Future<void> _storeAppEvent(Map<String, dynamic> appEvent) async {
    try {
      final appBereich = appEvent['routing']['app_bereich'];
      final medienTyp = appEvent['medien']['typ'];
      
      // BESTIMME COLLECTION basierend auf App-Bereich
      String collection = 'telegram_feed'; // Default
      
      if (appBereich == 'bilder') {
        collection = 'telegram_photos';
      } else if (appBereich == 'videos') {
        collection = 'telegram_videos';
      } else if (appBereich == 'audio') {
        collection = 'telegram_audio';
      } else if (appBereich == 'dokumente') {
        collection = 'telegram_documents';
      } else if (appBereich == 'thema_spezifisch') {
        collection = 'telegram_topics';
      }
      
      // SPEICHERE Event
      await _firestore.collection(collection).doc(appEvent['app_id']).set({
        // Quelle
        'platform': appEvent['quelle']['plattform'],
        'chat_id': appEvent['quelle']['chat_id'],
        'message_id': appEvent['quelle']['message_id'],
        'chat_title': appEvent['quelle']['chat_titel'],
        'edited': appEvent['quelle']['bearbeitet'],
        'timestamp': Timestamp.fromDate(DateTime.parse(appEvent['quelle']['zeitstempel'])),
        
        // Autor
        'author_user_id': appEvent['autor']['user_id'],
        'author_username': appEvent['autor']['username'],
        'author_display_name': appEvent['autor']['display_name'],
        
        // Inhalt
        'text_raw': appEvent['inhalt']['text_roh'],
        'text_clean': appEvent['inhalt']['text_bereinigt'],
        'hashtags': appEvent['inhalt']['hashtags'],
        'links': appEvent['inhalt']['links'],
        'mentions': appEvent['inhalt']['erwaehnungen'],
        
        // Medien
        'media_type': appEvent['medien']['typ'],
        'media_files': appEvent['medien']['dateien'],
        
        // Klassifikation
        'topic': appEvent['klassifikation']['thema'],
        'confidence': appEvent['klassifikation']['vertrauen'],
        'keywords': appEvent['klassifikation']['schlagworte'],
        'language': appEvent['klassifikation']['sprache'],
        
        // Routing
        'app_section': appEvent['routing']['app_bereich'],
        'auto_published': appEvent['routing']['auto_publish'],
        'notification_sent': appEvent['routing']['benachrichtigung'],
        'priority': appEvent['routing']['prioritaet'],
        
        // Meta
        'created_at': FieldValue.serverTimestamp(),
        'indexed_at': FieldValue.serverTimestamp(),
        'view_count': 0,
      });
      
      debugPrint('✅ App-Event gespeichert: ${appEvent['app_id']} → $collection');
      
    } catch (e) {
      debugPrint('❌ Fehler beim Speichern des App-Events: $e');
    }
  }
  
  /// Aktualisiert bestehendes App-Event
  Future<void> _updateAppEvent(Map<String, dynamic> appEvent) async {
    try {
      final appBereich = appEvent['routing']['app_bereich'];
      String collection = 'telegram_feed';
      
      if (appBereich == 'bilder') {
        collection = 'telegram_photos';
      } else if (appBereich == 'videos') {
        collection = 'telegram_videos';
      } else if (appBereich == 'audio') {
        collection = 'telegram_audio';
      } else if (appBereich == 'dokumente') {
        collection = 'telegram_documents';
      } else if (appBereich == 'thema_spezifisch') {
        collection = 'telegram_topics';
      }
      
      await _firestore.collection(collection).doc(appEvent['app_id']).update({
        'text_clean': appEvent['inhalt']['text_bereinigt'],
        'edited': true,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ App-Event aktualisiert: ${appEvent['app_id']}');
      
    } catch (e) {
      debugPrint('❌ Fehler beim Aktualisieren des App-Events: $e');
    }
  }
  
  // ========== BIDIREKTIONALE CHAT-SYNCHRONISATION ==========
  
  /// Synchronisiert Nachricht ZWINGEND in App-Chat (Telegram → App)
  Future<void> _syncToAppChat(Map<String, dynamic> message) async {
    try {
      final from = message['from'];
      final text = message['text'] ?? message['caption'] ?? '';
      
      if (text.isEmpty) return; // Nur Text-Nachrichten synchronisieren
      
      final senderId = from != null ? from['id'].toString() : 'unknown';
      final senderName = from != null ? (from['first_name'] ?? 'Unbekannt') : 'System';
      final messageId = message['message_id'];
      
      // SPEICHERE in chat_rooms/telegram_chat/messages
      await _firestore
          .collection('chat_rooms')
          .doc('telegram_chat')
          .collection('messages')
          .add({
        'senderId': 'telegram_$senderId',
        'senderName': '$senderName (Telegram)',
        'senderAvatar': '',
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'telegramMessageId': messageId,
        'fromTelegram': true,
      });
      
      // UPDATE Chat-Room lastActivity
      await _firestore.collection('chat_rooms').doc('telegram_chat').set({
        'lastActivity': FieldValue.serverTimestamp(),
        'last_message': text,
        'last_message_time': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('📥 Nachricht in App-Chat synchronisiert (Telegram → App)');
      
    } catch (e) {
      debugPrint('⚠️ Fehler bei Chat-Synchronisation: $e');
    }
  }
  
  /// Sendet Nachricht an Telegram Chat (App → Telegram)
  Future<bool> sendMessageToTelegram(String text) async {
    if (_chatId == null) {
      debugPrint('❌ Chat-ID nicht verfügbar');
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
          debugPrint('✅ Nachricht an Telegram gesendet (App → Telegram)');
          return true;
        }
      }
      
      debugPrint('❌ Fehler beim Senden: ${response.body}');
      return false;
      
    } catch (e) {
      debugPrint('❌ Exception beim Senden: $e');
      return false;
    }
  }
  
  // ========== PUBLIC API ==========
  
  /// Stoppt den Service
  void dispose() {
    _pollingTimer?.cancel();
    debugPrint('🛑 TelegramService v3.0 gestoppt');
  }
  
  // ========== BACKWARD COMPATIBILITY / UI ADAPTER ==========
  
  /// Holt alle Telegram-Inhalte (für Dashboard)
  Future<Map<String, List<dynamic>>> getAllTelegramContent() async {
    try {
      final videosSnapshot = await _firestore.collection('telegram_videos').limit(50).get();
      final docsSnapshot = await _firestore.collection('telegram_documents').limit(50).get();
      final photosSnapshot = await _firestore.collection('telegram_photos').limit(50).get();
      final audioSnapshot = await _firestore.collection('telegram_audio').limit(50).get();
      final postsSnapshot = await _firestore.collection('telegram_feed').where('media_type', isEqualTo: 'text').limit(50).get();
      
      return {
        'videos': videosSnapshot.docs.map((doc) => TelegramVideo(doc.id, doc.data())).toList(),
        'documents': docsSnapshot.docs.map((doc) => TelegramDocument(doc.id, doc.data())).toList(),
        'photos': photosSnapshot.docs.map((doc) => TelegramPhoto(doc.id, doc.data())).toList(),
        'audio': audioSnapshot.docs.map((doc) => TelegramAudio(doc.id, doc.data())).toList(),
        'posts': postsSnapshot.docs.map((doc) => TelegramPost(doc.id, doc.data())).toList(),
      };
    } catch (e) {
      debugPrint('❌ Fehler beim Laden aller Inhalte: $e');
      return {
        'videos': [],
        'documents': [],
        'photos': [],
        'audio': [],
        'posts': [],
      };
    }
  }
  
  /// Holt Videos als Stream
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
  
  /// Holt Videos nach Kategorie
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
  
  /// Holt Dokumente als Stream
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
  
  /// Holt Fotos als Stream
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
  
  /// Holt Audio als Stream
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
  
  /// Holt Text-Posts als Stream
  Stream<List<TelegramPost>> getTextPosts() {
    return _firestore
        .collection('telegram_feed')
        .where('media_type', isEqualTo: 'text')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TelegramPost(doc.id, doc.data()))
            .toList());
  }
}
