import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/historical_event.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  EventCategory? _selectedCategory;
  PerspectiveType? _selectedPerspective;
  final List<HistoricalEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    // Simuliere Laden von Beispiel-Events
    await Future.delayed(const Duration(milliseconds: 800));
    
    final sampleEvents = _generateSampleEvents();
    
    if (mounted) {
      setState(() {
        _events.addAll(sampleEvents);
        _isLoading = false;
      });
    }
  }

  List<HistoricalEvent> _generateSampleEvents() {
    return [
      HistoricalEvent(
        id: '1',
        title: 'Roswell UFO-Vorfall',
        description: 'Ein mysteriöser Absturz nahe Roswell, New Mexico. Die offizielle Version spricht von einem Wetterballon, doch Augenzeugen berichten von außerirdischen Artefakten.',
        date: DateTime(1947, 7, 8),
        category: EventCategory.alienContact,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.alternative],
        sources: [
          'US Air Force Report 1947',
          'Augenzeugenberichte',
          'Declassified Documents'
        ],
        trustLevel: 3,
        latitude: 33.3942,
        longitude: -104.5230,
        locationName: 'Roswell, New Mexico',
      ),
      HistoricalEvent(
        id: '2',
        title: 'Atlantis - Die versunkene Zivilisation',
        description: 'Platons Beschreibung einer hochentwickelten Inselzivilisation, die vor 11.600 Jahren im Meer versank. Geologische Anomalien im Atlantik könnten auf ihre Existenz hinweisen.',
        date: DateTime(-9600, 1, 1),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.alternative, PerspectiveType.spiritual],
        sources: [
          'Platons Timaios & Kritias',
          'Geologische Studien',
          'Unterwasser-Archaeologie'
        ],
        trustLevel: 2,
        latitude: 31.0,
        longitude: -24.0,
        locationName: 'Atlantischer Ozean',
      ),
      HistoricalEvent(
        id: '3',
        title: 'Tunguska-Explosion',
        description: 'Eine gewaltige Explosion in Sibirien mit der Kraft von 1000 Hiroshima-Bomben. Kein Krater gefunden. War es ein Meteor, eine außerirdische Waffe oder ein Tesla-Experiment?',
        date: DateTime(1908, 6, 30),
        category: EventCategory.energyPhenomena,
        perspectives: [PerspectiveType.scientific, PerspectiveType.conspiracy],
        sources: [
          'Wissenschaftliche Expeditionen',
          'Augenzeugenberichte',
          'Seismische Daten'
        ],
        trustLevel: 4,
        latitude: 60.886,
        longitude: 101.894,
        locationName: 'Tunguska, Sibirien',
      ),
      HistoricalEvent(
        id: '4',
        title: 'Nürnberger Himmelsschlacht 1561',
        description: 'Massenhafte UFO-Sichtung über Nürnberg. Zeitgenössische Holzschnitte zeigen Kugeln, Kreuze und Zylinder am Himmel kämpfend. Hunderte Zeugen dokumentiert.',
        date: DateTime(1561, 4, 14),
        category: EventCategory.ufoFleets,
        perspectives: [PerspectiveType.alternative, PerspectiveType.conspiracy],
        sources: [
          'Hans Glaser Holzschnitt',
          'Stadtchroniken Nürnberg',
          'Historische Aufzeichnungen'
        ],
        trustLevel: 4,
        latitude: 49.4521,
        longitude: 11.0767,
        locationName: 'Nürnberg, Deutschland',
      ),
      HistoricalEvent(
        id: '5',
        title: 'MK-Ultra Mind Control Program',
        description: 'Geheimes CIA-Programm zur Bewusstseinskontrolle durch LSD, Hypnose und Folter. 1975 offiziell enthüllt durch den Church Committee Report.',
        date: DateTime(1953, 4, 13),
        category: EventCategory.globalConspiracies,
        perspectives: [PerspectiveType.mainstream, PerspectiveType.conspiracy],
        sources: [
          'Church Committee Report 1975',
          'CIA Declassified Documents',
          'Opferaussagen'
        ],
        trustLevel: 5,
        latitude: 38.9072,
        longitude: -77.0369,
        locationName: 'Washington D.C., USA',
      ),
      HistoricalEvent(
        id: '6',
        title: 'Pyramiden von Gizeh - Energiezentren',
        description: 'Die Great Pyramid zeigt mathematische Präzision, die moderne Technik herausfordert. Ihre Ausrichtung zu Orion und elektromagnetische Anomalien deuten auf fortgeschrittenes Wissen hin.',
        date: DateTime(-2560, 1, 1),
        category: EventCategory.techMysteries,
        perspectives: [PerspectiveType.alternative, PerspectiveType.spiritual],
        sources: [
          'Archäologische Studien',
          'Elektromagnetische Messungen',
          'Ancient Alien Theory'
        ],
        trustLevel: 3,
        latitude: 29.9792,
        longitude: 31.1342,
        locationName: 'Gizeh, Ägypten',
      ),
      HistoricalEvent(
        id: '7',
        title: 'Bermuda-Dreieck Anomalie',
        description: 'Seit Jahrhunderten verschwinden Schiffe und Flugzeuge spurlos. Kompass-Anomalien, Zeitverzerrungen und dimensionale Portale werden berichtet.',
        date: DateTime(1945, 12, 5),
        category: EventCategory.dimensionalAnomalies,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.scientific],
        sources: [
          'US Navy Records',
          'Küstenwache Berichte',
          'Wissenschaftliche Studien'
        ],
        trustLevel: 3,
        latitude: 25.0,
        longitude: -71.0,
        locationName: 'Bermuda-Dreieck, Atlantik',
      ),
      HistoricalEvent(
        id: '8',
        title: 'Aleister Crowley - Abyss Working',
        description: 'Der berühmte Okkultist führte 1909 ein Ritual durch, das ein dimensionales Portal öffnete. Berichte von Entitätskontakt und bleibenden Realitätsverzerrungen.',
        date: DateTime(1909, 11, 1),
        category: EventCategory.occultEvents,
        perspectives: [PerspectiveType.spiritual, PerspectiveType.alternative],
        sources: [
          'Crowleys Magisches Tagebuch',
          'Zeitzeugenberichte',
          'Golden Dawn Archive'
        ],
        trustLevel: 2,
        latitude: 36.1357,
        longitude: 5.3395,
        locationName: 'Algier, Algerien',
      ),
    ];
  }

  List<HistoricalEvent> get _filteredEvents {
    var filtered = _events;
    
    if (_selectedCategory != null) {
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }
    
    if (_selectedPerspective != null) {
      filtered = filtered.where((e) => e.perspectives.contains(_selectedPerspective)).toList();
    }
    
    // Sortiere nach Datum (neueste zuerst)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    
    return filtered;
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
                    '⏱️ Historische Timeline',
                    style: theme.textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  // Filter-Chips
                  _buildFilterChips(),
                ],
              ),
            ),
            
            // Timeline Content
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
                            'Lade verborgene Chroniken...',
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
                                'Keine Ereignisse gefunden',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredEvents.length,
                          itemBuilder: (context, index) {
                            return _buildEventCard(
                              _filteredEvents[index],
                              index,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip('Alle', null),
          const SizedBox(width: 8),
          ...EventCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCategoryChip(
                _getCategoryName(category),
                category,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, EventCategory? category) {
    final isSelected = _selectedCategory == category;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      backgroundColor: AppTheme.surfaceDark,
      selectedColor: AppTheme.primaryPurple,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.textWhite : AppTheme.textWhite.withValues(alpha: 0.7),
      ),
    );
  }

  String _getCategoryName(EventCategory category) {
    switch (category) {
      case EventCategory.lostCivilizations:
        return '🏛️ Zivilisationen';
      case EventCategory.alienContact:
        return '👽 Außerirdische';
      case EventCategory.secretSocieties:
        return '🔺 Geheimbünde';
      case EventCategory.techMysteries:
        return '📡 Tech-Mysterien';
      case EventCategory.dimensionalAnomalies:
        return '🌀 Anomalien';
      case EventCategory.occultEvents:
        return '🔮 Okkult';
      case EventCategory.forbiddenKnowledge:
        return '📜 Verboten';
      case EventCategory.ufoFleets:
        return '🛸 UFOs';
      case EventCategory.energyPhenomena:
        return '⚡ Energie';
      case EventCategory.globalConspiracies:
        return '🌍 Verschwörungen';
    }
  }

  Widget _buildEventCard(HistoricalEvent event, int index) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final yearFormat = event.date.year < 0 
        ? '${event.date.year.abs()} v.Chr.'
        : dateFormat.format(event.date);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surfaceDark,
                _getCategoryColor(event.category).withValues(alpha: 0.15),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Kategorie und Trust-Level
              Row(
                children: [
                  Text(
                    event.categoryEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.categoryName,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCategoryColor(event.category),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildTrustLevelIndicator(event.trustLevel),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Titel
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Datum und Ort
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppTheme.secondaryGold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    yearFormat,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textWhite.withValues(alpha: 0.7),
                    ),
                  ),
                  if (event.locationName != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppTheme.secondaryGold,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.locationName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textWhite.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Beschreibung
              Text(
                event.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textWhite.withValues(alpha: 0.9),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Perspektiven
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: event.perspectives.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getPerspectiveEmoji(p),
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 100 * index))
      .slideX(begin: -0.1, end: 0, delay: Duration(milliseconds: 100 * index));
  }

  Widget _buildTrustLevelIndicator(int level) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < level ? Icons.star : Icons.star_border,
          size: 14,
          color: AppTheme.secondaryGold,
        );
      }),
    );
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

  String _getPerspectiveEmoji(PerspectiveType type) {
    switch (type) {
      case PerspectiveType.mainstream:
        return '🏛️';
      case PerspectiveType.alternative:
        return '🔍';
      case PerspectiveType.conspiracy:
        return '🕵️';
      case PerspectiveType.spiritual:
        return '🧘';
      case PerspectiveType.scientific:
        return '🔬';
    }
  }

  void _showEventDetails(HistoricalEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEventDetailsSheet(event),
    );
  }

  Widget _buildEventDetailsSheet(HistoricalEvent event) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final yearFormat = event.date.year < 0 
        ? '${event.date.year.abs()} v.Chr.'
        : dateFormat.format(event.date);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textWhite.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategorie Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(event.category),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.categoryEmoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          event.categoryName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Titel
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryGold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Datum und Ort
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: AppTheme.secondaryGold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        yearFormat,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ],
                  ),
                  
                  if (event.locationName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: AppTheme.secondaryGold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.locationName!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Beschreibung
                  Text(
                    'Beschreibung',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryGold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textWhite.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Perspektiven
                  Text(
                    'Perspektiven',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryGold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: event.perspectives.map((p) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryPurple.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getPerspectiveEmoji(p),
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getPerspectiveName(p),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textWhite,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Trust Level
                  Text(
                    'Vertrauensstufe',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryGold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < event.trustLevel ? Icons.star : Icons.star_border,
                          size: 28,
                          color: AppTheme.secondaryGold,
                        );
                      }),
                      const SizedBox(width: 12),
                      Text(
                        '${event.trustLevel}/5',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quellen
                  Text(
                    'Quellen (${event.sources.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryGold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ...event.sources.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key + 1}. ',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textWhite.withValues(alpha: 0.7),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textWhite.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPerspectiveName(PerspectiveType type) {
    switch (type) {
      case PerspectiveType.mainstream:
        return 'Mainstream';
      case PerspectiveType.alternative:
        return 'Alternativ';
      case PerspectiveType.conspiracy:
        return 'Verschwörung';
      case PerspectiveType.spiritual:
        return 'Spirituell';
      case PerspectiveType.scientific:
        return 'Wissenschaftlich';
    }
  }
}
