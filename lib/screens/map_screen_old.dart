import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/app_theme.dart';
import '../models/historical_event.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<HistoricalEvent> _events = [];
  HistoricalEvent? _selectedEvent;
  EventCategory? _filterCategory;
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
    
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Lade alle Events mit Koordinaten
    final events = _generateMapEvents();
    
    if (mounted) {
      setState(() {
        _events = events;
        _isLoading = false;
      });
    }
  }

  List<HistoricalEvent> _generateMapEvents() {
    return [
      HistoricalEvent(
        id: '1',
        title: 'Roswell UFO-Vorfall',
        description: 'Ein mysteriöser Absturz nahe Roswell, New Mexico. Die offizielle Version spricht von einem Wetterballon, doch Augenzeugen berichten von außerirdischen Artefakten.',
        date: DateTime(1947, 7, 8),
        category: EventCategory.alienContact,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.alternative],
        sources: ['US Air Force Report 1947', 'Augenzeugenberichte', 'Declassified Documents'],
        trustLevel: 4,
        latitude: 33.3942,
        longitude: -104.5230,
        locationName: 'Roswell, New Mexico, USA',
      ),
      HistoricalEvent(
        id: '2',
        title: 'Atlantis - Die versunkene Zivilisation',
        description: 'Platons Beschreibung einer hochentwickelten Inselzivilisation, die vor 11.600 Jahren im Meer versank.',
        date: DateTime(-9600, 1, 1),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.alternative, PerspectiveType.spiritual],
        sources: ['Platons Timaios & Kritias', 'Geologische Studien'],
        trustLevel: 2,
        latitude: 31.0,
        longitude: -24.0,
        locationName: 'Atlantischer Ozean',
      ),
      HistoricalEvent(
        id: '3',
        title: 'Tunguska-Explosion',
        description: 'Eine gewaltige Explosion in Sibirien mit der Kraft von 1000 Hiroshima-Bomben. Kein Krater gefunden.',
        date: DateTime(1908, 6, 30),
        category: EventCategory.energyPhenomena,
        perspectives: [PerspectiveType.scientific, PerspectiveType.conspiracy],
        sources: ['Wissenschaftliche Expeditionen', 'Augenzeugenberichte'],
        trustLevel: 5,
        latitude: 60.886,
        longitude: 101.894,
        locationName: 'Tunguska, Sibirien, Russland',
      ),
      HistoricalEvent(
        id: '4',
        title: 'Nürnberger Himmelsschlacht 1561',
        description: 'Massenhafte UFO-Sichtung über Nürnberg. Zeitgenössische Holzschnitte zeigen Kugeln, Kreuze und Zylinder am Himmel kämpfend.',
        date: DateTime(1561, 4, 14),
        category: EventCategory.ufoFleets,
        perspectives: [PerspectiveType.alternative, PerspectiveType.conspiracy],
        sources: ['Hans Glaser Holzschnitt', 'Stadtchroniken Nürnberg'],
        trustLevel: 4,
        latitude: 49.4521,
        longitude: 11.0767,
        locationName: 'Nürnberg, Deutschland',
      ),
      HistoricalEvent(
        id: '5',
        title: 'MK-Ultra Mind Control',
        description: 'Geheimes CIA-Programm zur Bewusstseinskontrolle durch LSD, Hypnose und Folter. 1975 offiziell enthüllt.',
        date: DateTime(1953, 4, 13),
        category: EventCategory.globalConspiracies,
        perspectives: [PerspectiveType.mainstream, PerspectiveType.conspiracy],
        sources: ['Church Committee Report 1975', 'CIA Declassified Documents'],
        trustLevel: 5,
        latitude: 38.9072,
        longitude: -77.0369,
        locationName: 'Washington D.C., USA',
      ),
      HistoricalEvent(
        id: '6',
        title: 'Pyramiden von Gizeh',
        description: 'Die Great Pyramid zeigt mathematische Präzision, die moderne Technik herausfordert. Ausrichtung zu Orion und elektromagnetische Anomalien.',
        date: DateTime(-2560, 1, 1),
        category: EventCategory.techMysteries,
        perspectives: [PerspectiveType.alternative, PerspectiveType.spiritual],
        sources: ['Archäologische Studien', 'Elektromagnetische Messungen'],
        trustLevel: 3,
        latitude: 29.9792,
        longitude: 31.1342,
        locationName: 'Gizeh, Ägypten',
      ),
      HistoricalEvent(
        id: '7',
        title: 'Bermuda-Dreieck',
        description: 'Seit Jahrhunderten verschwinden Schiffe und Flugzeuge spurlos. Kompass-Anomalien, Zeitverzerrungen und dimensionale Portale.',
        date: DateTime(1945, 12, 5),
        category: EventCategory.dimensionalAnomalies,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.scientific],
        sources: ['US Navy Records', 'Küstenwache Berichte'],
        trustLevel: 3,
        latitude: 25.0,
        longitude: -71.0,
        locationName: 'Bermuda-Dreieck, Atlantik',
      ),
      HistoricalEvent(
        id: '8',
        title: 'Aleister Crowley - Abyss Working',
        description: 'Der berühmte Okkultist führte 1909 ein Ritual durch, das ein dimensionales Portal öffnete.',
        date: DateTime(1909, 11, 1),
        category: EventCategory.occultEvents,
        perspectives: [PerspectiveType.spiritual, PerspectiveType.alternative],
        sources: ['Crowleys Magisches Tagebuch', 'Zeitzeugenberichte'],
        trustLevel: 2,
        latitude: 36.1357,
        longitude: 5.3395,
        locationName: 'Algier, Algerien',
      ),
      HistoricalEvent(
        id: '9',
        title: 'Phoenix Lights 1997',
        description: 'Massensichtung eines V-förmigen UFOs über Arizona. Tausende Zeugen, inklusive Gouverneur.',
        date: DateTime(1997, 3, 13),
        category: EventCategory.ufoFleets,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.mainstream],
        sources: ['FAA Records', '10.000+ Zeugenaussagen', 'Video-Aufnahmen'],
        trustLevel: 5,
        latitude: 33.4484,
        longitude: -112.0740,
        locationName: 'Phoenix, Arizona, USA',
      ),
      HistoricalEvent(
        id: '10',
        title: 'Nazca-Linien',
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
        id: '11',
        title: 'HAARP Alaska',
        description: 'Ionosphären-Forschung oder Wetterkontrolle? 180 Antennen mit 3,6 MW Sendeleistung.',
        date: DateTime(1993, 1, 1),
        category: EventCategory.globalConspiracies,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.scientific],
        sources: ['US Air Force Dokumente', 'Wissenschaftliche Analysen'],
        trustLevel: 3,
        latitude: 62.3900,
        longitude: -145.1500,
        locationName: 'Gakona, Alaska, USA',
      ),
      HistoricalEvent(
        id: '12',
        title: 'Stonehenge',
        description: 'Prähistorisches Monument mit astronomischer Ausrichtung. Teil eines globalen Ley-Linien-Netzwerks.',
        date: DateTime(-3000, 1, 1),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.alternative, PerspectiveType.spiritual],
        sources: ['Archäologische Forschung', 'Ley-Linien-Studien'],
        trustLevel: 4,
        latitude: 51.1789,
        longitude: -1.8262,
        locationName: 'Wiltshire, England',
      ),
    ];
  }

  List<HistoricalEvent> get _filteredEvents {
    if (_filterCategory == null) return _events;
    return _events.where((e) => e.category == _filterCategory).toList();
  }

  List<Polyline> _buildLeyLines() {
    // Definiere mystische Verbindungen zwischen Events
    final leyConnections = [
      // Atlantis ↔ Bermuda-Dreieck
      ['2', '7'],
      // Pyramiden ↔ Nazca-Linien
      ['6', '10'],
      // Stonehenge ↔ Pyramiden
      ['12', '6'],
      // Roswell ↔ Phoenix Lights
      ['1', '9'],
      // Nürnberg ↔ HAARP
      ['4', '11'],
    ];
    
    return leyConnections.map((connection) {
      final event1 = _events.firstWhere((e) => e.id == connection[0]);
      final event2 = _events.firstWhere((e) => e.id == connection[1]);
      
      if (event1.latitude == null || event2.latitude == null) {
        return Polyline(points: []);
      }
      
      return Polyline(
        points: [
          LatLng(event1.latitude!, event1.longitude!),
          LatLng(event2.latitude!, event2.longitude!),
        ],
        color: AppTheme.secondaryGold.withValues(alpha: 0.3),
        strokeWidth: 2.0,
        borderColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
        borderStrokeWidth: 1.0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Karte
            _buildMap(),
            
            // Header
            _buildHeader(theme),
            
            // Filter-Bar
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: _buildFilterBar(),
            ),
            
            // Event-Details Bottom Sheet
            if (_selectedEvent != null)
              _buildEventBottomSheet(),
            
            // Loading Overlay
            if (_isLoading)
              Container(
                color: AppTheme.backgroundDark.withValues(alpha: 0.9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.secondaryGold,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lade mystische Orte...',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(30.0, 0.0),
        initialZoom: 2.0,
        minZoom: 2.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Karten-Tiles (Dark Theme)
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.weltenbibliothek.weltenbibliothek',
        ),
        
        // Ley-Linien (Verbindungslinien zwischen Events)
        PolylineLayer(
          polylines: _buildLeyLines(),
        ),
        
        // Event-Marker
        MarkerLayer(
          markers: _filteredEvents
              .where((event) => event.latitude != null && event.longitude != null)
              .map((event) => _buildEventMarker(event))
              .toList(),
        ),
      ],
    );
  }

  Marker _buildEventMarker(HistoricalEvent event) {
    final isSelected = _selectedEvent?.id == event.id;
    final color = _getCategoryColor(event.category);
    
    return Marker(
      point: LatLng(event.latitude!, event.longitude!),
      width: isSelected ? 60 : 50,
      height: isSelected ? 60 : 50,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedEvent = event;
          });
          
          // Zentriere Karte auf Event
          _mapController.move(
            LatLng(event.latitude!, event.longitude!),
            _mapController.camera.zoom < 5 ? 5 : _mapController.camera.zoom,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsierender Ring
              if (isSelected)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1500.ms)
                  .fade(begin: 1, end: 0, duration: 1500.ms),
              
              // Hauptmarker
              Container(
                width: isSelected ? 50 : 40,
                height: isSelected ? 50 : 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color: AppTheme.textWhite,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: isSelected ? 20 : 10,
                      spreadRadius: isSelected ? 5 : 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    event.categoryEmoji,
                    style: TextStyle(fontSize: isSelected ? 24 : 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundDark,
              AppTheme.backgroundDark.withValues(alpha: 0.9),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            Text(
              '🗺️',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event-Karte',
                    style: theme.textTheme.displayMedium?.copyWith(fontSize: 24),
                  ),
                  Text(
                    '${_filteredEvents.length} mystische Orte',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.my_location,
                color: AppTheme.secondaryGold,
              ),
              onPressed: () {
                _mapController.move(const LatLng(30.0, 0.0), 2.0);
              },
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: -0.3, end: 0),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('Alle', null, _events.length),
          const SizedBox(width: 8),
          ...EventCategory.values.map((category) {
            final count = _events.where((e) => e.category == category).length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                _getCategoryName(category),
                category,
                count,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, EventCategory? category, int count) {
    final isSelected = _filterCategory == category;
    final color = category != null ? _getCategoryColor(category) : AppTheme.primaryPurple;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.textWhite.withValues(alpha: 0.3) : color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterCategory = selected ? category : null;
          _selectedEvent = null;
        });
      },
      backgroundColor: AppTheme.surfaceDark,
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.textWhite : AppTheme.textWhite.withValues(alpha: 0.7),
        fontSize: 13,
      ),
    );
  }

  Widget _buildEventBottomSheet() {
    final event = _selectedEvent!;
    final dateFormat = DateFormat('dd.MM.yyyy');
    final yearFormat = event.date.year < 0 
        ? '${event.date.year.abs()} v.Chr.'
        : dateFormat.format(event.date);
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            setState(() => _selectedEvent = null);
          }
        },
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryGold,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Datum und Ort
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: AppTheme.secondaryGold),
                          const SizedBox(width: 8),
                          Text(yearFormat, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: AppTheme.secondaryGold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.locationName ?? 'Unbekannt',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Beschreibung
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textWhite.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Trust Level
                      Row(
                        children: [
                          Text(
                            'Vertrauensstufe: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textWhite.withValues(alpha: 0.7),
                            ),
                          ),
                          ...List.generate(5, (index) {
                            return Icon(
                              index < event.trustLevel ? Icons.star : Icons.star_border,
                              size: 18,
                              color: AppTheme.secondaryGold,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '${event.trustLevel}/5',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Navigiere zur Detail-Ansicht
                                setState(() => _selectedEvent = null);
                              },
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: const Text('Details'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryPurple,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _selectedEvent = null);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceDark,
                              side: BorderSide(color: AppTheme.primaryPurple),
                            ),
                            child: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate()
          .slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOut),
      ),
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

  String _getCategoryName(EventCategory category) {
    switch (category) {
      case EventCategory.lostCivilizations:
        return '🏛️';
      case EventCategory.alienContact:
        return '👽';
      case EventCategory.secretSocieties:
        return '🔺';
      case EventCategory.techMysteries:
        return '📡';
      case EventCategory.dimensionalAnomalies:
        return '🌀';
      case EventCategory.occultEvents:
        return '🔮';
      case EventCategory.forbiddenKnowledge:
        return '📜';
      case EventCategory.ufoFleets:
        return '🛸';
      case EventCategory.energyPhenomena:
        return '⚡';
      case EventCategory.globalConspiracies:
        return '🌍';
    }
  }
}
