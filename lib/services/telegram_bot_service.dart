import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // v2.23.0 - Firestore Integration
import 'dart:convert';
import 'dart:async';

/// Telegram Bot API Service
/// 
/// ✅ Funktioniert auf Web + Android!
/// ✅ Keine native Bibliotheken nötig
/// ✅ Direkte HTTP Requests an api.telegram.org
/// ✅ Lädt historische Inhalte aus allen 6 Kanälen
/// ✅ Bidirektionaler Chat
/// ✅ Token wird dauerhaft gespeichert
class TelegramBotService extends ChangeNotifier {
  // Singleton Pattern
  static final TelegramBotService _instance = TelegramBotService._internal();
  factory TelegramBotService() => _instance;
  TelegramBotService._internal() {
    _loadSavedToken();
  }
  
  // Storage Keys
  static const String _tokenKey = 'telegram_bot_token';
  static const String _userNameKey = 'telegram_user_name';

  // Bot Token (FEST GESPEICHERT - wird automatisch verwendet)
  static const String _fixedBotToken = '7826102549:AAHMOTvl13GlR2vousHVTE4jO0xTYuVlS7k';
  String? _botToken = _fixedBotToken;
  String get baseUrl => 'https://api.telegram.org/bot$_botToken';
  
  // MadelineProto Backend URL
  static const String madelineProtoUrl = 'http://localhost:8080';

  // Target Channels
  static const List<String> targetChannels = [
    '@WeltenbibliothekPDF',
    '@ArchivWeltenBibliothek',
    '@WeltenbibliothekWachauf',
    '@weltenbibliothekbilder',
    '@WeltenbibliothekHoerbuch',
    '@Weltenbibliothekchat',
  ];

  // State
  bool _isInitialized = false;
  bool _isPolling = false;
  String? _errorMessage;
  Map<String, dynamic>? _botInfo;
  int _lastUpdateId = 0;
  String? _currentUserName;  // Name des App-Benutzers für gesendete Nachrichten

  // Data Storage
  final Map<String, List<Map<String, dynamic>>> _channelMessages = {};
  final List<Map<String, dynamic>> _chatMessages = [];

  // Polling Timer
  Timer? _pollingTimer;
  
  // Firestore Instance (v2.23.0 - für historische Daten)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPolling => _isPolling;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get botInfo => _botInfo;
  Map<String, List<Map<String, dynamic>>> get channelMessages => _channelMessages;
  List<Map<String, dynamic>> get chatMessages => _chatMessages;
  String? get currentUserName => _currentUserName;
  
  // Setters
  Future<void> setCurrentUserName(String name) async {
    _currentUserName = name;
    await _saveUserName(name);
    notifyListeners();
  }
  
