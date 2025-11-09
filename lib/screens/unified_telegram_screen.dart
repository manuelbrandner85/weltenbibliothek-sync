import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/multi_channel_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/offline_storage_service.dart';
import '../config/app_theme.dart';
import '../widgets/media_viewers.dart';

/// Vereinheitlichter Telegram-Screen
/// Alle Telegram-Funktionen an einem Ort:
/// - Kategorien (Hörbücher, PDFs, Bilder, etc.)
/// - Themen-Unterordner
/// - Chat senden/empfangen/löschen/bearbeiten
/// - Bidirektionale Synchronisation
class UnifiedTelegramScreen extends StatefulWidget {
  const UnifiedTelegramScreen({super.key});

  @override
  State<UnifiedTelegramScreen> createState() => _UnifiedTelegramScreenState();
}

class _UnifiedTelegramScreenState extends State<UnifiedTelegramScreen> with SingleTickerProviderStateMixin {
  final MultiChannelService _service = MultiChannelService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  String? _selectedCategory;
  String? _selectedTopic;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Neue State-Variablen für Verbesserungen
  String _searchQuery = '';
  bool _isSearching = false;
  int _messagesLimit = 100;
  final Map<String, int> _messageCounts = {};
  
  // ✅ NEU: Typing Indicator, Favoriten, Read Receipts
  bool _isTyping = false;
  Timer? _typingTimer;
  final Set<String> _favoriteMessages = {};
  final Set<String> _readMessages = {};
  
  // ✅ NEU: Filter-Optionen
  String _activeFilter = 'all'; // 'all', 'favorites', 'unread'
  
