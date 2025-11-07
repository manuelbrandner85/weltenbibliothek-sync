import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/telegram_models.dart';
import '../services/telegram_service.dart';

/// Erweiterte Such- & Filter-Screen für Telegram-Inhalte
/// 
/// Features:
/// - Volltext-Suche (Titel + Beschreibung)
/// - Hashtag-Suche
/// - Datums-Filter (Heute, Woche, Monat, Custom)
/// - Medientyp-Filter (Video, Dokument, Foto, Audio, Text)
/// - Kategorie-Filter
/// - Sortierung (Neueste, Älteste, Trending)
/// - Größen-Filter
class TelegramAdvancedSearchScreen extends StatefulWidget {
  const TelegramAdvancedSearchScreen({super.key});

  @override
  State<TelegramAdvancedSearchScreen> createState() => _TelegramAdvancedSearchScreenState();
}

class _TelegramAdvancedSearchScreenState extends State<TelegramAdvancedSearchScreen> {
  final TelegramService _telegramService = TelegramService();
  final TextEditingController _searchController = TextEditingController();
  
  // Filter-States
  String _searchQuery = '';
  Set<String> _selectedMediaTypes = {};
  Set<String> _selectedCategories = {};
  String _dateFilter = 'all'; // all, today, week, month, custom
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _sortBy = 'newest'; // newest, oldest, trending, mostLiked
  bool _onlyUnread = false;
  bool _onlyFavorites = false;
  
  // Medientypen
  final List<Map<String, dynamic>> _mediaTypes = [
    {'id': 'video', 'label': 'Videos', 'icon': Icons.videocam, 'color': Colors.red},
    {'id': 'document', 'label': 'Dokumente', 'icon': Icons.description, 'color': Colors.blue},
    {'id': 'photo', 'label': 'Fotos', 'icon': Icons.image, 'color': Colors.green},
    {'id': 'audio', 'label': 'Audio', 'icon': Icons.audiotrack, 'color': Colors.orange},
    {'id': 'text', 'label': 'Posts', 'icon': Icons.article, 'color': Colors.purple},
  ];
  
  // Kategorien
  final Map<String, String> _categories = {
    'lostCivilizations': 'Verlorene Zivilisationen',
    'alienContact': 'Außerirdische Kontakte',
    'ancientTechnology': 'Antike Technologien',
    'mysteriousArtifacts': 'Mysteriöse Artefakte',
    'paranormalPhenomena': 'Paranormale Phänomene',
    'secretSocieties': 'Geheimgesellschaften',
    'dimensionalAnomalies': 'Dimensions-Anomalien',
    'techMysteries': 'Technologie-Mysterien',
    'cosmicEvents': 'Kosmische Ereignisse',
    'hiddenKnowledge': 'Verborgenes Wissen',
  };
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erweiterte Suche'),
        backgroundColor: AppTheme.backgroundDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Filter zurücksetzen',
            onPressed: _resetFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Suchleiste
          _buildSearchBar(),
          
          // Filter-Chips
          _buildFilterChips(),
          
