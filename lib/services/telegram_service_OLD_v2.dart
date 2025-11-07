import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Phase 2.1: Timeout Exception für stabilisiertes Polling

/// Telegram Bot Service für Weltenbibliothek
/// 
/// Features:
/// - Bot-Initialisierung und Verbindung (@weltenbibliothek_bot)
/// - Bidirektionale Chat-Synchronisation
/// - Video-Synchronisation vom Channel (@ArchivWeltenBibliothek)
/// - Dokumente, Fotos, Audio, Posts vom Chat (@Weltenbibliothekchat)
/// - Automatische Kategorisierung (10 Kategorien)
class TelegramService {
  // ========== CONFIGURATION ==========
  
  static const String _botToken = '7826102549:AAHMOTvl13GlR2vousHVTE4jO0xTYuVlS7k';
  static const String _botUsername = '@weltenbibliothek_bot'; // Bot Username
  static const String _chatUsername = '@Weltenbibliothekchat';
  static const String _channelUsername = '@ArchivWeltenBibliothek';
  static const String _baseUrl = 'https://api.telegram.org/bot$_botToken';
  
  // Gruppen-Support (Phase 2.3)
  static const String _targetGroupTitle = 'Weltenbibliothekchat'; // Name der zu synchronisierenden Gruppe
  static const bool _syncAllGroups = false; // false = nur _targetGroupTitle, true = alle Gruppen
  
  // Chat & Channel IDs (werden bei Initialisierung gesetzt)
  String? _chatId;
  String? _channelId;
  
  // Long Polling
  Timer? _pollingTimer;
  int _lastUpdateId = 0;
  bool _isInitialized = false;
  
  // Polling Stability (Phase 2.1)
  int _consecutiveErrors = 0;
  int _pollingInterval = 2; // Start mit 2 Sekunden
  bool _isPolling = false;
  DateTime? _lastSuccessfulPoll;
  static const int _maxConsecutiveErrors = 5;
  static const int _maxPollingInterval = 60; // Max 60 Sekunden
  
  // Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
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
      debugPrint('🔄 TelegramService: Initialisierung startet...');
      
      // 1. Bot-Info abrufen
      await _getBotInfo();
      
      // 2. Chat & Channel IDs auflösen
      await _getChatId();
      await _getChannelId();
      
      // 3. Long Polling starten
      _startPolling();
      
      _isInitialized = true;
      debugPrint('✅ TelegramService erfolgreich initialisiert');
      
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
  
  /// Löst Chat-ID auf
  Future<void> _getChatId() async {
    try {
      // DIREKTER ANSATZ: Verwende bekannte Chat-ID ohne getUpdates
      // getUpdates wird nur im Polling-Loop verwendet
      _chatId = '-1001191136317';
      debugPrint('✅ Chat-ID gesetzt: $_chatId ($_chatUsername)');
      
    } catch (e) {
      debugPrint('⚠️ Fehler beim Setzen der Chat-ID: $e');
      _chatId = '-1001191136317'; // Fallback
    }
  }
  
  /// Löst Channel-ID auf
  Future<void> _getChannelId() async {
    try {
      // Channel-ID ist bekannt
      _channelId = '-1001583724662';
      debugPrint('✅ Channel-ID gesetzt: $_channelId ($_channelUsername)');
      
    } catch (e) {
      debugPrint('⚠️ Fehler beim Setzen der Channel-ID: $e');
      _channelId = '-1001583724662'; // Fallback
    }
  }
  
  // ========== LONG POLLING ==========
  
  /// Startet Long Polling für neue Nachrichten (v2.1: Stabilisiert)
  void _startPolling() {
    _pollingTimer?.cancel();
    
    // Reset stability tracking
    _consecutiveErrors = 0;
    _pollingInterval = 2;
    _lastSuccessfulPoll = DateTime.now();
    
    _pollingTimer = Timer.periodic(Duration(seconds: _pollingInterval), (timer) {
      _pollUpdates();
    });
    
    debugPrint('✅ Long Polling gestartet (Intervall: ${_pollingInterval}s)');
  }
  
