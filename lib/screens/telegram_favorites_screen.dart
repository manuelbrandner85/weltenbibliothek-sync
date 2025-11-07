import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/telegram_service.dart';
import '../services/auth_service.dart';
import '../widgets/enhanced_telegram_message_card.dart';

/// Telegram Favoriten Screen mit V4 Extended Features
/// 
/// Features:
/// - Favoriten anzeigen (favorite_by Array)
/// - Gepinnte Nachrichten anzeigen (is_pinned)
/// - Filter nach Kategorien
/// - Sortierung nach Datum/Priorität
/// - Suche in Favoriten
class TelegramFavoritesScreen extends StatefulWidget {
  const TelegramFavoritesScreen({Key? key}) : super(key: key);

  @override
  State<TelegramFavoritesScreen> createState() => _TelegramFavoritesScreenState();
}

class _TelegramFavoritesScreenState extends State<TelegramFavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'Alle';
  SortOrder _sortOrder = SortOrder.dateDescending;

  final List<String> _categories = [
    'Alle',
    'Verlorene Zivilisationen',
    'Außerirdischer Kontakt',
    'Verschwörungstheorien',
    'Antike Technologie',
    'Paranormales',
    'Esoterik',
    'Geheimgesellschaften',
    'Prophezeiungen',
    'Verborgenes Wissen',
    'Manipulation',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final telegramService = Provider.of<TelegramService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid ?? 'anonymous';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Favoriten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Suchen',
          ),
          PopupMenuButton<SortOrder>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sortieren',
            onSelected: (order) {
              setState(() {
                _sortOrder = order;
              });
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: SortOrder.dateDescending,
                checked: _sortOrder == SortOrder.dateDescending,
                child: const Text('Neueste zuerst'),
              ),
              CheckedPopupMenuItem(
                value: SortOrder.dateAscending,
                checked: _sortOrder == SortOrder.dateAscending,
                child: const Text('Älteste zuerst'),
              ),
              CheckedPopupMenuItem(
                value: SortOrder.readCount,
                checked: _sortOrder == SortOrder.readCount,
                child: const Text('Meist gelesen'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.star), text: 'Favoriten'),
            Tab(icon: Icon(Icons.push_pin), text: 'Gepinnt'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Category Filter
          _buildCategoryFilter(),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Favoriten Tab
                _buildFavoritesView(telegramService, currentUserId),
                
                // Gepinnte Tab
                _buildPinnedView(telegramService, currentUserId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Category Filter Chips
  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : 'Alle';
                });
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          );
        },
      ),
    );
  }

  /// Favoriten View mit Firestore Query
  Widget _buildFavoritesView(TelegramService telegramService, String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildFavoritesQuery(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Fehler: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_border,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine Favoriten',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Markiere Nachrichten als Favorit,\num sie hier zu sehen',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        var messages = snapshot.data!.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();

        // Filter by category
        if (_selectedCategory != 'Alle') {
          messages = messages.where((msg) {
            final topic = msg['topic'] as String? ?? '';
            return topic == _selectedCategory;
          }).toList();
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          messages = messages.where((msg) {
            final text = msg['text_clean']?.toString().toLowerCase() ?? '';
            return text.contains(_searchQuery.toLowerCase());
          }).toList();
        }

        // Sort messages
        _sortMessages(messages);

        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return EnhancedTelegramMessageCard(
              message: messages[index],
              telegramService: telegramService,
              currentUserId: currentUserId,
            );
          },
        );
      },
    );
  }

  /// Gepinnte View mit Firestore Query
  Widget _buildPinnedView(TelegramService telegramService, String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildPinnedQuery(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Fehler: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.push_pin_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine gepinnten Nachrichten',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Admins können wichtige Nachrichten\nanpinnen',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        var messages = snapshot.data!.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();

        // Filter by category
        if (_selectedCategory != 'Alle') {
          messages = messages.where((msg) {
            final topic = msg['topic'] as String? ?? '';
            return topic == _selectedCategory;
          }).toList();
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          messages = messages.where((msg) {
            final text = msg['text_clean']?.toString().toLowerCase() ?? '';
            return text.contains(_searchQuery.toLowerCase());
          }).toList();
        }

        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return EnhancedTelegramMessageCard(
              message: messages[index],
              telegramService: telegramService,
              currentUserId: currentUserId,
            );
          },
        );
      },
    );
  }

  /// Build Firestore Query für Favoriten
  Stream<QuerySnapshot> _buildFavoritesQuery(String currentUserId) {
    Query query = FirebaseFirestore.instance
        .collectionGroup('telegram_messages') // Search across all collections
        .where('favorite_by', arrayContains: currentUserId);

    // Add ordering based on sort order
    switch (_sortOrder) {
      case SortOrder.dateDescending:
        query = query.orderBy('timestamp', descending: true);
        break;
      case SortOrder.dateAscending:
        query = query.orderBy('timestamp', descending: false);
        break;
      case SortOrder.readCount:
        // Note: Firestore doesn't support array length sorting
        // We'll sort in memory after fetching
        query = query.orderBy('timestamp', descending: true);
        break;
    }

    return query.limit(100).snapshots();
  }

  /// Build Firestore Query für Gepinnte Nachrichten
  Stream<QuerySnapshot> _buildPinnedQuery() {
    return FirebaseFirestore.instance
        .collectionGroup('telegram_messages')
        .where('is_pinned', isEqualTo: true)
        .orderBy('pinned_at', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Sort messages in memory
  void _sortMessages(List<Map<String, dynamic>> messages) {
    switch (_sortOrder) {
      case SortOrder.dateDescending:
        messages.sort((a, b) {
          final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
        break;
      case SortOrder.dateAscending:
        messages.sort((a, b) {
          final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return aTime.compareTo(bTime);
        });
        break;
      case SortOrder.readCount:
        messages.sort((a, b) {
          final aCount = (a['read_by'] as List<dynamic>?)?.length ?? 0;
          final bCount = (b['read_by'] as List<dynamic>?)?.length ?? 0;
          return bCount.compareTo(aCount);
        });
        break;
    }
  }

  /// Show search dialog
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _searchQuery);
        
        return AlertDialog(
          title: const Text('Suchen'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Suchbegriff eingeben...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
                Navigator.pop(context);
              },
              child: const Text('Löschen'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = controller.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Suchen'),
            ),
          ],
        );
      },
    );
  }
}

/// Sort Order Enum
enum SortOrder {
  dateDescending,
  dateAscending,
  readCount,
}