  // Kategorien mit Icons und Farben
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'audiobooks',
      'name': 'Hörbücher',
      'icon': Icons.headset,
      'color': AppTheme.occultEvents,
      'collection': 'hoerbuch_messages',
    },
    {
      'id': 'pdfs',
      'name': 'PDF Dokumente',
      'icon': Icons.picture_as_pdf,
      'color': AppTheme.secretSocieties,
      'collection': 'pdf_messages',
    },
    {
      'id': 'images',
      'name': 'Bilder',
      'icon': Icons.image,
      'color': AppTheme.techMysteries,
      'collection': 'bilder_messages',
    },
    {
      'id': 'wachauf',
      'name': 'Wach Auf',
      'icon': Icons.bolt,
      'color': AppTheme.energyPhenomena,
      'collection': 'wachauf_messages',
    },
    {
      'id': 'archive',
      'name': 'Archiv',
      'icon': Icons.archive,
      'color': AppTheme.dimensionalAnomalies,
      'collection': 'archiv_messages',
    },
    {
      'id': 'chat',
      'name': 'Chat',
      'icon': Icons.chat_bubble,
      'color': AppTheme.alienContact,
      'collection': 'chat_messages',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadMessageCounts();
    _loadFavoritesAndReadReceipts();
    _initializeAuth();
  }
  
  /// Initialisiere Authentication
  Future<void> _initializeAuth() async {
    // Automatische anonyme Anmeldung wenn nicht eingeloggt
    if (!_authService.isSignedIn) {
      await _authService.signInAnonymously();
    }
    
    // Update Last Seen
    await _authService.updateLastSeen();
    
    // Initialisiere Push Notifications
    _initializeNotifications();
  }
  
  /// Initialisiere Push Notifications
  Future<void> _initializeNotifications() async {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      // Subscribe to all channels
      await notificationService.subscribeToTopic('all_messages');
      await notificationService.subscribeToTopic('chat_messages');
      
    } catch (e) {
      debugPrint('⚠️ Notification Initialisierung fehlgeschlagen: $e');
    }
  }
  
  /// ✅ Lade Favoriten und Read Receipts aus SharedPreferences
  Future<void> _loadFavoritesAndReadReceipts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favorite_messages') ?? [];
      final read = prefs.getStringList('read_messages') ?? [];
      
      if (mounted) {
        setState(() {
          _favoriteMessages.addAll(favorites);
          _readMessages.addAll(read);
        });
      }
    } catch (e) {
      debugPrint('⚠️ Fehler beim Laden der Favoriten/Read Receipts: $e');
    }
  }
  
  /// ✅ Speichere Favoriten
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_messages', _favoriteMessages.toList());
    } catch (e) {
      debugPrint('⚠️ Fehler beim Speichern der Favoriten: $e');
    }
  }
  
  /// ✅ Speichere Read Receipts
  Future<void> _saveReadReceipts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('read_messages', _readMessages.toList());
    } catch (e) {
      debugPrint('⚠️ Fehler beim Speichern der Read Receipts: $e');
    }
  }
  
  /// Lade Message-Counts für alle Kategorien
  Future<void> _loadMessageCounts() async {
    for (final category in _categories) {
      final collection = category['collection'] as String;
      final snapshot = await _firestore.collection(collection).get();
      if (mounted) {
        setState(() {
          _messageCounts[collection] = snapshot.docs.length;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }
  
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = _categories[_tabController.index]['id'];
        _selectedTopic = null; // Reset topic when changing category
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Suche in Nachrichten...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                ),
                onChanged: _performSearch,
              )
            : const Text(
                'Telegram Bibliothek',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              // Kategorie-Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.primaryTeal,
                indicatorWeight: 3,
                labelColor: AppTheme.primaryTeal,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: _categories.map((cat) {
                  final collection = cat['collection'] as String;
                  final count = _messageCounts[collection] ?? 0;
                  
                  return Tab(
                    child: Row(
                      children: [
                        Icon(cat['icon'] as IconData, size: 20),
                        const SizedBox(width: 8),
                        Text(cat['name'] as String),
                        if (count > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          // Filter
          if (!_isSearching)
            PopupMenuButton<String>(
              icon: Icon(
                _activeFilter == 'all' ? Icons.filter_list : Icons.filter_alt,
                color: _activeFilter == 'all' ? Colors.white : AppTheme.primaryTeal,
              ),
              tooltip: 'Filter',
              onSelected: (filter) {
                setState(() {
                  _activeFilter = filter;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.list, color: _activeFilter == 'all' ? AppTheme.primaryTeal : Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Alle anzeigen'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'favorites',
                  child: Row(
                    children: [
                      Icon(Icons.star, color: _activeFilter == 'favorites' ? AppTheme.primaryTeal : Colors.grey),
                      const SizedBox(width: 8),
                      Text('Nur Favoriten (${_favoriteMessages.length})'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'unread',
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_unread, color: _activeFilter == 'unread' ? AppTheme.primaryTeal : Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Nur Ungelesen'),
                    ],
                  ),
                ),
              ],
            ),
          // Statistiken
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'Statistiken',
              onPressed: _showStatistics,
            ),
          // Suche
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _showSearchDialog,
          ),
          // Einstellungen (nur wenn nicht im Suchmodus)
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettings,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Lade Message-Counts neu
          await _loadMessageCounts();
          // UI aktualisieren
          if (mounted) {
            setState(() {});
          }
        },
        color: AppTheme.primaryTeal,
        backgroundColor: AppTheme.surfaceDark,
        child: TabBarView(
          controller: _tabController,
          children: _categories.map((category) {
            return _buildCategoryView(category);
          }).toList(),
        ),
      ),
      // Chat-Eingabe (nur in Chat-Kategorie sichtbar)
      bottomSheet: _selectedCategory == 'chat'
          ? _buildChatInput()
          : null,
    );
  }
  
  /// Kategorie-Ansicht mit Themen
  Widget _buildCategoryView(Map<String, dynamic> category) {
    final collection = category['collection'] as String;
    
    return Column(
      children: [
        // Themen-Filter (wenn vorhanden)
        _buildTopicFilter(collection),
        
        // Nachrichten-Liste
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection(collection)
                .limit(_messagesLimit)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorView(snapshot.error.toString());
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyView(category['name'] as String);
              }
              
              var docs = snapshot.data!.docs;
              
              // ✅ Sortiere im Memory (vermeidet Firestore Index-Probleme)
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = aData['timestamp'] ?? aData['date'] ?? 0;
                final bTime = bData['timestamp'] ?? bData['date'] ?? 0;
                return bTime.compareTo(aTime); // Descending
              });
              
              // ✅ Cache Nachrichten für Offline-Zugriff
              OfflineStorageService().cacheMessages(collection, docs);
              
              // Filter nach Thema, Suchbegriff, Favoriten, Ungelesen
              var filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final docId = doc.id;
                
                // Themen-Filter
                if (_selectedTopic != null && data['topic'] != _selectedTopic) {
                  return false;
                }
                
                // Such-Filter
                if (!_matchesSearch(data)) {
                  return false;
                }
                
                // ✅ NEU: Favoriten-Filter
                if (_activeFilter == 'favorites' && !_favoriteMessages.contains(docId)) {
                  return false;
                }
                
                // ✅ NEU: Ungelesen-Filter
                if (_activeFilter == 'unread' && _readMessages.contains(docId)) {
                  return false;
                }
                
                return true;
              }).toList();
              
              if (filteredDocs.isEmpty) {
                return _searchQuery.isNotEmpty 
                    ? _buildEmptySearchView()
                    : _buildEmptyTopicView();
              }
              
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        
                        return _buildMessageCard(
                          doc.id,
                          data,
                          category['color'] as int,
                          collection,
                          filteredDocs,
                          index,
                        );
                      },
                    ),
                  ),
                  // "Mehr laden" Button (nur anzeigen wenn Limit erreicht)
                  if (docs.length >= _messagesLimit)
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.backgroundDark,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _messagesLimit += 50;
                          });
                        },
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Mehr laden (+50)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceDark,
                          foregroundColor: AppTheme.primaryTeal,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
  
  /// Themen-Filter
  Widget _buildTopicFilter(String collection) {
    return FutureBuilder<List<String>>(
      future: _getTopicsForCollection(collection),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final topics = snapshot.data!;
        
        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: topics.length + 1, // +1 für "Alle"
            itemBuilder: (context, index) {
              if (index == 0) {
                // "Alle" Chip mit Icon
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      Icons.grid_view,
                      size: 18,
                      color: _selectedTopic == null ? Colors.white : AppTheme.textSecondary,
                    ),
                    label: const Text('Alle'),
                    selected: _selectedTopic == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTopic = null;
                      });
                    },
                    selectedColor: AppTheme.primaryTeal,
                    backgroundColor: AppTheme.backgroundDark,
                    side: BorderSide(
                      color: _selectedTopic == null 
                          ? AppTheme.primaryTeal 
                          : AppTheme.textSecondary.withOpacity(0.3),
                      width: _selectedTopic == null ? 2 : 1,
                    ),
                    labelStyle: TextStyle(
                      color: _selectedTopic == null ? Colors.white : AppTheme.textPrimary,
                      fontWeight: _selectedTopic == null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }
              
              final topic = topics[index - 1];
              final isSelected = _selectedTopic == topic;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: Icon(
                    Icons.folder,
                    size: 18,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                  label: Text(topic),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTopic = selected ? topic : null;
                    });
                  },
                  selectedColor: AppTheme.primaryTeal,
                  backgroundColor: AppTheme.backgroundDark,
                  side: BorderSide(
                    color: isSelected 
                        ? AppTheme.primaryTeal 
                        : AppTheme.textSecondary.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  /// Nachrichtenkarte
  Widget _buildMessageCard(
    String docId,
    Map<String, dynamic> data,
    int categoryColor,
    String collection,
    List<QueryDocumentSnapshot> allDocs,
    int currentIndex,
  ) {
    final text = data['text'] ?? data['message'] ?? '';
    final mediaUrl = _getMediaUrl(data);
    final timestamp = _getTimestamp(data);
    final topic = data['topic'] as String?;
    
    // ✅ VERBESSERT: Bevorzuge Telegram-Username über from_name
    String senderName = 'Weltenbibliothek';
    
    if (data['telegramUsername'] != null && data['telegramUsername'].toString().isNotEmpty) {
      senderName = '@${data['telegramUsername']}';
    } else if (data['from_name'] != null && data['from_name'].toString().isNotEmpty) {
      senderName = data['from_name'].toString();
    } else if (data['telegramFirstName'] != null) {
      final firstName = data['telegramFirstName'].toString();
      final lastName = data['telegramLastName']?.toString() ?? '';
      senderName = '$firstName $lastName'.trim();
    }
    
    final fromId = data['from_id']?.toString() ?? 'Unbekannt';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surfaceDark,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Color(categoryColor).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _markAsRead(docId); // Auto-mark as read
          _showMessageDetails(docId, data, collection);
        },
        onLongPress: () => _showMessageActions(context, docId, data, collection),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Thema und Zeitstempel
              Row(
                children: [
                  // ✅ NEU: Favorit-Icon
                  if (_favoriteMessages.contains(docId))
                    const Icon(Icons.star, size: 16, color: AppTheme.primaryTeal),
                  if (_favoriteMessages.contains(docId)) const SizedBox(width: 4),
                  
                  // ✅ NEU: Read-Status
                  if (!_readMessages.contains(docId))
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (!_readMessages.contains(docId)) const SizedBox(width: 8),
                  
                  if (topic != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(categoryColor).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        topic,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(categoryColor),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      _formatTimestamp(timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  // Aktions-Menü
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    onSelected: (action) {
                      _handleMessageAction(action, docId, data, collection);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Bearbeiten'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Löschen', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 18),
                            SizedBox(width: 8),
                            Text('Teilen'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Medien (Bild, Video, Audio)
              if (mediaUrl != null) ...[
                _buildMediaPreview(mediaUrl, data, allDocs, currentIndex),
                const SizedBox(height: 8),
              ],
              
              // Text-Nachricht
              if (text.isNotEmpty)
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              
              // Footer mit von Info - ✅ Zeigt jetzt Telegram-Username
              const SizedBox(height: 8),
              Text(
                'Von: $senderName',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Medien-Vorschau
  Widget _buildMediaPreview(
    String mediaUrl, 
    Map<String, dynamic> data,
    List<QueryDocumentSnapshot> allDocs,
    int currentIndex,
  ) {
    final mediaType = data['mediaType'] ?? 'unknown';
    
    // WICHTIG: Korrigiere URL-Format
    final correctedUrl = _correctMediaUrl(mediaUrl);
    
    if (mediaType == 'photo' || mediaType == 'image') {
      // 📸 Erkenne Bilder-Album
      final albumUrls = _detectImageAlbum(allDocs, currentIndex);
      final imagesToShow = albumUrls.isNotEmpty ? albumUrls : [correctedUrl];
      
      return GestureDetector(
        onTap: () {
          // Öffne Bilder-Galerie (mit Album-Support)
          final currentImageIndex = albumUrls.isNotEmpty 
              ? albumUrls.indexOf(correctedUrl).clamp(0, albumUrls.length - 1)
              : 0;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageGalleryViewer(
                imageUrls: imagesToShow,
                text: data['text']?.toString(),
                initialIndex: currentImageIndex,
              ),
            ),
          );
        },
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: correctedUrl,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 300,
                  color: AppTheme.surfaceDark,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 300,
                  color: AppTheme.surfaceDark,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image,
                        size: 48,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bild konnte nicht geladen werden',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        correctedUrl,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 📸 Album-Badge (zeigt Anzahl der Bilder)
            if (albumUrls.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.collections,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${albumUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    if (mediaType == 'video') {
      return GestureDetector(
        onTap: () {
          // Öffne Video-Player
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerViewer(
                videoUrl: correctedUrl,
                title: data['text']?.toString() ?? 'Video',
              ),
            ),
          );
        },
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_circle_outline,
                size: 48,
                color: AppTheme.primaryTeal,
              ),
              const SizedBox(height: 8),
              const Text(
                'Video',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                correctedUrl,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }
    
    if (mediaType == 'document' || mediaType == 'pdf') {
      return GestureDetector(
        onTap: () {
          // Öffne PDF-Viewer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen(
                pdfUrl: correctedUrl,
                title: correctedUrl.split('/').last,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.secretSocieties.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.picture_as_pdf,
                size: 40,
                color: AppTheme.secretSocieties,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PDF Dokument',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      correctedUrl.split('/').last,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                color: AppTheme.primaryTeal,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PDFViewerScreen(
                        pdfUrl: correctedUrl,
                        title: correctedUrl.split('/').last,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }
    
    // Audio/Podcast
    if (mediaType == 'audio' || mediaType == 'voice' || correctedUrl.contains('/audios/')) {
      return GestureDetector(
        onTap: () {
          // Öffne Audio-Player
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudioPlayerScreen(
                audioUrl: correctedUrl,
                title: data['text']?.toString() ?? correctedUrl.split('/').last,
                subtitle: _getSenderDisplay(data),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.audiotrack,
                size: 40,
                color: AppTheme.primaryTeal,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Audio / Hörbuch',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['text']?.toString() ?? correctedUrl.split('/').last,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.play_circle_outline,
                size: 32,
                color: AppTheme.primaryTeal,
              ),
            ],
          ),
        ),
      );
    }
    
    // Fallback für unbekannte Medientypen
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              correctedUrl,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Chat-Eingabe
  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Anhang-Button
            IconButton(
              icon: const Icon(Icons.attach_file),
              color: AppTheme.primaryTeal,
              onPressed: _attachFile,
            ),
            
            // Eingabefeld
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: _isTyping ? '💬 Tippt...' : 'Nachricht schreiben...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.newline,
                onChanged: (text) {
                  _setTyping(text.isNotEmpty);
                },
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Senden-Button
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send),
                color: Colors.white,
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // === HELPER FUNKTIONEN ===
  
  /// Hole Media-URL aus Document
  String? _getMediaUrl(Map<String, dynamic> data) {
    if (data['mediaUrl'] != null && data['mediaUrl'].toString().isNotEmpty) {
      return data['mediaUrl'].toString();
    }
    if (data['ftpPath'] != null && data['ftpPath'].toString().isNotEmpty) {
      final ftpPath = data['ftpPath'].toString();
      return 'http://Weltenbibliothek.ddns.net:8080$ftpPath';
    }
    return null;
  }
  
  /// Korrigiere Media-URL Format (Optimiert für FTP/HTTP Server)
  String _correctMediaUrl(String url) {
    // Bereits vollständige URL → direkt zurückgeben
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // Entferne führende Slashes
    url = url.replaceFirst(RegExp(r'^/+'), '');
    
    // Entferne doppelte Slashes
    url = url.replaceAll(RegExp(r'//+'), '/');
    
    // Stelle sicher dass URL korrekt encodiert ist (Umlaute, Leerzeichen)
    final parts = url.split('/');
    final encodedParts = parts.map((part) => Uri.encodeComponent(part)).join('/');
    
    // Baue vollständige URL mit HTTP-Server
    return 'http://Weltenbibliothek.ddns.net:8080/$encodedParts';
  }
  
  /// Extrahiere Timestamp
  DateTime _getTimestamp(Map<String, dynamic> data) {
    try {
      final timestamp = data['timestamp'];
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    } catch (e) {
      // Fallback
    }
    return DateTime.now();
  }
  
  /// Formatiere Timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return 'Gerade eben';
    } else if (diff.inHours < 1) {
      return 'vor ${diff.inMinutes} Min';
    } else if (diff.inDays < 1) {
      return 'vor ${diff.inHours} Std';
    } else if (diff.inDays < 7) {
      return 'vor ${diff.inDays} Tagen';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }
  
  /// Hole Themen für Collection
  Future<List<String>> _getTopicsForCollection(String collection) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .limit(100)
          .get();
      
      final topics = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['topic'] != null && data['topic'].toString().isNotEmpty) {
          topics.add(data['topic'].toString());
        }
      }
      
      return topics.toList()..sort();
    } catch (e) {
      return [];
    }
  }
  
  // === AKTIONS-HANDLER ===
  
  /// Nachricht senden
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    try {
      // Hole aktuelle Kategorie
      final category = _categories[_tabController.index];
      final collection = category['collection'] as String;
      
      // ⚠️ WICHTIG: Nur Chat-Messages können gesendet werden!
      if (collection != 'chat_messages') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💬 Nachrichten können nur im Chat-Kanal gesendet werden'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      // Sende zu Firestore (nur chat_messages)
      await _firestore.collection('chat_messages').add({
        'text': text,
        'message': text, // Duplikat für Kompatibilität
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unix timestamp
        'from_id': _authService.getUserId(),
        'from_name': _authService.getUserDisplayName(),
        'mediaType': 'text',
        'topic': _selectedTopic,
        // ✅ WICHTIG: Felder für bidirektionale Sync
        'source': 'app', // Von Flutter App
        'syncedToTelegram': false, // Noch nicht zu Telegram gesendet
        'synced': false, // Backward compatibility
      });
      
      // Leere Eingabefeld
      _messageController.clear();
      
      // Scroll nach unten
      _scrollToBottom();
      
      // Zeige Erfolg
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Nachricht gesendet und wird zu Telegram synchronisiert'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Fehler beim Senden: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Datei anhängen
  Future<void> _attachFile() async {
    try {
      // Prüfe aktuelle Kategorie
      final category = _categories[_tabController.index];
      final collection = category['collection'] as String;
      
      // Nur im Chat erlaubt
      if (collection != 'chat_messages') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📎 Datei-Upload nur im Chat-Kanal möglich'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Öffne File Picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'mp4', 'mp3', 'doc', 'docx'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = result.files.single.size;
        
        // Größen-Check (Max 10MB)
        if (fileSize > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Datei zu groß (max 10MB)'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Zeige Upload-Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('📤 Datei hochladen', style: TextStyle(color: AppTheme.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primaryTeal),
                const SizedBox(height: 16),
                Text(
                  'Lade $fileName hoch...',
                  style: const TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
        
        // Konvertiere zu Base64 für Firebase
        final bytes = await file.readAsBytes();
        final base64File = base64Encode(bytes);
        
        // Bestimme Media-Type
        String mediaType = 'document';
        if (fileName.toLowerCase().endsWith('.jpg') || 
            fileName.toLowerCase().endsWith('.jpeg') || 
            fileName.toLowerCase().endsWith('.png')) {
          mediaType = 'photo';
        } else if (fileName.toLowerCase().endsWith('.pdf')) {
          mediaType = 'pdf';
        } else if (fileName.toLowerCase().endsWith('.mp4')) {
          mediaType = 'video';
        } else if (fileName.toLowerCase().endsWith('.mp3')) {
          mediaType = 'audio';
        }
        
        // Upload zu Firestore
        await _firestore.collection('chat_messages').add({
          'text': '📎 Datei: $fileName',
          'message': '📎 Datei: $fileName',
          'timestamp': FieldValue.serverTimestamp(),
          'date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'from_id': _authService.getUserId(),
          'from_name': _authService.getUserDisplayName(),
          'mediaType': mediaType,
          'fileName': fileName,
          'fileSize': fileSize,
          'fileData': base64File,
          'source': 'app',
          'syncedToTelegram': false,
          'synced': false,
        });
        
        // Schließe Dialog
        if (context.mounted) Navigator.pop(context);
        
        // Zeige Erfolg
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $fileName erfolgreich hochgeladen'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        // Scroll nach unten
        _scrollToBottom();
        
      } else {
        // User hat abgebrochen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Dateiauswahl abgebrochen'),
          ),
        );
      }
    } catch (e) {
      // Schließe Dialog falls offen
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Nachricht bearbeiten
  Future<void> _handleMessageAction(
    String action,
    String docId,
    Map<String, dynamic> data,
    String collection,
  ) async {
    switch (action) {
      case 'edit':
        await _editMessage(docId, data, collection);
        break;
      case 'delete':
        await _deleteMessage(docId, collection);
        break;
      case 'share':
        _shareMessage(data);
        break;
    }
  }
  
  /// Bearbeite Nachricht
  Future<void> _editMessage(
    String docId,
    Map<String, dynamic> data,
    String collection,
  ) async {
    final controller = TextEditingController(text: data['text'] ?? '');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nachricht bearbeiten'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Nachricht...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      try {
        await _firestore.collection(collection).doc(docId).update({
          'text': result,
          'edited': true,
          'edited_at': FieldValue.serverTimestamp(),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Nachricht aktualisiert')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Lösche Nachricht
  Future<void> _deleteMessage(String docId, String collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nachricht löschen'),
        content: const Text('Möchten Sie diese Nachricht wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _firestore.collection(collection).doc(docId).delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Nachricht gelöscht')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Teile Nachricht
  void _shareMessage(Map<String, dynamic> data) {
    // TODO: Implementiere Share-Funktionalität
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 Share-Funktionalität wird implementiert...'),
      ),
    );
  }
  
  /// Zeige Nachrichten-Details
  void _showMessageDetails(
    String docId,
    Map<String, dynamic> data,
    String collection,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Titel
              const Text(
                'Nachrichten-Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailItem('ID', docId),
                    _buildDetailItem('Collection', collection),
                    _buildDetailItem('Text', data['text'] ?? '-'),
                    _buildDetailItem('Von', data['from_id']?.toString() ?? '-'),
                    _buildDetailItem('Thema', data['topic']?.toString() ?? '-'),
                    _buildDetailItem(
                      'Zeitstempel',
                      _formatTimestamp(_getTimestamp(data)),
                    ),
                    if (data['mediaUrl'] != null)
                      _buildDetailItem('Media URL', data['mediaUrl'].toString()),
                    if (data['ftpPath'] != null)
                      _buildDetailItem('FTP Path', data['ftpPath'].toString()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  // _showMessageActions entfernt - siehe erweiterte Version unten mit Favoriten/Read Receipts
  
  /// Toggle Suchmodus
  void _showSearchDialog() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }
  
  /// Führe Suche aus
  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }
  
  /// Prüfe ob Nachricht Suchbegriff enthält
  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;
    
    final text = (data['text'] ?? '').toString().toLowerCase();
    final caption = (data['caption'] ?? '').toString().toLowerCase();
    final topic = (data['topic'] ?? '').toString().toLowerCase();
    final fromName = (data['from_name'] ?? '').toString().toLowerCase();
    
    return text.contains(_searchQuery) || 
           caption.contains(_searchQuery) || 
           topic.contains(_searchQuery) ||
           fromName.contains(_searchQuery);
  }
  
  /// ✅ NEU: Hole Absender-Anzeige (bevorzugt Telegram-Username)
  String _getSenderDisplay(Map<String, dynamic> data) {
    if (data['telegramUsername'] != null && data['telegramUsername'].toString().isNotEmpty) {
      final firstName = data['telegramFirstName']?.toString() ?? '';
      final lastName = data['telegramLastName']?.toString() ?? '';
      final fullName = '$firstName $lastName'.trim();
      
      if (fullName.isNotEmpty) {
        return '$fullName (@${data['telegramUsername']})';
      }
      return '@${data['telegramUsername']}';
    }
    
    if (data['from_name'] != null && data['from_name'].toString().isNotEmpty) {
      return data['from_name'].toString();
    }
    
    if (data['telegramFirstName'] != null) {
      final firstName = data['telegramFirstName'].toString();
      final lastName = data['telegramLastName']?.toString() ?? '';
      return '$firstName $lastName'.trim();
    }
    
    return 'Weltenbibliothek';
  }
  
  /// Einstellungen
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Einstellungen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Synchronisation'),
              subtitle: const Text('Automatisch alle 3 Sekunden'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: Toggle sync
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Auto-Löschen'),
              subtitle: const Text('Nach 6 Stunden'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: Toggle auto-delete
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Benachrichtigungen'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: Toggle notifications
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Scroll nach unten
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  /// Empty View
  Widget _buildEmptyView(String categoryName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Keine $categoryName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Noch keine Inhalte vorhanden',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Empty Topic View
  Widget _buildEmptyTopicView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keine Inhalte für dieses Thema',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedTopic = null;
              });
            },
            child: const Text('Alle Themen anzeigen'),
          ),
        ],
      ),
    );
  }
  
  /// Empty Search View
  Widget _buildEmptySearchView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Ergebnisse für "$_searchQuery"',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Versuche einen anderen Suchbegriff',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Error View
  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Fehler beim Laden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {}); // Rebuild to retry
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Neu laden'),
          ),
        ],
      ),
    );
  }
  
  // ========================================
  // ✅ NEUE FEATURES: Favoriten, Read Receipts, Statistiken
  // ========================================
  
  /// Toggle Favorit
  Future<void> _toggleFavorite(String messageId) async {
    setState(() {
      if (_favoriteMessages.contains(messageId)) {
        _favoriteMessages.remove(messageId);
      } else {
        _favoriteMessages.add(messageId);
      }
    });
    await _saveFavorites();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _favoriteMessages.contains(messageId) 
              ? '⭐ Zu Favoriten hinzugefügt' 
              : '❌ Von Favoriten entfernt'
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  /// Markiere als gelesen
  Future<void> _markAsRead(String messageId) async {
    if (!_readMessages.contains(messageId)) {
      setState(() {
        _readMessages.add(messageId);
      });
      await _saveReadReceipts();
    }
  }
  
  /// Typing Indicator setzen
  void _setTyping(bool typing) {
    _typingTimer?.cancel();
    
    setState(() {
      _isTyping = typing;
    });
    
    if (typing) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
        }
      });
    }
  }
  
  /// Erweiterte Long-Press Actions
  void _showMessageActions(BuildContext context, String messageId, Map<String, dynamic> data, String collection) {
    final isFavorite = _favoriteMessages.contains(messageId);
    final isRead = _readMessages.contains(messageId);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(isFavorite ? Icons.star : Icons.star_border, color: AppTheme.primaryTeal),
              title: Text(isFavorite ? 'Von Favoriten entfernen' : 'Zu Favoriten hinzufügen'),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(messageId);
              },
            ),
            ListTile(
              leading: Icon(isRead ? Icons.mark_email_unread : Icons.mark_email_read, color: AppTheme.primaryTeal),
              title: Text(isRead ? 'Als ungelesen markieren' : 'Als gelesen markieren'),
              onTap: () {
                Navigator.pop(context);
                if (isRead) {
                  setState(() => _readMessages.remove(messageId));
                  _saveReadReceipts();
                } else {
                  _markAsRead(messageId);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppTheme.primaryTeal),
              title: const Text('Text kopieren'),
              onTap: () async {
                Navigator.pop(context);
                final text = data['text'] ?? data['message'] ?? data['caption'] ?? '';
                if (text.isNotEmpty) {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 Text in Zwischenablage kopiert'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppTheme.primaryTeal),
              title: const Text('Teilen'),
              onTap: () async {
                Navigator.pop(context);
                final text = data['text'] ?? data['message'] ?? data['caption'] ?? '';
                final fromName = data['from_name'] ?? 'Weltenbibliothek';
                final topic = data['topic'] ?? '';
                
                String shareText = text;
                if (topic.isNotEmpty) {
                  shareText = '[$topic] $text';
                }
                shareText += '\n\n📚 Via Weltenbibliothek - $fromName';
                
                if (shareText.isNotEmpty) {
                  await Share.share(shareText, subject: 'Weltenbibliothek Nachricht');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: AppTheme.primaryTeal),
              title: const Text('Info'),
              onTap: () {
                Navigator.pop(context);
                _showMessageInfo(data);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  
  /// Zeige Message-Info
  void _showMessageInfo(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Nachrichten-Info', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Absender:', _getSenderDisplay(data)),
            if (data['telegramUsername'] != null) 
              _buildInfoRow('Telegram:', '@${data['telegramUsername']}'),
            _buildInfoRow('Zeitstempel:', _formatTimestamp(_getTimestamp(data))),
            if (data['topic'] != null) _buildInfoRow('Thema:', data['topic']),
            if (data['mediaType'] != null) _buildInfoRow('Medientyp:', data['mediaType']),
            _buildInfoRow('Message ID:', data['messageId']?.toString() ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen', style: TextStyle(color: AppTheme.primaryTeal)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Statistiken anzeigen
  void _showStatistics() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '📊 Statistiken',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildStatCard('Gesamt Nachrichten', _messageCounts.values.fold(0, (a, b) => a + b).toString(), Icons.message),
                      _buildStatCard('Favoriten', _favoriteMessages.length.toString(), Icons.star),
                      _buildStatCard('Gelesen', _readMessages.length.toString(), Icons.check_circle),
                      
                      // ✅ NEU: Export-Buttons
                      if (_favoriteMessages.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: ElevatedButton.icon(
                            onPressed: _exportFavorites,
                            icon: const Icon(Icons.download),
                            label: const Text('Favoriten exportieren'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTeal,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ),
                      
                      ..._categories.map((cat) {
                        final collection = cat['collection'] as String;
                        final count = _messageCounts[collection] ?? 0;
                        return _buildStatCard(cat['name'] as String, count.toString(), cat['icon'] as IconData);
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryTeal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTeal,
            ),
          ),
        ],
      ),
    );
  }
  
  // ========================================
  // ✅ EXPORT FUNKTIONALITÄT
  // ========================================
  
  /// Exportiere Favoriten als Text
  Future<void> _exportFavorites() async {
    if (_favoriteMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📭 Keine Favoriten zum Exportieren')),
      );
      return;
    }
    
    try {
      final StringBuffer export = StringBuffer();
      export.writeln('📚 WELTENBIBLIOTHEK - FAVORITEN EXPORT');
      export.writeln('═' * 50);
      export.writeln('Exportiert am: ${DateTime.now().toString().split('.')[0]}');
      export.writeln('Anzahl Favoriten: ${_favoriteMessages.length}');
      export.writeln('═' * 50);
      export.writeln();
      
      int counter = 1;
      for (final messageId in _favoriteMessages) {
        // Versuche Nachricht aus allen Collections zu laden
        for (final category in _categories) {
          final collection = category['collection'] as String;
          try {
            final doc = await _firestore.collection(collection).doc(messageId).get();
            if (doc.exists) {
              final data = doc.data()!;
              final text = data['text'] ?? data['message'] ?? data['caption'] ?? '';
              final topic = data['topic'] ?? '';
              final fromName = data['from_name'] ?? 'Unbekannt';
              final timestamp = _getTimestamp(data);
              
              export.writeln('[$counter] ${category['name']}');
              if (topic.isNotEmpty) export.writeln('Thema: $topic');
              export.writeln('Von: $fromName');
              export.writeln('Datum: ${_formatTimestamp(timestamp)}');
              export.writeln('─' * 50);
              export.writeln(text);
              export.writeln();
              export.writeln('═' * 50);
              export.writeln();
              
              counter++;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }
      
      export.writeln();
      export.writeln('📱 Weltenbibliothek App');
      export.writeln('🔗 weltenbibliothek.ddns.net');
      
      // Teile den Export-Text
      await Share.share(
        export.toString(),
        subject: 'Weltenbibliothek Favoriten Export (${_favoriteMessages.length} Einträge)',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${_favoriteMessages.length} Favoriten exportiert'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Export fehlgeschlagen: $e')),
        );
      }
    }
  }
  
  /// 📸 Hilfsfunktion: Erkennt Bilder-Alben (mehrere Bilder innerhalb 1 Sekunde vom selben Absender)
  List<String> _detectImageAlbum(List<QueryDocumentSnapshot> docs, int currentIndex) {
    final List<String> albumUrls = [];
    final currentDoc = docs[currentIndex];
    final currentData = currentDoc.data() as Map<String, dynamic>;
    final currentMediaType = currentData['mediaType'] ?? '';
    
    // Nur für Bilder relevant
    if (currentMediaType != 'photo' && currentMediaType != 'image') {
      return [];
    }
    
    final currentTimestamp = _getTimestamp(currentData);
    final currentFromId = currentData['from_id']?.toString() ?? '';
    final currentMediaUrl = _getMediaUrl(currentData);
    
    if (currentMediaUrl == null || currentMediaUrl.isEmpty) {
      return [];
    }
    
    // Füge das aktuelle Bild hinzu
    albumUrls.add(_correctMediaUrl(currentMediaUrl));
    
    // Prüfe die nächsten 10 Nachrichten auf weitere Bilder im gleichen Zeitfenster
    for (int i = currentIndex + 1; i < docs.length && i < currentIndex + 10; i++) {
      final nextDoc = docs[i];
      final nextData = nextDoc.data() as Map<String, dynamic>;
      final nextMediaType = nextData['mediaType'] ?? '';
      final nextTimestamp = _getTimestamp(nextData);
      final nextFromId = nextData['from_id']?.toString() ?? '';
      final nextMediaUrl = _getMediaUrl(nextData);
      
      // Muss ein Bild sein
      if (nextMediaType != 'photo' && nextMediaType != 'image') {
        break;
      }
      
      // Muss vom gleichen Absender sein
      if (nextFromId != currentFromId) {
        break;
      }
      
      // Muss innerhalb von 1 Sekunde sein
      final timeDiff = (currentTimestamp.millisecondsSinceEpoch - 
                        nextTimestamp.millisecondsSinceEpoch).abs();
      if (timeDiff > 1000) { // 1 Sekunde
        break;
      }
      
      if (nextMediaUrl != null && nextMediaUrl.isNotEmpty) {
        albumUrls.add(_correctMediaUrl(nextMediaUrl));
      }
    }
    
    // Prüfe auch die vorherigen 10 Nachrichten
    for (int i = currentIndex - 1; i >= 0 && i >= currentIndex - 10; i--) {
      final prevDoc = docs[i];
      final prevData = prevDoc.data() as Map<String, dynamic>;
      final prevMediaType = prevData['mediaType'] ?? '';
      final prevTimestamp = _getTimestamp(prevData);
      final prevFromId = prevData['from_id']?.toString() ?? '';
      final prevMediaUrl = _getMediaUrl(prevData);
      
      // Muss ein Bild sein
      if (prevMediaType != 'photo' && prevMediaType != 'image') {
        break;
      }
      
      // Muss vom gleichen Absender sein
      if (prevFromId != currentFromId) {
        break;
      }
      
      // Muss innerhalb von 1 Sekunde sein
      final timeDiff = (currentTimestamp.millisecondsSinceEpoch - 
                        prevTimestamp.millisecondsSinceEpoch).abs();
      if (timeDiff > 1000) { // 1 Sekunde
        break;
      }
      
      if (prevMediaUrl != null && prevMediaUrl.isNotEmpty) {
        albumUrls.insert(0, _correctMediaUrl(prevMediaUrl)); // Am Anfang einfügen
      }
    }
    
    // Gib nur zurück wenn es tatsächlich ein Album ist (>1 Bild)
    return albumUrls.length > 1 ? albumUrls : [];
  }
}