  /// Stoppt Long Polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('🛑 Long Polling gestoppt');
  }
  
  /// Holt neue Updates von Telegram (v2.1: Stabilisiert mit Retry-Logik)
  Future<void> _pollUpdates() async {
    // Prevent concurrent polling
    if (_isPolling) {
      debugPrint('⚠️ Polling bereits aktiv, überspringe...');
      return;
    }
    
    _isPolling = true;
    
    try {
      // FIX: Verwende korrekten Offset
      // offset=0 holt ALLE verfügbaren Updates (beim ersten Mal)
      // offset=lastUpdateId+1 holt nur NEUE Updates (nach dem ersten Mal)
      final offset = _lastUpdateId == 0 ? 0 : _lastUpdateId + 1;
      
      final response = await http.get(
        Uri.parse('$_baseUrl/getUpdates?offset=$offset&timeout=30&allowed_updates=["message","channel_post","edited_message","edited_channel_post"]'),
      ).timeout(
        const Duration(seconds: 35), // Timeout etwas länger als API timeout
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
              final updateId = update['update_id'] as int;
              
              // Verarbeite Update
              await _processUpdate(update);
              
              // Update die lastUpdateId NACH erfolgreicher Verarbeitung
              if (updateId > _lastUpdateId) {
                _lastUpdateId = updateId;
              }
            }
            
            debugPrint('✅ Alle Updates verarbeitet. Letzte ID: $_lastUpdateId');
          }
          
          // SUCCESS: Reset error counter und interval
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
    
    // Reset error counter
    if (_consecutiveErrors > 0) {
      debugPrint('✅ Verbindung wiederhergestellt!');
      _consecutiveErrors = 0;
    }
    
    // Reset interval zurück auf 2 Sekunden (wenn erhöht)
    if (_pollingInterval > 2) {
      _pollingInterval = 2;
      _restartPollingWithNewInterval();
    }
  }
  
  /// Behandelt Polling-Fehler mit Exponential Backoff
  void _onPollError(String error) {
    _consecutiveErrors++;
    
    debugPrint('⚠️ Fehler #$_consecutiveErrors: $error');
    
    // Exponential Backoff: 2s → 4s → 8s → 16s → 32s → 60s (max)
    if (_consecutiveErrors >= 2) {
      final newInterval = (_pollingInterval * 2).clamp(2, _maxPollingInterval);
      
      if (newInterval != _pollingInterval) {
        _pollingInterval = newInterval;
        debugPrint('🔄 Polling-Intervall erhöht auf ${_pollingInterval}s (Exponential Backoff)');
        _restartPollingWithNewInterval();
      }
    }
    
    // Wenn zu viele Fehler, warne Benutzer
    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      debugPrint('🚨 WARNUNG: $_consecutiveErrors aufeinanderfolgende Fehler! Netzwerkproblem?');
    }
  }
  
  /// Startet Polling mit neuem Intervall neu
  void _restartPollingWithNewInterval() {
    _pollingTimer?.cancel();
    
    _pollingTimer = Timer.periodic(Duration(seconds: _pollingInterval), (timer) {
      _pollUpdates();
    });
    
    debugPrint('🔄 Polling neu gestartet mit ${_pollingInterval}s Intervall');
  }
  
  /// Health-Check: Prüft ob Polling gesund läuft
  bool isPollingHealthy() {
    if (!_isInitialized) return false;
    if (_pollingTimer == null || !_pollingTimer!.isActive) return false;
    if (_consecutiveErrors >= _maxConsecutiveErrors) return false;
    
    // Prüfe ob letzter erfolgreicher Poll nicht zu lange her ist
    if (_lastSuccessfulPoll != null) {
      final timeSinceLastPoll = DateTime.now().difference(_lastSuccessfulPoll!);
      if (timeSinceLastPoll.inMinutes > 5) {
        debugPrint('⚠️ Health-Check: Letzter erfolgreicher Poll vor ${timeSinceLastPoll.inMinutes} Minuten');
        return false;
      }
    }
    
    return true;
  }
  
  /// Gibt Polling-Status zurück (für Debugging)
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
  
  /// Verarbeitet ein Telegram Update
  Future<void> _processUpdate(Map<String, dynamic> update) async {
    try {
      final updateId = update['update_id'];
      
      // Verarbeite Nachrichten (inkl. Gruppen-Nachrichten)
      if (update['message'] != null) {
        final message = update['message'];
        final chat = message['chat'];
        final chatId = chat['id'].toString();
        final chatType = chat['type'] as String?; // 'private', 'group', 'supergroup', 'channel'
        final chatTitle = chat['title'] as String?;
        
        debugPrint('📩 Update #$updateId: Nachricht von Chat $chatId (Type: $chatType, Title: $chatTitle)');
        
        // Verarbeite Gruppen-Nachrichten (group/supergroup)
        if (chatType == 'group' || chatType == 'supergroup') {
          // Prüfe ob Gruppe synchronisiert werden soll
          if (_syncAllGroups || chatTitle == _targetGroupTitle) {
            debugPrint('✅ Gruppen-Nachricht von "$chatTitle" wird synchronisiert');
            await _processGroupMessage(message);
          } else {
            debugPrint('⏭️ Gruppen-Nachricht ignoriert (Gruppe: "$chatTitle" nicht in Whitelist)');
          }
        } 
        // Verarbeite private Chat-Nachrichten (wie bisher)
        else if (chatId == _chatId) {
          debugPrint('✅ Nachricht ist vom Ziel-Chat ($_chatUsername)');
          await _processChatMessage(message);
        } else {
          debugPrint('⚠️ Nachricht ignoriert (nicht vom Ziel-Chat)');
        }
      }
      
      // Verarbeite Channel Posts
      if (update['channel_post'] != null) {
        final post = update['channel_post'];
        final chat = post['chat'];
        final chatId = chat['id'].toString();
        
        debugPrint('📺 Update #$updateId: Channel-Post von $chatId');
        
        // Nur Posts vom konfigurierten Channel verarbeiten
        if (chatId == _channelId) {
          debugPrint('✅ Post ist vom Ziel-Channel ($_channelUsername)');
          await _processChannelPost(post);
        } else {
          debugPrint('⚠️ Post ignoriert (nicht vom Ziel-Channel)');
        }
      }
      
      // Wenn weder message noch channel_post vorhanden
      if (update['message'] == null && update['channel_post'] == null) {
        debugPrint('⚠️ Update #$updateId: Unbekannter Typ (weder message noch channel_post)');
      }
      
    } catch (e) {
      debugPrint('⚠️ Fehler beim Verarbeiten des Updates: $e');
    }
  }
  
  // ========== CHAT MESSAGE HANDLING ==========
  
  /// Verarbeitet eine Chat-Nachricht (ALLE MEDIENTYPEN außer Videos)
  Future<void> _processChatMessage(Map<String, dynamic> message) async {
    try {
      final messageId = message['message_id'];
      final text = message['text'] ?? message['caption'] ?? '';
      final from = message['from'];
      final senderName = from['first_name'] ?? 'Unknown';
      final senderId = from['id'].toString();
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        message['date'] * 1000,
      );
      
      debugPrint('📩 Neue Telegram-Nachricht: $text');
      
      // Verarbeite Medientypen aus Chat (außer Videos - die kommen vom Channel)
      if (message['document'] != null) {
        await _processDocument(message, messageId, text, timestamp);
      } else if (message['photo'] != null) {
        await _processPhoto(message, messageId, text, timestamp);
      } else if (message['audio'] != null) {
        await _processAudio(message, messageId, text, timestamp);
      } else if (text.isNotEmpty) {
        await _processTextPost(message, messageId, text, timestamp);
      }
      
      // Speichere Text-Nachricht zusätzlich in telegram_messages
      await _firestore.collection('telegram_messages').add({
        'telegram_message_id': messageId,
        'chat_id': _chatId,
        'sender_id': senderId,
        'sender_name': senderName,
        'text': text,
        'timestamp': timestamp,
        'synced_to_app': false,
        'created_at': FieldValue.serverTimestamp(),
      });
      
      // v2.14.3: Synchronisation in App-Chat (Telegram → App)
      if (text.isNotEmpty) {
        try {
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
          
          // Update Chat-Room lastActivity
          await _firestore.collection('chat_rooms').doc('telegram_chat').update({
            'lastActivity': FieldValue.serverTimestamp(),
            'last_message': text,
            'last_message_time': FieldValue.serverTimestamp(),
          });
          
          debugPrint('📥 Telegram-Nachricht in App-Chat synchronisiert');
        } catch (e) {
          debugPrint('⚠️ Fehler beim Synchronisieren in App-Chat: $e');
        }
      }
      
    } catch (e) {
      debugPrint('❌ Fehler beim Verarbeiten der Chat-Nachricht: $e');
    }
  }
  
  // ========== GROUP MESSAGE HANDLING (Phase 2.3) ==========
  
  /// Verarbeitet eine Gruppen-Nachricht (aus supergroup/group)
  /// 
  /// Diese Funktion wird aufgerufen, wenn eine Nachricht aus einer Telegram-Gruppe
  /// empfangen wird (z.B. Weltenbibliothekchat). Sie extrahiert alle relevanten
  /// Informationen und speichert sie in Firestore basierend auf dem Medientyp.
  Future<void> _processGroupMessage(Map<String, dynamic> message) async {
    try {
      final messageId = message['message_id'];
      final chat = message['chat'];
      final chatId = chat['id'].toString();
      final chatTitle = chat['title'] as String? ?? 'Unbekannte Gruppe';
      final chatType = chat['type'] as String?;
      
      final text = message['text'] ?? message['caption'] ?? '';
      final from = message['from'];
      final senderName = from != null ? (from['first_name'] ?? 'Unknown') : 'Unknown';
      final senderUsername = from != null ? (from['username'] ?? '') : '';
      final senderId = from != null ? from['id'].toString() : 'unknown';
      
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        message['date'] * 1000,
      );
      
      // Topic/Thread Support (für Gruppen mit Topics)
      final messageThreadId = message['message_thread_id'] as int?;
      final isTopicMessage = message['is_topic_message'] as bool? ?? false;
      
      debugPrint('👥 Gruppen-Nachricht verarbeiten:');
      debugPrint('   📍 Gruppe: \"$chatTitle\" (ID: $chatId, Type: $chatType)');
      debugPrint('   👤 Von: $senderName (@$senderUsername)');
      debugPrint('   💬 Text: ${text.length > 50 ? text.substring(0, 50) + '...' : text}');
      if (isTopicMessage) {
        debugPrint('   🔖 Topic/Thread: $messageThreadId');
      }
      
      // Basis-Daten für alle Medientypen
      final Map<String, dynamic> baseData = {
        'telegram_message_id': messageId,
        'chat_id': chatId,
        'chat_title': chatTitle,
        'chat_type': chatType,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_username': senderUsername,
        'text': text,
        'timestamp': timestamp,
        'is_group_message': true,
        'indexed_at': FieldValue.serverTimestamp(),
      };
      
      // Topic-Daten hinzufügen wenn vorhanden
      if (isTopicMessage && messageThreadId != null) {
        baseData['topic_id'] = messageThreadId;
        baseData['is_topic_message'] = true;
      }
      
      // Verarbeite verschiedene Medientypen
      bool mediaProcessed = false;
      
      if (message['document'] != null) {
        await _processDocument(message, messageId, text, timestamp, extraData: baseData);
        mediaProcessed = true;
      } else if (message['photo'] != null) {
        await _processPhoto(message, messageId, text, timestamp, extraData: baseData);
        mediaProcessed = true;
      } else if (message['video'] != null) {
        await _processVideo(message, messageId, text, timestamp, extraData: baseData);
        mediaProcessed = true;
      } else if (message['audio'] != null) {
        await _processAudio(message, messageId, text, timestamp, extraData: baseData);
        mediaProcessed = true;
      } else if (text.isNotEmpty) {
        await _processTextPost(message, messageId, text, timestamp, extraData: baseData);
        mediaProcessed = true;
      }
      
      if (mediaProcessed) {
        debugPrint('✅ Gruppen-Nachricht erfolgreich verarbeitet und in Firestore gespeichert');
      } else {
        debugPrint('⚠️ Gruppen-Nachricht ohne verwertbaren Inhalt (kein Text/Media)');
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Fehler beim Verarbeiten der Gruppen-Nachricht: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
  
  /// Sendet eine Nachricht an Telegram Chat
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
          debugPrint('✅ Nachricht an Telegram gesendet');
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
  
  // ========== CHANNEL POST HANDLING ==========
  
  /// Verarbeitet einen Channel Post (NUR VIDEOS vom Channel)
  Future<void> _processChannelPost(Map<String, dynamic> post) async {
    try {
      final messageId = post['message_id'];
      final text = post['text'] ?? post['caption'] ?? '';
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        post['date'] * 1000,
      );
      
      // Nur Videos vom Channel verarbeiten
      if (post['video'] != null) {
        await _processVideo(post, messageId, text, timestamp);
      } else {
        debugPrint('⚠️ Channel-Post ohne Video ignoriert (messageId: $messageId)');
      }
      
    } catch (e) {
      debugPrint('❌ Fehler beim Verarbeiten des Channel Posts: $e');
    }
  }
  
  /// Verarbeitet ein Video
  Future<void> _processVideo(
    Map<String, dynamic> post,
    int messageId,
    String description,
    DateTime timestamp, {
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final video = post['video'];
      final fileId = video['file_id'];
      final duration = video['duration'];
      final fileSize = video['file_size'];
      
      // Kategorisiere basierend auf Beschreibung
      final category = _categorizeContent(description);
      
      // Erstelle Video-URL (ohne @ Zeichen)
      final channelName = _channelUsername.replaceAll('@', '');
      final videoUrl = 'https://t.me/$channelName/$messageId';
      
      // Thumbnail (falls vorhanden)
      String? thumbnailUrl;
      if (video['thumb'] != null) {
        thumbnailUrl = await _getFileUrl(video['thumb']['file_id']);
      }
      
      // Speichere in Firestore
      final videoData = {
        'telegram_message_id': messageId,
        'channel_id': _channelId,
        'channel_username': _channelUsername,
        'file_id': fileId,
        'title': _extractTitle(description),
        'description': description,
        'category': category,
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'duration': duration,
        'file_size': fileSize,
        'view_count': 0,
        'created_at': timestamp,
        'indexed_at': FieldValue.serverTimestamp(),
      };
      
      // Füge Extra-Daten hinzu (z.B. für Gruppen-Nachrichten)
      if (extraData != null) {
        videoData.addAll(extraData);
      }
      
      await _firestore.collection('telegram_videos').add(videoData);
      
      debugPrint('✅ Video gespeichert: Kategorie=$category');
      
    } catch (e) {
      debugPrint('❌ Fehler beim Verarbeiten des Videos: $e');
    }
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
  
  // ========== DOCUMENT HANDLING ==========
  
  /// Verarbeitet ein Dokument (PDF, DOC, etc.)
  Future<void> _processDocument(
    Map<String, dynamic> post,
    int messageId,
    String description,
    DateTime timestamp, {
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final document = post['document'];
      final fileId = document['file_id'];
      final fileName = document['file_name'] ?? 'document';
      final fileSize = document['file_size'] ?? 0;
      final mimeType = document['mime_type'] ?? 'application/octet-stream';
      
      // Bestimme Dokumenttyp
      String docType = 'other';
      if (mimeType.contains('pdf')) {
        docType = 'pdf';
      } else if (mimeType.contains('word') || fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
        docType = 'word';
      } else if (mimeType.contains('text')) {
        docType = 'text';
      }
      
      // Kategorisiere basierend auf Beschreibung
      final category = _categorizeContent(description);
      
      // Erstelle Dokument-URL (aus CHAT, nicht Channel)
      final chatName = _chatUsername.replaceAll('@', '');
      final docUrl = 'https://t.me/$chatName/$messageId';
      
      // Hole Download-URL
      final downloadUrl = await _getFileUrl(fileId);
      
      // Speichere in Firestore telegram_documents
      final docData = {
        'telegram_message_id': messageId,
        'channel_id': _channelId,
        'channel_username': _channelUsername,
        'file_id': fileId,
        'title': _extractTitle(description.isNotEmpty ? description : fileName),
        'description': description,
        'file_name': fileName,
        'file_size': fileSize,
        'mime_type': mimeType,
        'doc_type': docType,
        'category': category,
        'telegram_url': docUrl,
        'download_url': downloadUrl,
        'view_count': 0,
        'download_count': 0,
        'created_at': timestamp,
        'indexed_at': FieldValue.serverTimestamp(),
      };
      
      // Füge Extra-Daten hinzu (z.B. für Gruppen-Nachrichten)
      if (extraData != null) {
        docData.addAll(extraData);
      }
      
      await _firestore.collection('telegram_documents').add(docData);
      
      debugPrint('✅ Dokument gespeichert: \$fileName (Typ: \$docType, Kategorie: \$category)');
      
    } catch (e) {
      debugPrint('❌ Fehler beim Verarbeiten des Dokuments: \$e');
    }
  }
  
  // ========== PHOTO HANDLING ==========
  
  /// Verarbeitet ein Foto
  Future<void> _processPhoto(
    Map<String, dynamic> post,
    int messageId,
    String description,
    DateTime timestamp, {
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final photos = post['photo'] as List;
      if (photos.isEmpty) return;
      
      // Nimm höchste Auflösung (letztes Element)
      final photo = photos.last;
      final fileId = photo['file_id'];
      final width = photo['width'] ?? 0;
      final height = photo['height'] ?? 0;
      final fileSize = photo['file_size'] ?? 0;
      
      // Kategorisiere basierend auf Beschreibung
      final category = _categorizeContent(description);
      
      // Erstelle Foto-URL (aus CHAT, nicht Channel)
      final chatName = _chatUsername.replaceAll('@', '');
      final photoUrl = 'https://t.me/$chatName/$messageId';
      
      // Hole Bild-URL
      final imageUrl = await _getFileUrl(fileId);
      
      // Speichere in Firestore telegram_photos
      final photoData = {
        'telegram_message_id': messageId,
        'channel_id': _channelId,
        'channel_username': _channelUsername,
        'file_id': fileId,
        'title': _extractTitle(description),
        'description': description,
        'category': category,
        'telegram_url': photoUrl,
        'image_url': imageUrl,
        'width': width,
        'height': height,
        'file_size': fileSize,
        'view_count': 0,
        'created_at': timestamp,
        'indexed_at': FieldValue.serverTimestamp(),
      };
      
      // Füge Extra-Daten hinzu (z.B. für Gruppen-Nachrichten)
      if (extraData != null) {
        photoData.addAll(extraData);
      }
      
      await _firestore.collection('telegram_photos').add(photoData);
      
      debugPrint('✅ Foto gespeichert: Kategorie=\$category, Size=\${width}x\${height}');
      
    } catch (e) {
      debugPrint('❌ Fehler beim Verarbeiten des Fotos: \$e');
    }
  }
  
  // ========== AUDIO HANDLING ==========
  
  /// Verarbeitet Audio-Dateien
  Future<void> _processAudio(
    Map<String, dynamic> post,
    int messageId,
    String description,
    DateTime timestamp, {
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final audio = post['audio'];
      final fileId = audio['file_id'];
      final duration = audio['duration'] ?? 0;
      final title = audio['title'] ?? audio['file_name'] ?? 'Audio';
      final performer = audio['performer'];
      final fileSize = audio['file_size'] ?? 0;
      
      // Kategorisiere basierend auf Beschreibung
      final category = _categorizeContent(description);
      
      // Erstelle Audio-URL (aus CHAT, nicht Channel)
      final chatName = _chatUsername.replaceAll('@', '');
      final audioUrl = 'https://t.me/$chatName/$messageId';
      
      // Hole Download-URL
      final downloadUrl = await _getFileUrl(fileId);
      
      // Speichere in Firestore telegram_audio
      final audioData = {
        'telegram_message_id': messageId,
        'channel_id': _channelId,
        'channel_username': _channelUsername,
        'file_id': fileId,
        'title': title,
        'performer': performer,
        'description': description,
        'category': category,
        'telegram_url': audioUrl,
        'download_url': downloadUrl,
        'duration': duration,
        'file_size': fileSize,
        'view_count': 0,
        'created_at': timestamp,
        'indexed_at': FieldValue.serverTimestamp(),
      };
      
      // Füge Extra-Daten hinzu (z.B. für Gruppen-Nachrichten)
      if (extraData != null) {
        audioData.addAll(extraData);
      }
      
      await _firestore.collection('telegram_audio').add(audioData);
      
      debugPrint('✅ Audio gespeichert: \$title (Kategorie: \$category)');
      
    } catch (e) {
      debugPrint('❌ Fehler beim Verarbeiten der Audio-Datei: \$e');
    }
  }
  
  // ========== TEXT POST HANDLING ==========
  
  /// Verarbeitet reine Text-Posts
  Future<void> _processTextPost(
    Map<String, dynamic> post,
    int messageId,
    String text,
    DateTime timestamp, {
    Map<String, dynamic>? extraData,
  }) async {
    try {
      // Kategorisiere basierend auf Text-Inhalt
      final category = _categorizeContent(text);
      
      // Erstelle Post-URL (aus CHAT, nicht Channel)
      final chatName = _chatUsername.replaceAll('@', '');
      final postUrl = 'https://t.me/$chatName/$messageId';
      
      // Speichere in Firestore telegram_posts
      final postData = {
        'telegram_message_id': messageId,
        'channel_id': _channelId,
        'channel_username': _channelUsername,
        'title': _extractTitle(text),
        'content': text,
        'category': category,
        'telegram_url': postUrl,
        'view_count': 0,
        'created_at': timestamp,
        'indexed_at': FieldValue.serverTimestamp(),
      };
      
      // Füge Extra-Daten hinzu (z.B. für Gruppen-Nachrichten)
      if (extraData != null) {
        postData.addAll(extraData);
      }
      
      await _firestore.collection('telegram_posts').add(postData);
      
      debugPrint('✅ Text-Post gespeichert: Kategorie=\$category');
      
    } catch (e) {
      debugPrint('❌ Fehler beim Verarbeiten des Text-Posts: \$e');
    }
  }
  
  // ========== VIDEO CATEGORIZATION (v2.0 - ERWEITERT) ==========
  
  /// Kategorisiert Inhalte basierend auf Beschreibung (universell für alle Medientypen)
  /// v2.0: Scoring-basiert mit erweiterten Keyword-Listen
  String _categorizeContent(String description) {
    final lowerDesc = description.toLowerCase();
    
    // Scoring-System: Jede Kategorie bekommt Punkte für Keyword-Matches
    Map<String, int> categoryScores = {
      'lostCivilizations': 0,
      'alienContact': 0,
      'ancientTechnology': 0,
      'mysteriousArtifacts': 0,
      'paranormalPhenomena': 0,
      'secretSocieties': 0,
      'dimensionalAnomalies': 0,
      'techMysteries': 0,
      'cosmicEvents': 0,
      'hiddenKnowledge': 0,
    };
    
    // KATEGORIE 1: Verlorene Zivilisationen
    final lostCivKeywords = [
      'atlantis', 'zivilisation', 'civilization', 'lemuria', 'mu', 'hyperborea',
      'versunken', 'ancient', 'antik', 'maya', 'azteken', 'inka', 'ägypten',
      'egypt', 'pyramide', 'pyramid', 'megalith', 'stonehenge', 'göbekli',
      'sumerer', 'sumer', 'babylon', 'mesopotam', 'indus', 'kultur', 'culture',
      'reich', 'empire', 'ruine', 'ruins', 'ausgrabung', 'excavation'
    ];
    for (var keyword in lostCivKeywords) {
      if (lowerDesc.contains(keyword)) categoryScores['lostCivilizations'] = categoryScores['lostCivilizations']! + 1;
    }
    
    // KATEGORIE 2: Außerirdische Kontakte
    final alienKeywords = [
      'ufo', 'alien', 'außerirdisch', 'extraterrestrial', 'et', 'greys', 'grays',
      'reptilien', 'reptilian', 'annunaki', 'plejad', 'pleiadian', 'sirius',
      'zeta', 'nordics', 'kontakt', 'contact', 'abduction', 'entführung',
      'roswell', 'area 51', 'begegnung', 'encounter', 'sichtung', 'sighting',
      'raumschiff', 'spacecraft', 'fliegende untertasse', 'flying saucer',
      'disclosure', 'offenbarung', 'besuch', 'visit'
    ];
    for (var keyword in alienKeywords) {
      if (lowerDesc.contains(keyword)) categoryScores['alienContact'] = categoryScores['alienContact']! + 1;
    }
    
    // KATEGORIE 3: Antike Technologien
    final ancientTechKeywords = [
      'technologie', 'technology', 'antik', 'ancient tech', 'vimana', 'vril',
      'kristall', 'crystal', 'batterien', 'battery', 'baghdad', 'mechanismus',
      'mechanism', 'antikythera', 'computer', 'maschine', 'machine', 'werkzeug',
      'tool', 'flying', 'flug', 'energie', 'energy', 'power', 'kraft',
      'gerät', 'device', 'instrument', 'apparatur', 'apparatus'
    ];
    for (var keyword in ancientTechKeywords) {
      if (lowerDesc.contains(keyword)) categoryScores['ancientTechnology'] = categoryScores['ancientTechnology']! + 1;
    }
    
    // KATEGORIE 4: Mysteriöse Artefakte
    final artifactKeywords = [
      'artefakt', 'artifact', 'kristallschädel', 'crystal skull', 'relikt',
      'relic', 'objekt', 'object', 'schatz', 'treasure', 'heilig', 'sacred',
      'gral', 'grail', 'bundeslade', 'ark', 'stein', 'stone', 'schrift',
      'script', 'text', 'dokument', 'manuscript', 'manuskript', 'rolle',
      'scroll', 'tafel', 'tablet', 'fund', 'finding', 'entdeckung', 'discovery'
    ];
    for (var keyword in artifactKeywords) {
      if (lowerDesc.contains(keyword)) categoryScores['mysteriousArtifacts'] = categoryScores['mysteriousArtifacts']! + 1;
    }
    
    // KATEGORIE 5: Paranormale Phänomene
    final paranormalKeywords = [
      'paranormal', 'geist', 'ghost', 'spuk', 'haunted', 'poltergeist',
      'erscheinung', 'apparition', 'séance', 'medium', 'jenseits', 'afterlife',
      'spirit', 'seele', 'soul', 'dämon', 'demon', 'besessen', 'possessed',
      'exorzismus', 'exorcism', 'übernatürlich', 'supernatural', 'unerklärlich',
      'unexplained', 'mysteriös', 'mysterious', 'rätselhaft', 'enigma'
    ];
    for (var keyword in paranormalKeywords) {
      if (lowerDesc.contains(keyword)) categoryScores['paranormalPhenomena'] = categoryScores['paranormalPhenomena']! + 1;
    }
    
    // KATEGORIE 6: Geheimgesellschaften
    final secretSocietyKeywords = [
      'illuminati', 'freimauer', 'freemason', 'loge', 'lodge', 'geheim',
      'secret', 'society', 'gesellschaft', 'orden', 'order', 'templer',
      'templar', 'rosenkreuzer', 'rosicrucian', 'skulls', 'bones', 'bohemian',
      'bilderberg', 'rothschild', 'verschwörung', 'conspiracy', 'kabale',
      'cabal', 'elite', 'shadow', 'schatten', 'macht', 'power', 'kontrolle',
      'control', 'new world order', 'nwo', 'deep state'
    ];
    for (var keyword in secretSocietyKeywords) {
      if (lowerDesc.contains(keyword)) categoryScores['secretSocieties'] = categoryScores['secretSocieties']! + 1;
    }
    
    // KATEGORIE 7: Dimensionale Anomalien
    final dimensionKeywords = [
      'dimension', 'portal', 'tor', 'gate', 'anomalie', 'anomaly', 'zeitreise',
      'time travel', 'zeitschleife', 'loop', 'parallel', 'universum', 'universe',
      'multiverse', 'multiversum', 'realität', 'reality', 'mandela effekt',
      'mandela effect', 'glitch', 'matrix', 'simulation', 'vortex', 'wirbel',
      'bermuda', 'dreieck', 'triangle', 'verschwinden', 'disappear', 'teleport'
    ];
    for (var keyword in dimensionKeywords) {
      if (lowerDesc.contains(keyword)) categoryScores['dimensionalAnomalies'] = categoryScores['dimensionalAnomalies']! + 1;
    }
    
    // KATEGORIE 8: Technologie-Mysterien
    final techMysteryKeywords = [
      'tesla', 'nikola', 'edison', 'erfindung', 'invention', 'patent',
      'unterdrückt', 'suppressed', 'freie energie', 'free energy', 'anti',
      'gravitation', 'haarp', 'chemtrails', 'geoengineering', 'weather',
      'wetter', 'kontrolle', 'mind control', 'gedanken', 'thought', 'mkultra',
      'projekt', 'project', 'philadelphia', 'montauk', 'experimente', 'experiments'
    ];
    for (var keyword in techMysteryKeywords) {
      if (lowerDesc.contains(keyword)) categoryScores['techMysteries'] = categoryScores['techMysteries']! + 1;
    }
    
    // KATEGORIE 9: Kosmische Ereignisse
    final cosmicKeywords = [
      'planet', 'kosmos', 'cosmos', 'cosmic', 'stern', 'star', 'nibiru',
      'nemesis', 'planet x', 'komet', 'comet', 'asteroid', 'meteorit', 'meteor',
      'einschlag', 'impact', 'katastrophe', 'catastrophe', 'apokalypse',
      'apocalypse', 'sonnensturm', 'solar', 'flare', 'cme', 'magnetfeld',
      'magnetic', 'polsprung', 'pole shift', 'eiszeit', 'ice age', 'sintflut',
      'flood', 'deluge'
    ];
    for (var keyword in cosmicKeywords) {
      if (lowerDesc.contains(keyword)) categoryScores['cosmicEvents'] = categoryScores['cosmicEvents']! + 1;
    }
    
    // KATEGORIE 10: Verborgenes Wissen
    final knowledgeKeywords = [
      'bibliothek', 'library', 'wissen', 'knowledge', 'weisheit', 'wisdom',
      'lehre', 'teaching', 'geheim', 'hidden', 'verborgen', 'occult', 'okkult',
      'esoterik', 'esoteric', 'mystik', 'mystic', 'alchemie', 'alchemy',
      'kabbala', 'kabbalah', 'gnostik', 'gnostic', 'hermetik', 'hermetic',
      'philosophie', 'philosophy', 'ancient wisdom', 'alte weisheit', 'akasha',
      'record', 'chronik', 'chronicle', 'schrift', 'scripture', 'text'
    ];
    for (var keyword in knowledgeKeywords) {
      if (lowerDesc.contains(keyword)) categoryScores['hiddenKnowledge'] = categoryScores['hiddenKnowledge']! + 1;
    }
    
    // Finde Kategorie mit höchstem Score
    String bestCategory = 'hiddenKnowledge';
    int maxScore = 0;
    
    categoryScores.forEach((category, score) {
      if (score > maxScore) {
        maxScore = score;
        bestCategory = category;
      }
    });
    
    // Logging für Debugging
    if (maxScore > 0) {
      debugPrint('🎯 Kategorisierung: "${description.substring(0, description.length > 50 ? 50 : description.length)}..." → $bestCategory (Score: $maxScore)');
    } else {
      debugPrint('⚠️ Keine Kategorie-Übereinstimmung gefunden, verwende Default: $bestCategory');
    }
    
    return bestCategory;
  }
  
  /// Extrahiert Titel aus Beschreibung
  String _extractTitle(String description) {
    // Nimm erste Zeile oder ersten Satz
    final lines = description.split('\n');
    if (lines.isNotEmpty) {
      String title = lines[0].trim();
      
      // Entferne Hashtags
      title = title.replaceAll(RegExp(r'#\w+'), '').trim();
      
      // Limitiere Länge
      if (title.length > 80) {
        title = '${title.substring(0, 77)}...';
      }
      
      return title.isNotEmpty ? title : 'Telegram Video';
    }
    
    return 'Telegram Video';
  }
  
  // ========== FIRESTORE QUERIES ==========
  
  /// Holt alle Videos (Stream) - OHNE INDEX-ANFORDERUNG
  Stream<List<TelegramVideo>> getVideos() {
    return _firestore
        .collection('telegram_videos')
        .snapshots()
        .map((snapshot) {
      debugPrint('📹 Telegram Videos geladen: ${snapshot.docs.length} Videos');
      
      // Sortierung im Speicher statt in Firestore Query
      final videos = snapshot.docs
          .map((doc) {
            try {
              return TelegramVideo.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              debugPrint('❌ Fehler beim Parsen von Video ${doc.id}: $e');
              return null;
            }
          })
          .whereType<TelegramVideo>()
          .toList();
      
      // Sortiere nach created_at (neueste zuerst)
      videos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('✅ ${videos.length} Videos erfolgreich verarbeitet');
      return videos;
    });
  }
  
  /// Holt Videos nach Kategorie (Stream) - OHNE INDEX-ANFORDERUNG
  Stream<List<TelegramVideo>> getVideosByCategory(String? category) {
    if (category == null || category.isEmpty) {
      debugPrint('📹 Lade alle Videos (keine Kategorie)');
      return getVideos();
    }
    
    debugPrint('📹 Lade Videos für Kategorie: $category');
    
    return _firestore
        .collection('telegram_videos')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      debugPrint('📊 Videos in Kategorie $category: ${snapshot.docs.length}');
      
      // Sortierung im Speicher statt in Firestore Query
      final videos = snapshot.docs
          .map((doc) {
            try {
              return TelegramVideo.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              debugPrint('❌ Fehler beim Parsen von Video ${doc.id}: $e');
              return null;
            }
          })
          .whereType<TelegramVideo>()
          .toList();
      
      // Sortiere nach created_at (neueste zuerst)
      videos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return videos;
    });
  }
  
  /// Erhöht View-Counter für ein Video
  Future<void> incrementViewCount(String videoId) async {
    try {
      await _firestore.collection('telegram_videos').doc(videoId).update({
        'view_count': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('⚠️ Fehler beim Erhöhen des View-Counters: $e');
    }
  }
  
  // ========== DOCUMENT QUERIES ==========
  
  /// Holt alle Dokumente (Stream)
  Stream<List<TelegramDocument>> getDocuments() {
    return _firestore
        .collection('telegram_documents')
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs
          .map((doc) {
            try {
              return TelegramDocument.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              debugPrint('❌ Fehler beim Parsen von Dokument ${doc.id}: $e');
              return null;
            }
          })
          .whereType<TelegramDocument>()
          .toList();
      
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }
  
  /// Holt Dokumente nach Kategorie (Stream)
  Stream<List<TelegramDocument>> getDocumentsByCategory(String? category) {
    if (category == null || category.isEmpty) return getDocuments();
    
    return _firestore
        .collection('telegram_documents')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs
          .map((doc) {
            try {
              return TelegramDocument.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              return null;
            }
          })
          .whereType<TelegramDocument>()
          .toList();
      
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }
  
  /// Holt Dokumente nach Typ (pdf, word, text)
  Stream<List<TelegramDocument>> getDocumentsByType(String docType) {
    return _firestore
        .collection('telegram_documents')
        .where('doc_type', isEqualTo: docType)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs
          .map((doc) {
            try {
              return TelegramDocument.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              return null;
            }
          })
          .whereType<TelegramDocument>()
          .toList();
      
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }
  
  // ========== PHOTO QUERIES ==========
  
  /// Holt alle Fotos (Stream)
  Stream<List<TelegramPhoto>> getPhotos() {
    return _firestore
        .collection('telegram_photos')
        .snapshots()
        .map((snapshot) {
      final photos = snapshot.docs
          .map((doc) {
            try {
              return TelegramPhoto.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              debugPrint('❌ Fehler beim Parsen von Foto ${doc.id}: $e');
              return null;
            }
          })
          .whereType<TelegramPhoto>()
          .toList();
      
      photos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return photos;
    });
  }
  
  /// Holt Fotos nach Kategorie (Stream)
  Stream<List<TelegramPhoto>> getPhotosByCategory(String? category) {
    if (category == null || category.isEmpty) return getPhotos();
    
    return _firestore
        .collection('telegram_photos')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      final photos = snapshot.docs
          .map((doc) {
            try {
              return TelegramPhoto.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              return null;
            }
          })
          .whereType<TelegramPhoto>()
          .toList();
      
      photos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return photos;
    });
  }
  
  // ========== AUDIO QUERIES ==========
  
  /// Holt alle Audio-Dateien (Stream)
  Stream<List<TelegramAudio>> getAudioFiles() {
    return _firestore
        .collection('telegram_audio')
        .snapshots()
        .map((snapshot) {
      final audioFiles = snapshot.docs
          .map((doc) {
            try {
              return TelegramAudio.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              debugPrint('❌ Fehler beim Parsen von Audio ${doc.id}: $e');
              return null;
            }
          })
          .whereType<TelegramAudio>()
          .toList();
      
      audioFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return audioFiles;
    });
  }
  
  /// Holt Audio nach Kategorie (Stream)
  Stream<List<TelegramAudio>> getAudioByCategory(String? category) {
    if (category == null || category.isEmpty) return getAudioFiles();
    
    return _firestore
        .collection('telegram_audio')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      final audioFiles = snapshot.docs
          .map((doc) {
            try {
              return TelegramAudio.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              return null;
            }
          })
          .whereType<TelegramAudio>()
          .toList();
      
      audioFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return audioFiles;
    });
  }
  
  // ========== TEXT POST QUERIES ==========
  
  /// Holt alle Text-Posts (Stream)
  Stream<List<TelegramPost>> getTextPosts() {
    return _firestore
        .collection('telegram_posts')
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) {
            try {
              return TelegramPost.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              debugPrint('❌ Fehler beim Parsen von Post ${doc.id}: $e');
              return null;
            }
          })
          .whereType<TelegramPost>()
          .toList();
      
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }
  
  /// Holt Text-Posts nach Kategorie (Stream)
  Stream<List<TelegramPost>> getTextPostsByCategory(String? category) {
    if (category == null || category.isEmpty) return getTextPosts();
    
    return _firestore
        .collection('telegram_posts')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) {
            try {
              return TelegramPost.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              return null;
            }
          })
          .whereType<TelegramPost>()
          .toList();
      
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }
  
  // ========== UNIFIED CONTENT QUERY ==========
  
  /// Holt ALLE Telegram-Inhalte (Videos, Dokumente, Fotos, Audio, Posts)
  /// Gruppiert nach Medientyp
  Future<Map<String, List<dynamic>>> getAllTelegramContent() async {
    try {
      final videos = await _firestore.collection('telegram_videos').get();
      final documents = await _firestore.collection('telegram_documents').get();
      final photos = await _firestore.collection('telegram_photos').get();
      final audio = await _firestore.collection('telegram_audio').get();
      final posts = await _firestore.collection('telegram_posts').get();
      
      return {
        'videos': videos.docs.map((doc) => TelegramVideo.fromFirestore(doc.data(), doc.id)).toList(),
        'documents': documents.docs.map((doc) => TelegramDocument.fromFirestore(doc.data(), doc.id)).toList(),
        'photos': photos.docs.map((doc) => TelegramPhoto.fromFirestore(doc.data(), doc.id)).toList(),
        'audio': audio.docs.map((doc) => TelegramAudio.fromFirestore(doc.data(), doc.id)).toList(),
        'posts': posts.docs.map((doc) => TelegramPost.fromFirestore(doc.data(), doc.id)).toList(),
      };
    } catch (e) {
      debugPrint('❌ Fehler beim Abrufen aller Telegram-Inhalte: $e');
      return {};
    }
  }
  
  // ========== CLEANUP ==========
  
  /// Räumt Ressourcen auf
  void dispose() {
    stopPolling();
    _isInitialized = false;
  }
}

