import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/historical_event.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favorites = {};
  List<HistoricalEvent> _allEvents = [];
  List<HistoricalEvent> _filteredEvents = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLibrary();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Lade Events aus Timeline (in echter App: Firebase)
    _allEvents = _generateLibraryEvents();
    _filteredEvents = _allEvents;
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<HistoricalEvent> _generateLibraryEvents() {
    // Füge mehr Events hinzu für die Bibliothek
    return [
      HistoricalEvent(
        id: '10',
        title: 'Philadelphia Experiment 1943',
        description: 'USS Eldridge verschwand angeblich durch Teleportation-Experimente der US Navy. Crew-Mitglieder sollen in Wände verschmolzen sein.',
        date: DateTime(1943, 10, 28),
        category: EventCategory.techMysteries,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.scientific],
        sources: ['Navy Records', 'Zeitzeugen', 'Declassified Files'],
        trustLevel: 2,
      ),
      HistoricalEvent(
        id: '11',
        title: 'Nazca-Linien: Landebahnen für Götter?',
        description: 'Gigantische Geoglyphen in Peru, nur aus der Luft erkennbar. Ihre Präzision und Zweck bleiben rätselhaft.',
        date: DateTime(-500, 1, 1),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.alternative, PerspectiveType.spiritual],
        sources: ['Archäologische Studien', 'Ancient Astronaut Theory'],
        trustLevel: 3,
        latitude: -14.7389,
        longitude: -75.1300,
        locationName: 'Nazca, Peru',
      ),
      HistoricalEvent(
        id: '12',
        title: 'Montauk Project: Zeitreise-Experimente',
        description: 'Geheime Militärbasis in Long Island. Berichte über Bewusstseinskontrolle, Zeitreisen und interdimensionale Portale.',
        date: DateTime(1971, 1, 1),
        category: EventCategory.dimensionalAnomalies,
        perspectives: [PerspectiveType.conspiracy],
        sources: ['Whistleblower Aussagen', 'Preston Nichols Bücher'],
        trustLevel: 1,
        latitude: 41.0482,
        longitude: -71.9542,
        locationName: 'Montauk, New York',
      ),
      HistoricalEvent(
        id: '13',
        title: 'Voynich-Manuskript',
        description: 'Mysteriöses Buch in unbekannter Schrift und Sprache. Enthält botanische und astronomische Zeichnungen, die keiner bekannten Pflanze entsprechen.',
        date: DateTime(1404, 1, 1),
        category: EventCategory.forbiddenKnowledge,
        perspectives: [PerspectiveType.alternative, PerspectiveType.scientific],
        sources: ['Yale University Bibliothek', 'Kryptographie-Studien'],
        trustLevel: 4,
      ),
      HistoricalEvent(
        id: '14',
        title: 'Phoenix Lights 1997',
        description: 'Massensichtung eines V-förmigen UFOs über Arizona. Tausende Zeugen, inklusive Gouverneur Fife Symington.',
        date: DateTime(1997, 3, 13),
        category: EventCategory.ufoFleets,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.mainstream],
        sources: ['FAA Records', 'Zeugenaussagen', 'Video-Aufnahmen'],
        trustLevel: 5,
        latitude: 33.4484,
        longitude: -112.0740,
        locationName: 'Phoenix, Arizona',
      ),
      HistoricalEvent(
        id: '15',
        title: 'HAARP: Wetterkontrolle oder Erdbeben-Waffe?',
        description: 'High Frequency Active Auroral Research Program in Alaska. Offiziell Ionosphären-Forschung, inoffiziell Gedankenkontrolle und Wettermanipulation.',
        date: DateTime(1993, 1, 1),
        category: EventCategory.globalConspiracies,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.scientific],
        sources: ['US Air Force Dokumente', 'Wissenschaftliche Analysen'],
        trustLevel: 3,
        latitude: 62.3900,
        longitude: -145.1500,
        locationName: 'Gakona, Alaska',
      ),
    ];
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      
      if (_searchQuery.isEmpty) {
        _filteredEvents = _allEvents;
      } else {
        _filteredEvents = _allEvents.where((event) {
          return event.title.toLowerCase().contains(_searchQuery) ||
                 event.description.toLowerCase().contains(_searchQuery) ||
                 event.categoryName.toLowerCase().contains(_searchQuery) ||
                 (event.locationName?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();
      }
    });
  }

  void _toggleFavorite(String eventId) {
    setState(() {
      if (_favorites.contains(eventId)) {
        _favorites.remove(eventId);
      } else {
        _favorites.add(eventId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '📚 Bibliothek',
                    style: theme.textTheme.displayMedium,
                  ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  // Suchfeld
                  TextField(
                    controller: _searchController,
                    onChanged: _performSearch,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: InputDecoration(
                      hintText: 'Durchsuche verborgenes Wissen...',
                      hintStyle: TextStyle(
                        color: AppTheme.textWhite.withValues(alpha: 0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppTheme.secondaryGold,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppTheme.textWhite.withValues(alpha: 0.7),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.secondaryGold,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Statistiken
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        '📖',
                        'Einträge',
                        '${_allEvents.length}',
                      ),
                      _buildStatCard(
                        '⭐',
                        'Favoriten',
                        '${_favorites.length}',
                      ),
                      _buildStatCard(
                        '🔍',
                        'Gefunden',
                        '${_filteredEvents.length}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.secondaryGold,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Lade Bibliothek...',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : _filteredEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: AppTheme.textWhite.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Keine Einträge gefunden',
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Versuche andere Suchbegriffe',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filteredEvents.length,
                          itemBuilder: (context, index) {
                            return _buildEventGridCard(_filteredEvents[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textWhite.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventGridCard(HistoricalEvent event) {
    final isFavorite = _favorites.contains(event.id);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Detail-Ansicht öffnen
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.surfaceDark,
                _getCategoryColor(event.category).withValues(alpha: 0.2),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategorie Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(event.category),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.categoryEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Titel
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Beschreibung
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textWhite.withValues(alpha: 0.7),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Trust Level
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < event.trustLevel ? Icons.star : Icons.star_border,
                          size: 12,
                          color: AppTheme.secondaryGold,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              
              // Favorite Button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? AppTheme.errorRed : AppTheme.textWhite,
                    size: 20,
                  ),
                  onPressed: () => _toggleFavorite(event.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }

  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.lostCivilizations:
        return AppTheme.lostCivilizations;
      case EventCategory.alienContact:
        return AppTheme.alienContact;
      case EventCategory.secretSocieties:
        return AppTheme.secretSocieties;
      case EventCategory.techMysteries:
        return AppTheme.techMysteries;
      case EventCategory.dimensionalAnomalies:
        return AppTheme.dimensionalAnomalies;
      case EventCategory.occultEvents:
        return AppTheme.occultEvents;
      case EventCategory.forbiddenKnowledge:
        return AppTheme.forbiddenKnowledge;
      case EventCategory.ufoFleets:
        return AppTheme.ufoFleets;
      case EventCategory.energyPhenomena:
        return AppTheme.energyPhenomena;
      case EventCategory.globalConspiracies:
        return AppTheme.globalConspiracies;
    }
  }
}