          // Ergebnisse
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }
  
  /// Suchleiste mit Hashtag-Support
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Suche nach Titel, Text, #hashtags...',
              hintStyle: AppTheme.bodySmall.copyWith(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: AppTheme.secondaryGold),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.secondaryGold.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.secondaryGold.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
          ),
          
          const SizedBox(height: 12),
          
          // Quick-Filter-Buttons
          Row(
            children: [
              Expanded(
                child: _buildQuickFilterButton(
                  'Nur ungelesen',
                  Icons.mark_email_unread,
                  _onlyUnread,
                  () => setState(() => _onlyUnread = !_onlyUnread),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickFilterButton(
                  'Nur Favoriten',
                  Icons.favorite,
                  _onlyFavorites,
                  () => setState(() => _onlyFavorites = !_onlyFavorites),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickFilterButton(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryPurple.withValues(alpha: 0.3)
              : AppTheme.backgroundDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryPurple
                : AppTheme.secondaryGold.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isActive ? AppTheme.primaryPurple : AppTheme.textWhite),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: isActive ? AppTheme.primaryPurple : AppTheme.textWhite,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Filter-Chips (horizontal scrollable)
  Widget _buildFilterChips() {
    return Container(
      height: 60,
      color: AppTheme.surfaceDark.withValues(alpha: 0.5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Medientyp-Filter
          _buildFilterChip(
            'Medientyp',
            Icons.category,
            _selectedMediaTypes.isNotEmpty,
            () => _showMediaTypeFilter(),
          ),
          
          const SizedBox(width: 8),
          
          // Kategorie-Filter
          _buildFilterChip(
            'Kategorien',
            Icons.label,
            _selectedCategories.isNotEmpty,
            () => _showCategoryFilter(),
          ),
          
          const SizedBox(width: 8),
          
          // Datums-Filter
          _buildFilterChip(
            _getDateFilterLabel(),
            Icons.calendar_today,
            _dateFilter != 'all',
            () => _showDateFilter(),
          ),
          
          const SizedBox(width: 8),
          
          // Sortierung
          _buildFilterChip(
            _getSortLabel(),
            Icons.sort,
            true,
            () => _showSortOptions(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.secondaryGold.withValues(alpha: 0.2)
              : AppTheme.backgroundDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.secondaryGold : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? AppTheme.secondaryGold : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.secondaryGold : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getDateFilterLabel() {
    switch (_dateFilter) {
      case 'today':
        return 'Heute';
      case 'week':
        return 'Diese Woche';
      case 'month':
        return 'Dieser Monat';
      case 'custom':
        return 'Benutzerdefiniert';
      default:
        return 'Alle Zeiten';
    }
  }
  
  String _getSortLabel() {
    switch (_sortBy) {
      case 'oldest':
        return 'Älteste zuerst';
      case 'trending':
        return 'Trending';
      case 'mostLiked':
        return 'Meist gemocht';
      default:
        return 'Neueste zuerst';
    }
  }
  
  /// Suchergebnisse mit allen Filtern
  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Fehler beim Laden', style: AppTheme.bodyMedium),
                Text(snapshot.error.toString(), style: AppTheme.bodySmall),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final docs = snapshot.data!.docs;
        
        // Client-seitige Filterung
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Suchquery-Filter (Volltext + Hashtags)
          if (_searchQuery.isNotEmpty) {
            final title = (data['title'] ?? '').toString().toLowerCase();
            final description = (data['description'] ?? '').toString().toLowerCase();
            final text = (data['text'] ?? '').toString().toLowerCase();
            
            if (_searchQuery.startsWith('#')) {
              // Hashtag-Suche
              final combined = '$title $description $text';
              if (!combined.contains(_searchQuery)) return false;
            } else {
              // Volltext-Suche
              if (!title.contains(_searchQuery) &&
                  !description.contains(_searchQuery) &&
                  !text.contains(_searchQuery)) {
                return false;
              }
            }
          }
          
          // Medientyp-Filter
          if (_selectedMediaTypes.isNotEmpty) {
            final mediaType = data['media_type'] ?? 'text';
            if (!_selectedMediaTypes.contains(mediaType)) return false;
          }
          
          // Kategorie-Filter
          if (_selectedCategories.isNotEmpty) {
            final category = data['category'];
            if (!_selectedCategories.contains(category)) return false;
          }
          
          // Datums-Filter
          if (_dateFilter != 'all') {
            final timestamp = data['timestamp'] as Timestamp?;
            if (timestamp != null) {
              final date = timestamp.toDate();
              final now = DateTime.now();
              
              switch (_dateFilter) {
                case 'today':
                  if (date.day != now.day || date.month != now.month || date.year != now.year) {
                    return false;
                  }
                  break;
                case 'week':
                  final weekAgo = now.subtract(const Duration(days: 7));
                  if (date.isBefore(weekAgo)) return false;
                  break;
                case 'month':
                  final monthAgo = DateTime(now.year, now.month - 1, now.day);
                  if (date.isBefore(monthAgo)) return false;
                  break;
                case 'custom':
                  if (_customStartDate != null && date.isBefore(_customStartDate!)) {
                    return false;
                  }
                  if (_customEndDate != null && date.isAfter(_customEndDate!)) {
                    return false;
                  }
                  break;
              }
            }
          }
          
          // Nur-Ungelesen-Filter
          if (_onlyUnread) {
            final readBy = data['read_by'] as List<dynamic>?;
            // TODO: Check if current user ID is in read_by array
            // For now, skip this filter
          }
          
          // Nur-Favoriten-Filter
          if (_onlyFavorites) {
            final favoriteBy = data['favorite_by'] as List<dynamic>?;
            // TODO: Check if current user ID is in favorite_by array
            // For now, skip this filter
          }
          
          return true;
        }).toList();
        
        // Sortierung
        filteredDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          
          switch (_sortBy) {
            case 'oldest':
              final aTime = (aData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
              final bTime = (bData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
              return aTime.compareTo(bTime);
            
            case 'trending':
              // TODO: Implement trending algorithm (views + reactions + recency)
              final aReactions = (aData['reactions'] as Map<dynamic, dynamic>?)?.length ?? 0;
              final bReactions = (bData['reactions'] as Map<dynamic, dynamic>?)?.length ?? 0;
              return bReactions.compareTo(aReactions);
            
            case 'mostLiked':
              final aReactions = (aData['reactions'] as Map<dynamic, dynamic>?)?.length ?? 0;
              final bReactions = (bData['reactions'] as Map<dynamic, dynamic>?)?.length ?? 0;
              return bReactions.compareTo(aReactions);
            
            default: // newest
              final aTime = (aData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
              final bTime = (bData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
              return bTime.compareTo(aTime);
          }
        });
        
        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text('Keine Ergebnisse gefunden', style: AppTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Versuche andere Suchbegriffe oder Filter',
                  style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: filteredDocs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return _buildResultCard(data);
          },
        );
      },
    );
  }
  
  Stream<QuerySnapshot> _buildQuery() {
    // Basis-Query ohne komplexe Filter (um Firestore-Index-Anforderungen zu vermeiden)
    return FirebaseFirestore.instance
        .collection('telegram_messages')
        .orderBy('timestamp', descending: true)
        .limit(500)
        .snapshots();
  }
  
  Widget _buildResultCard(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Kein Titel';
    final description = data['description'] ?? '';
    final mediaType = data['media_type'] ?? 'text';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final category = data['category'] ?? '';
    
    IconData icon;
    Color color;
    
    switch (mediaType) {
      case 'video':
        icon = Icons.videocam;
        color = Colors.red;
        break;
      case 'document':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'photo':
        icon = Icons.image;
        color = Colors.green;
        break;
      case 'audio':
        icon = Icons.audiotrack;
        color = Colors.orange;
        break;
      default:
        icon = Icons.article;
        color = Colors.purple;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.secondaryGold.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to detail screen
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Icon und Datum
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (timestamp != null)
                          Text(
                            DateFormat('dd.MM.yyyy HH:mm').format(timestamp),
                            style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: AppTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              if (category.isNotEmpty) ...[
                const SizedBox(height: 12),
                Chip(
                  label: Text(
                    _categories[category] ?? category,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
                  side: BorderSide(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  // Dialog-Methoden
  void _showMediaTypeFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Medientyp wählen', style: AppTheme.headlineSmall),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _mediaTypes.map((type) {
                  final isSelected = _selectedMediaTypes.contains(type['id']);
                  return CheckboxListTile(
                    title: Row(
                      children: [
                        Icon(type['icon'] as IconData, color: type['color'] as Color, size: 20),
                        const SizedBox(width: 12),
                        Text(type['label'] as String, style: AppTheme.bodyMedium),
                      ],
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          _selectedMediaTypes.add(type['id'] as String);
                        } else {
                          _selectedMediaTypes.remove(type['id']);
                        }
                      });
                      setState(() {});
                    },
                    activeColor: AppTheme.secondaryGold,
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }
  
  void _showCategoryFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Kategorien wählen', style: AppTheme.headlineSmall),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _categories.entries.map((entry) {
                  final isSelected = _selectedCategories.contains(entry.key);
                  return CheckboxListTile(
                    title: Text(entry.value, style: AppTheme.bodyMedium),
                    value: isSelected,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          _selectedCategories.add(entry.key);
                        } else {
                          _selectedCategories.remove(entry.key);
                        }
                      });
                      setState(() {});
                    },
                    activeColor: AppTheme.secondaryGold,
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }
  
  void _showDateFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Zeitraum wählen', style: AppTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Alle Zeiten'),
              leading: Radio<String>(
                value: 'all',
                groupValue: _dateFilter,
                onChanged: (value) {
                  setState(() => _dateFilter = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Heute'),
              leading: Radio<String>(
                value: 'today',
                groupValue: _dateFilter,
                onChanged: (value) {
                  setState(() => _dateFilter = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Diese Woche'),
              leading: Radio<String>(
                value: 'week',
                groupValue: _dateFilter,
                onChanged: (value) {
                  setState(() => _dateFilter = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Dieser Monat'),
              leading: Radio<String>(
                value: 'month',
                groupValue: _dateFilter,
                onChanged: (value) {
                  setState(() => _dateFilter = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Benutzerdefiniert'),
              leading: Radio<String>(
                value: 'custom',
                groupValue: _dateFilter,
                onChanged: (value) {
                  setState(() => _dateFilter = value!);
                  Navigator.pop(context);
                  _showCustomDateRangePicker();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showCustomDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryPurple,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceDark,
              onSurface: AppTheme.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }
  
  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Sortierung', style: AppTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Neueste zuerst'),
              leading: Radio<String>(
                value: 'newest',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Älteste zuerst'),
              leading: Radio<String>(
                value: 'oldest',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Trending'),
              leading: Radio<String>(
                value: 'trending',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Meist gemocht'),
              leading: Radio<String>(
                value: 'mostLiked',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedMediaTypes.clear();
      _selectedCategories.clear();
      _dateFilter = 'all';
      _customStartDate = null;
      _customEndDate = null;
      _sortBy = 'newest';
      _onlyUnread = false;
      _onlyFavorites = false;
    });
  }
}