// ========== DATA MODELS ==========

/// Telegram Video Model
class TelegramVideo {
  final String id;
  final int telegramMessageId;
  final String channelId;
  final String channelUsername;
  final String title;
  final String description;
  final String category;
  final String videoUrl;
  final String? thumbnailUrl;
  final int duration;
  final int fileSize;
  final int viewCount;
  final DateTime createdAt;
  
  TelegramVideo({
    required this.id,
    required this.telegramMessageId,
    required this.channelId,
    required this.channelUsername,
    required this.title,
    required this.description,
    required this.category,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.duration,
    required this.fileSize,
    required this.viewCount,
    required this.createdAt,
  });
  
  factory TelegramVideo.fromFirestore(Map<String, dynamic> data, String id) {
    return TelegramVideo(
      id: id,
      telegramMessageId: data['telegram_message_id'] ?? 0,
      channelId: data['channel_id'] ?? '',
      channelUsername: data['channel_username'] ?? '',
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? '',
      category: data['category'] ?? 'hiddenKnowledge',
      videoUrl: data['video_url'] ?? '',
      thumbnailUrl: data['thumbnail_url'],
      duration: data['duration'] ?? 0,
      fileSize: data['file_size'] ?? 0,
      viewCount: data['view_count'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Telegram Document Model (PDFs, Word, Text, etc.)
class TelegramDocument {
  final String id;
  final int telegramMessageId;
  final String channelId;
  final String channelUsername;
  final String title;
  final String description;
  final String fileName;
  final String mimeType;
  final String docType; // pdf, word, text, other
  final String category;
  final String telegramUrl;
  final String? downloadUrl;
  final int fileSize;
  final int viewCount;
  final int downloadCount;
  final DateTime createdAt;
  
  TelegramDocument({
    required this.id,
    required this.telegramMessageId,
    required this.channelId,
    required this.channelUsername,
    required this.title,
    required this.description,
    required this.fileName,
    required this.mimeType,
    required this.docType,
    required this.category,
    required this.telegramUrl,
    this.downloadUrl,
    required this.fileSize,
    required this.viewCount,
    required this.downloadCount,
    required this.createdAt,
  });
  
  factory TelegramDocument.fromFirestore(Map<String, dynamic> data, String id) {
    return TelegramDocument(
      id: id,
      telegramMessageId: data['telegram_message_id'] ?? 0,
      channelId: data['channel_id'] ?? '',
      channelUsername: data['channel_username'] ?? '',
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? '',
      fileName: data['file_name'] ?? 'document',
      mimeType: data['mime_type'] ?? 'application/octet-stream',
      docType: data['doc_type'] ?? 'other',
      category: data['category'] ?? 'hiddenKnowledge',
      telegramUrl: data['telegram_url'] ?? '',
      downloadUrl: data['download_url'],
      fileSize: data['file_size'] ?? 0,
      viewCount: data['view_count'] ?? 0,
      downloadCount: data['download_count'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Telegram Photo Model
class TelegramPhoto {
  final String id;
  final int telegramMessageId;
  final String channelId;
  final String channelUsername;
  final String title;
  final String description;
  final String category;
  final String telegramUrl;
  final String? imageUrl;
  final int width;
  final int height;
  final int fileSize;
  final int viewCount;
  final DateTime createdAt;
  
  TelegramPhoto({
    required this.id,
    required this.telegramMessageId,
    required this.channelId,
    required this.channelUsername,
    required this.title,
    required this.description,
    required this.category,
    required this.telegramUrl,
    this.imageUrl,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.viewCount,
    required this.createdAt,
  });
  
  factory TelegramPhoto.fromFirestore(Map<String, dynamic> data, String id) {
    return TelegramPhoto(
      id: id,
      telegramMessageId: data['telegram_message_id'] ?? 0,
      channelId: data['channel_id'] ?? '',
      channelUsername: data['channel_username'] ?? '',
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? '',
      category: data['category'] ?? 'hiddenKnowledge',
      telegramUrl: data['telegram_url'] ?? '',
      imageUrl: data['image_url'],
      width: data['width'] ?? 0,
      height: data['height'] ?? 0,
      fileSize: data['file_size'] ?? 0,
      viewCount: data['view_count'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Telegram Audio Model
class TelegramAudio {
  final String id;
  final int telegramMessageId;
  final String channelId;
  final String channelUsername;
  final String title;
  final String? performer;
  final String description;
  final String category;
  final String telegramUrl;
  final String? downloadUrl;
  final int duration;
  final int fileSize;
  final int viewCount;
  final DateTime createdAt;
  
  TelegramAudio({
    required this.id,
    required this.telegramMessageId,
    required this.channelId,
    required this.channelUsername,
    required this.title,
    this.performer,
    required this.description,
    required this.category,
    required this.telegramUrl,
    this.downloadUrl,
    required this.duration,
    required this.fileSize,
    required this.viewCount,
    required this.createdAt,
  });
  
  factory TelegramAudio.fromFirestore(Map<String, dynamic> data, String id) {
    return TelegramAudio(
      id: id,
      telegramMessageId: data['telegram_message_id'] ?? 0,
      channelId: data['channel_id'] ?? '',
      channelUsername: data['channel_username'] ?? '',
      title: data['title'] ?? 'Untitled',
      performer: data['performer'],
      description: data['description'] ?? '',
      category: data['category'] ?? 'hiddenKnowledge',
      telegramUrl: data['telegram_url'] ?? '',
      downloadUrl: data['download_url'],
      duration: data['duration'] ?? 0,
      fileSize: data['file_size'] ?? 0,
      viewCount: data['view_count'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Telegram Text Post Model
class TelegramPost {
  final String id;
  final int telegramMessageId;
  final String channelId;
  final String channelUsername;
  final String title;
  final String content;
  final String category;
  final String telegramUrl;
  final int viewCount;
  final DateTime createdAt;
  
  TelegramPost({
    required this.id,
    required this.telegramMessageId,
    required this.channelId,
    required this.channelUsername,
    required this.title,
    required this.content,
    required this.category,
    required this.telegramUrl,
    required this.viewCount,
    required this.createdAt,
  });
  
  factory TelegramPost.fromFirestore(Map<String, dynamic> data, String id) {
    return TelegramPost(
      id: id,
      telegramMessageId: data['telegram_message_id'] ?? 0,
      channelId: data['channel_id'] ?? '',
      channelUsername: data['channel_username'] ?? '',
      title: data['title'] ?? 'Untitled',
      content: data['content'] ?? '',
      category: data['category'] ?? 'hiddenKnowledge',
      telegramUrl: data['telegram_url'] ?? '',
      viewCount: data['view_count'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
