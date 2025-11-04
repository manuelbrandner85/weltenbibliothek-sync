import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../data/massive_events_data.dart';
import '../models/historical_event.dart';
import '../services/search_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<HistoricalEvent> _allEvents = [];
  List<HistoricalEvent> _searchResults = [];
  bool _isSearching = false;
  EventCategory? _selectedCategory;
  SortCriteria _sortBy = SortCriteria.dateAscending;

  @override
  void initState() {
    super.initState();
    _allEvents = MassiveEventsData.getAllEvents();
    _searchResults = _allEvents;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() {
      _isSearching = true;
    });

    final results = SearchService.advancedSearch(
      events: _allEvents,
      query: _searchController.text,
      category: _selectedCategory,
      sortBy: _sortBy,
    );

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('🔍 Suche'),
        backgroundColor: AppTheme.surfaceDark,
      ),
      body: Column(
        children: [
          // Suchleiste
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceDark,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: AppTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Suche nach Events, Orten, Quellen...',
                    hintStyle: AppTheme.bodyLarge.copyWith(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryPurple),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),
                
                // Filter-Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Kategorie-Filter
                      ChoiceChip(
                        label: Text(_selectedCategory == null ? 'Alle Kategorien' : _getCategoryName(_selectedCategory!)),
                        selected: _selectedCategory != null,
                        onSelected: (_) {
                          _showCategoryFilter();
                        },
                        backgroundColor: AppTheme.backgroundDark,
                        selectedColor: AppTheme.primaryPurple.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 8),
                      
                      // Sortierung
                      ChoiceChip(
                        label: Text(_getSortName(_sortBy)),
                        selected: true,
                        onSelected: (_) {
                          _showSortOptions();
                        },
                        backgroundColor: AppTheme.backgroundDark,
                        selectedColor: AppTheme.accentGold.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ergebnisse
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Keine Ergebnisse gefunden',
                              style: AppTheme.headlineSmall.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final event = _searchResults[index];
                          return _buildEventCard(event, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(HistoricalEvent event, int index) {
    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _getCategoryIcon(event.category),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppTheme.accentGold),
                  const SizedBox(width: 4),
                  Text(
                    _formatYear(event.date.year),
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.accentGold),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.locationName ?? 'Unbekannt',
                      style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.description.split('\n').first.replaceAll(RegExp(r'[🔮👁️📋🔍🏛️👽⚡🌊💥🛸✨]'), '').trim(),
                style: AppTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: -0.1, end: 0);
  }

  void _showEventDetails(HistoricalEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _getCategoryIcon(event.category),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.title,
                      style: AppTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: AppTheme.accentGold),
                  const SizedBox(width: 8),
                  Text(_formatYear(event.date.year), style: AppTheme.bodyLarge),
                  const SizedBox(width: 24),
                  const Icon(Icons.location_on, color: AppTheme.primaryPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(event.locationName ?? 'Unbekannt', style: AppTheme.bodyLarge),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(event.description, style: AppTheme.bodyMedium),
              const SizedBox(height: 16),
              if (event.sources.isNotEmpty) ...[
                Text('📚 Quellen:', style: AppTheme.headlineSmall),
                const SizedBox(height: 8),
                ...event.sources.map((source) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $source', style: AppTheme.bodySmall),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategorie wählen', style: AppTheme.headlineMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('🌍', style: TextStyle(fontSize: 24)),
              title: const Text('Alle Kategorien'),
              selected: _selectedCategory == null,
              onTap: () {
                setState(() => _selectedCategory = null);
                _performSearch();
                Navigator.pop(context);
              },
            ),
            ...EventCategory.values.map((category) => ListTile(
                  leading: Text(_getCategoryIcon(category), style: const TextStyle(fontSize: 24)),
                  title: Text(_getCategoryName(category)),
                  selected: _selectedCategory == category,
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    _performSearch();
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sortierung', style: AppTheme.headlineMedium),
            const SizedBox(height: 16),
            ...SortCriteria.values.map((criteria) => ListTile(
                  leading: const Icon(Icons.sort),
                  title: Text(_getSortName(criteria)),
                  selected: _sortBy == criteria,
                  onTap: () {
                    setState(() => _sortBy = criteria);
                    _performSearch();
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  String _formatYear(int year) {
    if (year < 0) return '${-year} v.Chr.';
    return '$year n.Chr.';
  }

  String _getCategoryIcon(EventCategory category) {
    switch (category) {
      case EventCategory.lostCivilizations: return '🏛️';
      case EventCategory.alienContact: return '👽';
      case EventCategory.secretSocieties: return '🔺';
      case EventCategory.techMysteries: return '⚙️';
      case EventCategory.dimensionalAnomalies: return '🌀';
      case EventCategory.occultEvents: return '🐐';
      case EventCategory.forbiddenKnowledge: return '📖';
      case EventCategory.ufoFleets: return '🛸';
      case EventCategory.energyPhenomena: return '⚡';
      case EventCategory.globalConspiracies: return '👁️';
    }
  }

  String _getCategoryName(EventCategory category) {
    switch (category) {
      case EventCategory.lostCivilizations: return 'Versunkene Zivilisationen';
      case EventCategory.alienContact: return 'Alien-Kontakte';
      case EventCategory.secretSocieties: return 'Geheimbünde';
      case EventCategory.techMysteries: return 'Tech-Mysterien';
      case EventCategory.dimensionalAnomalies: return 'Dimensionale Anomalien';
      case EventCategory.occultEvents: return 'Okkulte Ereignisse';
      case EventCategory.forbiddenKnowledge: return 'Verbotenes Wissen';
      case EventCategory.ufoFleets: return 'UFO-Flotten';
      case EventCategory.energyPhenomena: return 'Energie-Phänomene';
      case EventCategory.globalConspiracies: return 'Globale Verschwörungen';
    }
  }

  String _getSortName(SortCriteria criteria) {
    switch (criteria) {
      case SortCriteria.dateAscending: return '📅 Datum (Alt → Neu)';
      case SortCriteria.dateDescending: return '📅 Datum (Neu → Alt)';
      case SortCriteria.nameAscending: return '🔤 Name (A → Z)';
      case SortCriteria.nameDescending: return '🔤 Name (Z → A)';
      case SortCriteria.trustLevelAscending: return '⭐ Vertrauen (Niedrig → Hoch)';
      case SortCriteria.trustLevelDescending: return '⭐ Vertrauen (Hoch → Niedrig)';
    }
  }
}