  /// Load Saved Token from Storage
  Future<void> _loadSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);
      final savedUserName = prefs.getString(_userNameKey);
      
      if (savedToken != null && savedToken.isNotEmpty) {
        _botToken = savedToken;
        debugPrint('✅ Gespeicherter Token geladen');
        
        // Auto-initialize mit gespeichertem Token
        await initialize();
      }
      
      if (savedUserName != null && savedUserName.isNotEmpty) {
        _currentUserName = savedUserName;
        debugPrint('✅ Gespeicherter Benutzername geladen: $savedUserName');
      }
    } catch (e) {
      debugPrint('⚠️ Fehler beim Laden des Tokens: $e');
    }
  }
  
  /// Save Token to Storage
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      debugPrint('💾 Token gespeichert');
    } catch (e) {
      debugPrint('❌ Fehler beim Speichern des Tokens: $e');
    }
  }
  
  /// Save User Name to Storage
  Future<void> _saveUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userNameKey, name);
      debugPrint('💾 Benutzername gespeichert: $name');
    } catch (e) {
      debugPrint('❌ Fehler beim Speichern des Benutzernamens: $e');
    }
  }

  /// Initialize Bot Service
  Future<bool> initialize([String? token]) async {
    // Update token if provided
    if (token != null && token.isNotEmpty) {
      _botToken = token;
      _isInitialized = false;  // Reset if new token
      await _saveToken(token);  // Speichere Token dauerhaft
    }
    
    if (_isInitialized) {
      debugPrint('✅ Bot Service bereits initialisiert');
      return true;
    }
    
    if (_botToken == null || _botToken!.isEmpty) {
      _errorMessage = 'Kein Bot Token angegeben';
      debugPrint('❌ Kein Token verfügbar');
      notifyListeners();
      return false;
    }

    try {
      debugPrint('🤖 Initialisiere Telegram Bot Service...');
      debugPrint('🔑 Token: ${_botToken!.substring(0, 20)}...');

      // Get Bot Info
      final response = await http.get(Uri.parse('$baseUrl/getMe'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['ok'] == true) {
          _botInfo = data['result'];
          _isInitialized = true;
          _errorMessage = null;
          
          debugPrint('✅ Bot verbunden: @${_botInfo!['username']}');
          debugPrint('📛 Bot Name: ${_botInfo!['first_name']}');
          
          notifyListeners();
          return true;
        } else {
          _errorMessage = data['description'] ?? 'Bot API Fehler';
          debugPrint('❌ Bot API Error: $_errorMessage');
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'HTTP ${response.statusCode}';
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        notifyListeners();
        return false;
      }

    } catch (e, stackTrace) {
      debugPrint('❌ Initialize Error: $e');
      debugPrint('Stack: $stackTrace');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Load Messages from Firestore (v2.23.0)
  /// 
  /// Lädt historische Nachrichten aus Firestore
  /// Dies umgeht Permission-Probleme und lädt echte Telegram-Daten
  Future<List<Map<String, dynamic>>> _loadFromFirestore({
    required String channelUsername,
    int limit = 100,
  }) async {
    try {
      debugPrint('🔥 Lade aus Firestore: $channelUsername');
      
      // Query Firestore for telegram_messages
      final querySnapshot = await _firestore
          .collection('telegram_messages')
          .where('channel', isEqualTo: channelUsername)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      
      final messages = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'message_id': doc.id,
          'text': data['text'] ?? '',
          'date': data['date'] is Timestamp 
              ? (data['date'] as Timestamp).seconds 
              : data['date'] ?? 0,
          'from': data['from'] ?? {},
          'chat': data['chat'] ?? {},
          'channel': channelUsername,
          // Medien-Felder
          'photo': data['photo'],
          'video': data['video'],
          'document': data['document'],
          'audio': data['audio'],
          'voice': data['voice'],
        };
      }).toList();
      
      debugPrint('✅ ${messages.length} Nachrichten aus Firestore geladen');
      
      // Cache die Nachrichten für spätere Verwendung
      _channelMessages[channelUsername] = messages;
      
      return messages;
      
    } catch (e) {
      debugPrint('❌ Firestore Load Error: $e');
      debugPrint('💡 Hinweis: Überprüfe Firestore Security Rules!');
      return [];
    }
  }

  /// Load Channel History
  /// 
  /// Lädt gespeicherte Nachrichten aus Channel
  /// v2.23.0: Lädt zuerst aus Firestore, dann aus Bot API Polling
  Future<List<Map<String, dynamic>>> loadChannelHistory({
    required String channelUsername,
    int limit = 100,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ Bot nicht initialisiert');
      return [];
    }

    try {
      debugPrint('📜 Lade History von $channelUsername');

      // 🔥 NEU v2.23.0: Lade zuerst aus Firestore
      final firestoreMessages = await _loadFromFirestore(
        channelUsername: channelUsername,
        limit: limit,
      );
      
      if (firestoreMessages.isNotEmpty) {
        debugPrint('✅ ${firestoreMessages.length} Nachrichten aus Firestore');
        notifyListeners();  // Update UI
        return firestoreMessages;
      }

      // Fallback: Hole gespeicherte Nachrichten aus Bot API Polling
      final messages = _channelMessages[channelUsername] ?? [];
      debugPrint('📊 Gespeicherte Nachrichten (Polling): ${messages.length}');
      
      // Sortiere nach Datum (neueste zuerst)
      messages.sort((a, b) {
        final aDate = a['date'] ?? 0;
        final bDate = b['date'] ?? 0;
        return bDate.compareTo(aDate);
      });

      return messages;

    } catch (e) {
      debugPrint('❌ loadChannelHistory Error: $e');
      return [];
    }
  }
  
  /// Load Historical Messages from MadelineProto Backend
  /// 
  /// Lädt ALLE historischen Nachrichten (auch vor Bot-Erstellung)
  Future<List<Map<String, dynamic>>> _loadHistoricalMessagesFromMadelineProto(
    String channelUsername,
    int limit,
  ) async {
    try {
      debugPrint('🔄 Lade historische Inhalte via MadelineProto: $channelUsername');
      
      final response = await http.post(
        Uri.parse('$madelineProtoUrl?action=get_history'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'peer': channelUsername,
          'limit': limit,
          'offset_id': 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final messages = data['messages']['messages'] as List?;
          
          if (messages != null && messages.isNotEmpty) {
            // Konvertiere MadelineProto Format zu unserem Format
            final converted = messages.map((msg) {
              final enriched = Map<String, dynamic>.from(msg);
              
              // Extrahiere Sender-Informationen
              enriched['_sender_name'] = _extractSenderName(msg);
              enriched['_sender_username'] = _extractSenderUsername(msg);
              enriched['_from_madelineproto'] = true;
              
              return enriched;
            }).toList();
            
            debugPrint('✅ ${converted.length} Nachrichten von MadelineProto konvertiert');
            return converted;
          }
        } else {
          debugPrint('⚠️ MadelineProto API Error: ${data['error']}');
        }
      } else {
        debugPrint('⚠️ MadelineProto HTTP Error: ${response.statusCode}');
      }

      return [];

    } catch (e) {
      debugPrint('❌ MadelineProto Error: $e');
      return [];
    }
  }

  /// Start Polling for Updates
  /// 
  /// Empfängt neue Nachrichten über Long Polling
  void startPolling() {
    if (_isPolling) {
      debugPrint('⚠️ Polling läuft bereits');
      return;
    }

    _isPolling = true;
    debugPrint('🔄 Starte Polling...');

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _pollUpdates();
    });

    notifyListeners();
  }

  /// Stop Polling
  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('⏹️ Polling gestoppt');
    notifyListeners();
  }

  /// Poll Updates (Internal)
  Future<void> _pollUpdates() async {
    if (!_isInitialized) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getUpdates'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'offset': _lastUpdateId + 1,
          'timeout': 30,
          'allowed_updates': ['message', 'channel_post', 'edited_message', 'edited_channel_post'],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['ok'] == true) {
          final updates = data['result'] as List;
          
          if (updates.isNotEmpty) {
            debugPrint('🔄 Verarbeite ${updates.length} Updates...');
            for (var update in updates) {
              _processUpdate(update);
              _lastUpdateId = update['update_id'];
            }
            notifyListeners();
          }
        }
      }

    } catch (e) {
      // Silent fail für Polling-Fehler
      debugPrint('⚠️ Polling Error: $e');
    }
  }

  /// Process Update (Internal)
  void _processUpdate(Map<String, dynamic> update) {
    try {
      // Neue Channel-Nachricht
      if (update.containsKey('channel_post')) {
        final post = update['channel_post'];
        _handleChannelPost(post, isEdit: false);
      }
      
      // Bearbeitete Channel-Nachricht
      if (update.containsKey('edited_channel_post')) {
        final post = update['edited_channel_post'];
        _handleChannelPost(post, isEdit: true);
      }

      // Neue Direktnachricht
      if (update.containsKey('message')) {
        final message = update['message'];
        _handleMessage(message, isEdit: false);
      }
      
      // Bearbeitete Direktnachricht
      if (update.containsKey('edited_message')) {
        final message = update['edited_message'];
        _handleMessage(message, isEdit: true);
      }

    } catch (e) {
      debugPrint('❌ processUpdate Error: $e');
    }
  }
  
  /// Handle Channel Post (new or edited)
  void _handleChannelPost(Map<String, dynamic> post, {required bool isEdit}) {
    final chat = post['chat'];
    final username = '@${chat['username'] ?? ''}';
    final messageId = post['message_id'];

    if (!targetChannels.contains(username)) return;

    // Initialisiere Channel-Liste
    if (!_channelMessages.containsKey(username)) {
      _channelMessages[username] = [];
    }

    // Erweitere Post mit Infos
    final enrichedPost = Map<String, dynamic>.from(post);
    enrichedPost['_sender_name'] = _extractSenderName(post);
    enrichedPost['_sender_username'] = _extractSenderUsername(post);
    enrichedPost['_message_id'] = messageId;

    // Suche nach existierender Nachricht
    final existingIndex = _channelMessages[username]!
        .indexWhere((msg) => msg['message_id'] == messageId);

    if (isEdit) {
      // Bearbeitung: Update existierende Nachricht
      if (existingIndex != -1) {
        _channelMessages[username]![existingIndex] = enrichedPost;
        debugPrint('✏️ Channel-Nachricht bearbeitet: $username (ID: $messageId)');
      } else {
        // Falls nicht gefunden, als neue Nachricht hinzufügen
        _channelMessages[username]!.insert(0, enrichedPost);
        debugPrint('✏️ Channel-Nachricht hinzugefügt (bearbeitet): $username');
      }
    } else {
      // Neue Nachricht: Prüfe Duplikate
      if (existingIndex == -1) {
        _channelMessages[username]!.insert(0, enrichedPost);
        debugPrint('📨 Neue Channel-Nachricht: $username von ${enrichedPost['_sender_name']}');
      } else {
        debugPrint('⚠️ Duplikat ignoriert: $username (ID: $messageId)');
      }
    }
  }
  
  /// Handle Message (new or edited)
  void _handleMessage(Map<String, dynamic> message, {required bool isEdit}) {
    final messageId = message['message_id'];

    // Erweitere Message mit Infos
    final enrichedMessage = Map<String, dynamic>.from(message);
    enrichedMessage['_sender_name'] = _extractSenderName(message);
    enrichedMessage['_sender_username'] = _extractSenderUsername(message);
    enrichedMessage['_message_id'] = messageId;

    // Suche nach existierender Nachricht
    final existingIndex = _chatMessages
        .indexWhere((msg) => msg['message_id'] == messageId);

    if (isEdit) {
      // Bearbeitung: Update existierende Nachricht
      if (existingIndex != -1) {
        _chatMessages[existingIndex] = enrichedMessage;
        debugPrint('✏️ Chat-Nachricht bearbeitet (ID: $messageId)');
      } else {
        // Falls nicht gefunden, als neue Nachricht hinzufügen
        _chatMessages.insert(0, enrichedMessage);
        debugPrint('✏️ Chat-Nachricht hinzugefügt (bearbeitet)');
      }
    } else {
      // Neue Nachricht: Prüfe Duplikate
      if (existingIndex == -1) {
        _chatMessages.insert(0, enrichedMessage);
        debugPrint('💬 Neue Chat-Nachricht von ${enrichedMessage['_sender_name']}');
      } else {
        debugPrint('⚠️ Duplikat ignoriert (ID: $messageId)');
      }
    }
  }
  
  /// Extract Sender Name from Message/Post
  String _extractSenderName(Map<String, dynamic> messageOrPost) {
    // Versuche verschiedene Quellen für den Namen
    
    // 1. Aus 'from' (für normale Nachrichten)
    if (messageOrPost.containsKey('from')) {
      final from = messageOrPost['from'];
      
      // Voller Name (first_name + last_name)
      final firstName = from['first_name'] ?? '';
      final lastName = from['last_name'] ?? '';
      final fullName = '$firstName ${lastName}'.trim();
      
      if (fullName.isNotEmpty) {
        return fullName;
      }
      
      // Username als Fallback
      if (from['username'] != null) {
        return '@${from['username']}';
      }
      
      // User ID als letzter Fallback
      return 'User ${from['id']}';
    }
    
    // 2. Aus 'sender_chat' (für Channel-Posts)
    if (messageOrPost.containsKey('sender_chat')) {
      final senderChat = messageOrPost['sender_chat'];
      return senderChat['title'] ?? senderChat['username'] ?? 'Unbekannt';
    }
    
    // 3. Aus 'chat' (für Channel-Nachrichten)
    if (messageOrPost.containsKey('chat')) {
      final chat = messageOrPost['chat'];
      return chat['title'] ?? '@${chat['username'] ?? 'Unbekannt'}';
    }
    
    return 'Unbekannter Absender';
  }
  
  /// Extract Sender Username from Message/Post
  String? _extractSenderUsername(Map<String, dynamic> messageOrPost) {
    // Aus 'from'
    if (messageOrPost.containsKey('from') && messageOrPost['from']['username'] != null) {
      return '@${messageOrPost['from']['username']}';
    }
    
    // Aus 'sender_chat'
    if (messageOrPost.containsKey('sender_chat') && messageOrPost['sender_chat']['username'] != null) {
      return '@${messageOrPost['sender_chat']['username']}';
    }
    
    // Aus 'chat'
    if (messageOrPost.containsKey('chat') && messageOrPost['chat']['username'] != null) {
      return '@${messageOrPost['chat']['username']}';
    }
    
    return null;
  }

  /// Send Message
  /// 
  /// Sendet eine Nachricht an einen Chat/Channel
  /// Fügt automatisch den App-Benutzernamen hinzu
  Future<bool> sendMessage({
    required String chatId,
    required String text,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ Bot nicht initialisiert');
      return false;
    }

    try {
      // Füge Benutzernamen zur Nachricht hinzu
      final userName = _currentUserName ?? 'App-Benutzer';
      final messageText = '👤 $userName:\n$text';
      
      debugPrint('📤 Sende Nachricht an $chatId als $userName');

      final response = await http.post(
        Uri.parse('$baseUrl/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chat_id': chatId,
          'text': messageText,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['ok'] == true) {
          debugPrint('✅ Nachricht gesendet');
          
          // Füge gesendete Nachricht lokal hinzu
          final sentMessage = data['result'];
          sentMessage['_sender_name'] = userName;
          sentMessage['_is_from_app'] = true;
          _chatMessages.insert(0, sentMessage);
          notifyListeners();
          
          return true;
        } else {
          debugPrint('❌ sendMessage error: ${data['description']}');
          _errorMessage = data['description'];
          notifyListeners();
          return false;
        }
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        return false;
      }

    } catch (e) {
      debugPrint('❌ sendMessage Error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get Chat Info
  Future<Map<String, dynamic>?> getChatInfo(String username) async {
    if (!_isInitialized) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getChat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'chat_id': username}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          return data['result'];
        }
      }
      return null;

    } catch (e) {
      debugPrint('❌ getChatInfo Error: $e');
      return null;
    }
  }

  /// Load All Channels
  Future<void> loadAllChannels() async {
    debugPrint('📡 Lade alle Kanäle...');

    for (var channel in targetChannels) {
      await loadChannelHistory(channelUsername: channel);
    }

    debugPrint('✅ Alle Kanäle geladen');
    notifyListeners();
  }
  
  /// Edit Message
  /// 
  /// Bearbeitet eine bereits gesendete Nachricht
  Future<bool> editMessage({
    required String chatId,
    required int messageId,
    required String newText,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ Bot nicht initialisiert');
      return false;
    }

    try {
      // Füge Benutzernamen zur bearbeiteten Nachricht hinzu
      final userName = _currentUserName ?? 'App-Benutzer';
      final messageText = '👤 $userName:\n$newText';
      
      debugPrint('✏️ Bearbeite Nachricht $messageId in $chatId');

      final response = await http.post(
        Uri.parse('$baseUrl/editMessageText'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chat_id': chatId,
          'message_id': messageId,
          'text': messageText,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['ok'] == true) {
          debugPrint('✅ Nachricht bearbeitet');
          
          // Update lokale Nachricht
          final index = _chatMessages.indexWhere((msg) => msg['message_id'] == messageId);
          if (index != -1) {
            _chatMessages[index]['text'] = messageText;
            _chatMessages[index]['edit_date'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            notifyListeners();
          }
          
          return true;
        } else {
          debugPrint('❌ editMessage error: ${data['description']}');
          _errorMessage = data['description'];
          return false;
        }
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        return false;
      }

    } catch (e) {
      debugPrint('❌ editMessage Error: $e');
      _errorMessage = e.toString();
      return false;
    }
  }
  
  /// Delete Message
  /// 
  /// Löscht eine Nachricht
  Future<bool> deleteMessage({
    required String chatId,
    required int messageId,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ Bot nicht initialisiert');
      return false;
    }

    try {
      debugPrint('🗑️ Lösche Nachricht $messageId in $chatId');

      final response = await http.post(
        Uri.parse('$baseUrl/deleteMessage'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chat_id': chatId,
          'message_id': messageId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['ok'] == true) {
          debugPrint('✅ Nachricht gelöscht');
          
          // Entferne lokale Nachricht
          _chatMessages.removeWhere((msg) => msg['message_id'] == messageId);
          notifyListeners();
          
          return true;
        } else {
          debugPrint('❌ deleteMessage error: ${data['description']}');
          _errorMessage = data['description'];
          return false;
        }
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        return false;
      }

    } catch (e) {
      debugPrint('❌ deleteMessage Error: $e');
      _errorMessage = e.toString();
      return false;
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
