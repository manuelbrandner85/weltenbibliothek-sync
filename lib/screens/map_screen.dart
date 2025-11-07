import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/app_theme.dart';
import '../models/historical_event.dart';
import '../services/live_data_service.dart';
import '../data/massive_events_data.dart';
import '../data/real_ley_lines_data.dart';
import '../widgets/compact_timeline_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LiveDataService _liveDataService = LiveDataService();
  List<HistoricalEvent> _events = [];
  HistoricalEvent? _selectedEvent;
  EventCategory? _filterCategory;
  bool _isLoading = true;
  
  // Live-Daten
  List<EarthquakeData> _earthquakes = [];
  ISSPosition? _issPosition;
  SchumannResonance? _schumannData;
  bool _showLiveData = true;
  EarthquakeData? _selectedEarthquake;
  
  // Zeitfilter
  int _startYear = -10000;
  int _endYear = 2025;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
      _loadLiveData();
      _startLiveDataStream();
    });
  }
  
  void _startLiveDataStream() {
    _liveDataService.getLiveDataStream().listen((update) {
      if (mounted) {
        setState(() {
          _earthquakes = update.earthquakes;
          _issPosition = update.issPosition;
          _schumannData = update.schumann;
        });
      }
    });
  }
  
  Future<void> _loadLiveData() async {
    final earthquakes = await _liveDataService.getEarthquakes();
    final issPos = await _liveDataService.getISSPosition();
    final schumann = await _liveDataService.getSchumannResonance();
    
    if (mounted) {
      setState(() {
        _earthquakes = earthquakes;
        _issPosition = issPos;
        _schumannData = schumann;
      });
    }
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
    // Nutze massive Events-Datenbank mit über 160 Events aus allen Kategorien
    return MassiveEventsData.getAllEvents();
  }

  List<HistoricalEvent> get _filteredEvents {
    return _events.where((e) {
      // Filter nach Kategorie
      if (_filterCategory != null && e.category != _filterCategory) {
        return false;
      }
      
      // Filter nach Zeitraum
      final eventYear = e.date.year;
      if (eventYear < _startYear || eventYear > _endYear) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// ECHTE LEY-LINIEN basierend auf Forschung und Becker-Hagens Grid
  /// Quellen: Alfred Watkins, Ivan Sanderson, Becker-Hagens System
  List<Polyline> _buildLeyLines() {
    final List<Polyline> lines = [];
    
    // Lade echte Ley-Linien-Verbindungen aus recherchierten Daten
    final majorConnections = RealLeyLinesData.getMajorConnections();
    final vortexConnections = RealLeyLinesData.getVortexConnections();
    
    // Zeichne Haupt-Ley-Linien (15 historisch belegte Verbindungen)
    for (var connection in majorConnections) {
      lines.add(Polyline(
        points: connection.points,
        color: _getLeyLineColor(connection.type),
        strokeWidth: _getLeyLineWidth(connection.type),
        borderColor: AppTheme.secondaryGold.withValues(alpha: 0.3),
        borderStrokeWidth: 1.0,
      ));
    }
    
    // Zeichne Vortex-Verbindungen (Sanderson's 12 Vile Vortices)
    for (var connection in vortexConnections) {
      lines.add(Polyline(
        points: connection.points,
        color: Colors.red.withValues(alpha: 0.6),
        strokeWidth: 2.0,
        borderColor: AppTheme.secondaryGold.withValues(alpha: 0.4),
        borderStrokeWidth: 1.5,
      ));
    }
    
    return lines;
  }
  
  /// Farbcodierung nach Ley-Linien-Typ
  Color _getLeyLineColor(LeyLineType type) {
    switch (type) {
      case LeyLineType.ancientMonuments:
        return AppTheme.secondaryGold.withValues(alpha: 0.7);
      case LeyLineType.pacificRing:
        return Colors.blue.withValues(alpha: 0.6);
      case LeyLineType.eurasianBelt:
        return Colors.green.withValues(alpha: 0.6);
      case LeyLineType.vortexChain:
        return Colors.red.withValues(alpha: 0.7);
      case LeyLineType.mediterraneanArc:
        return Colors.cyan.withValues(alpha: 0.6);
      case LeyLineType.americanAxis:
        return Colors.orange.withValues(alpha: 0.6);
      case LeyLineType.transPacific:
        return AppTheme.primaryPurple.withValues(alpha: 0.6);
      case LeyLineType.europeanMystical:
        return Colors.pink.withValues(alpha: 0.6);
      case LeyLineType.middleEastern:
        return Colors.yellow.withValues(alpha: 0.7);
      case LeyLineType.atlantisTriangle:
        return Colors.teal.withValues(alpha: 0.7);
      case LeyLineType.ufoTriangle:
        return Colors.lime.withValues(alpha: 0.7);
      case LeyLineType.americanVortex:
        return Colors.purple.withValues(alpha: 0.7);
      case LeyLineType.britishLey:
        return Colors.indigo.withValues(alpha: 0.6);
      case LeyLineType.asianTemples:
        return Colors.amber.withValues(alpha: 0.6);
      case LeyLineType.africanMeridian:
        return const Color(0xFF008080).withValues(alpha: 0.6); // Teal
      case LeyLineType.vortexRing:
        return const Color(0xFFDC143C).withValues(alpha: 0.7); // Crimson
    }
  }
  
  /// Liniendicke basierend auf Wichtigkeit
  double _getLeyLineWidth(LeyLineType type) {
    // Wichtigste Linien dicker
    if (type == LeyLineType.ancientMonuments || 
        type == LeyLineType.vortexChain ||
        type == LeyLineType.eurasianBelt) {
      return 3.5;
    }
    
    // UFO/Mystische Linien mittel-dick
    if (type == LeyLineType.ufoTriangle ||
        type == LeyLineType.atlantisTriangle ||
        type == LeyLineType.americanVortex) {
      return 3.0;
    }
    
    // Andere Linien standard
    return 2.5;
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
            
            // Timeline-Slider (kompakt)
            Positioned(
              top: 145,
              left: 0,
              right: 0,
              child: CompactTimelineSlider(
                minYear: -10000,
                maxYear: 2025,
                currentStartYear: _startYear,
                currentEndYear: _endYear,
                eventCount: _filteredEvents.length,
                onYearRangeChanged: (startYear, endYear) {
                  setState(() {
                    _startYear = startYear;
                    _endYear = endYear;
                  });
                },
              ),
            ),
            
            // Schumann-Resonanz Widget (unten links)
            if (_showLiveData && _schumannData != null)
              Positioned(
                bottom: 20,
                left: 20,
                child: _buildSchumannWidget(_schumannData!),
              ),
            
            // Event-Details Bottom Sheet
            if (_selectedEvent != null)
              _buildEventBottomSheet(),
            
            // Erdbeben-Details Bottom Sheet
            if (_selectedEarthquake != null)
              _buildEarthquakeBottomSheet(),
            
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
        
        // Ley-Linien (Intelligente Verbindungen)
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
        
        // Live-Daten-Marker
        if (_showLiveData) ...[
          // Erdbeben-Marker
          MarkerLayer(
            markers: _earthquakes.take(20).map((eq) {
              return _buildEarthquakeMarker(eq);
            }).toList(),
          ),
          
          // ISS-Marker
          if (_issPosition != null)
            MarkerLayer(
              markers: [_buildISSMarker(_issPosition!)],
            ),
        ],
      ],
    );
  }

  /// VERBESSERTE MARKER-ANIMATIONEN
  Marker _buildEventMarker(HistoricalEvent event) {
    final isSelected = _selectedEvent?.id == event.id;
    final color = _getCategoryColor(event.category);
    final index = _events.indexOf(event);
    
    return Marker(
      point: LatLng(event.latitude!, event.longitude!),
      width: isSelected ? 70 : 50,
      height: isSelected ? 70 : 50,
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
              // Äußerer Pulsierender Ring (langsam)
              if (isSelected)
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.4, 1.4), duration: 2000.ms)
                  .fade(begin: 0.8, end: 0, duration: 2000.ms),
              
              // Mittlerer Pulsierender Ring (schnell)
              if (isSelected)
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.secondaryGold.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1200.ms)
                  .fade(begin: 1, end: 0, duration: 1200.ms),
              
              // Glow-Effekt (konstant)
              Container(
                width: isSelected ? 55 : 45,
                height: isSelected ? 55 : 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isSelected ? 0.6 : 0.4),
                      blurRadius: isSelected ? 20 : 12,
                      spreadRadius: isSelected ? 8 : 4,
                    ),
                  ],
                ),
              ),
              
              // Hauptmarker mit Premium-Gradient
              Container(
                width: isSelected ? 50 : 40,
                height: isSelected ? 50 : 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isSelected 
                      ? [
                          color,
                          color.withValues(alpha: 0.9),
                          color.withValues(alpha: 0.7),
                        ]
                      : [
                          color.withValues(alpha: 1.0),
                          color.withValues(alpha: 0.8),
                        ],
                    stops: isSelected ? [0.0, 0.6, 1.0] : [0.0, 1.0],
                  ),
                  border: Border.all(
                    color: isSelected ? AppTheme.secondaryGold : AppTheme.textWhite,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isSelected ? 0.8 : 0.6),
                      blurRadius: isSelected ? 25 : 10,
                      spreadRadius: isSelected ? 6 : 2,
                    ),
                    // Zusätzlicher innerer Schatten-Effekt
                    if (isSelected)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    event.categoryEmoji,
                    style: TextStyle(fontSize: isSelected ? 24 : 20),
                  ),
                ),
              )
                // Erscheinungs-Animation beim Laden (gestaffelt)
                .animate(delay: Duration(milliseconds: index * 100))
                .scale(begin: const Offset(0, 0), end: const Offset(1, 1), 
                       duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),
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
              AppTheme.backgroundDark.withValues(alpha: 0),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.map,
                color: AppTheme.secondaryGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weltenkarte',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_filteredEvents.length} mystische Orte',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryGold,
                    ),
                  ),
                ],
              ),
            ),
            // Live-Daten Toggle
            IconButton(
              icon: Icon(
                _showLiveData ? Icons.satellite_alt : Icons.satellite_alt_outlined,
                color: _showLiveData ? Colors.cyan : AppTheme.textWhite.withValues(alpha: 0.5),
              ),
              onPressed: () {
                setState(() {
                  _showLiveData = !_showLiveData;
                });
              },
              tooltip: 'Live-Daten ${_showLiveData ? 'ausblenden' : 'anzeigen'}',
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
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: _getCategoryColor(event.category)),
            boxShadow: [
              BoxShadow(
                color: _getCategoryColor(event.category).withValues(alpha: 0.3),
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
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textWhite.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(event.category),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              event.categoryEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  color: AppTheme.textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                yearFormat,
                                style: TextStyle(
                                  color: AppTheme.secondaryGold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on, 
                             color: AppTheme.secondaryGold, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.locationName ?? 'Unbekannter Ort',
                            style: TextStyle(
                              color: AppTheme.textWhite.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Description
                    Text(
                      event.description,
                      style: TextStyle(
                        color: AppTheme.textWhite.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Trust Level
                    Row(
                      children: [
                        Text(
                          'Vertrauensstufe:',
                          style: TextStyle(
                            color: AppTheme.textWhite.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...List.generate(5, (index) {
                          return Icon(
                            index < event.trustLevel ? Icons.star : Icons.star_border,
                            color: AppTheme.secondaryGold,
                            size: 16,
                          );
                        }),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Event-Details in Modal-Dialog anzeigen
                              _showFullEventDetails(event);
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
  
  /// ERDBEBEN-MARKER (Klickbar)
  Marker _buildEarthquakeMarker(EarthquakeData eq) {
    final color = _getEarthquakeColor(eq.magnitude);
    final size = _getEarthquakeSize(eq.magnitude);
    final isSelected = _selectedEarthquake == eq;
    
    return Marker(
      point: LatLng(eq.latitude, eq.longitude),
      width: isSelected ? size + 10 : size,
      height: isSelected ? size + 10 : size,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedEvent = null; // Schließe Event-Details
            _selectedEarthquake = eq;
          });
          
          // Zentriere Karte auf Erdbeben
          _mapController.move(
            LatLng(eq.latitude, eq.longitude),
            _mapController.camera.zoom < 6 ? 6 : _mapController.camera.zoom,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsierender Ring bei Auswahl
            if (isSelected)
              Container(
                width: size + 20,
                height: size + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.6),
                    width: 3,
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.3, 1.3), duration: 1500.ms)
                .fade(begin: 1, end: 0, duration: 1500.ms),
            
            // Hauptmarker mit Premium-Gradient
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                    color.withValues(alpha: isSelected ? 0.9 : 0.6),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                border: Border.all(
                  color: isSelected ? AppTheme.secondaryGold : Colors.white,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.7),
                    blurRadius: isSelected ? 20 : 12,
                    spreadRadius: isSelected ? 6 : 3,
                  ),
                  // Innerer Glanz-Effekt
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 5,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  eq.magnitude.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSelected ? 12 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1500.ms)
              .then()
              .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1), duration: 1500.ms),
          ],
        ),
      ),
    );
  }
  
  Color _getEarthquakeColor(double magnitude) {
    if (magnitude >= 7.0) return Colors.red;
    if (magnitude >= 6.0) return Colors.deepOrange;
    if (magnitude >= 5.0) return Colors.orange;
    if (magnitude >= 4.0) return Colors.yellow;
    return Colors.green;
  }
  
  double _getEarthquakeSize(double magnitude) {
    if (magnitude >= 7.0) return 50;
    if (magnitude >= 6.0) return 40;
    if (magnitude >= 5.0) return 35;
    if (magnitude >= 4.0) return 30;
    return 25;
  }
  
  /// ISS-MARKER
  Marker _buildISSMarker(ISSPosition iss) {
    return Marker(
      point: LatLng(iss.latitude, iss.longitude),
      width: 60,
      height: 60,
      child: Tooltip(
        message: 'ISS Position\n${iss.latitude.toStringAsFixed(2)}, ${iss.longitude.toStringAsFixed(2)}',
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.cyan.withValues(alpha: 0.3),
            border: Border.all(color: Colors.cyan, width: 3),
          ),
          child: const Center(
            child: Text(
              '🛰️',
              style: TextStyle(fontSize: 28),
            ),
          ),
        )
          .animate(onPlay: (controller) => controller.repeat())
          .rotate(begin: 0, end: 1, duration: 10000.ms)
          .then()
          .shimmer(duration: 2000.ms, color: Colors.cyan),
      ),
    );
  }
  
  /// SCHUMANN-RESONANZ WIDGET
  Widget _buildSchumannWidget(SchumannResonance schumann) {
    final color = schumann.isAnomalous ? Colors.red : Colors.green;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.waves, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Schumann-Resonanz',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${schumann.frequency.toStringAsFixed(2)} Hz',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            schumann.interpretation,
            style: TextStyle(
              color: AppTheme.textWhite.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Q: ${schumann.quality.toStringAsFixed(1)}',
                style: TextStyle(
                  color: AppTheme.secondaryGold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'A: ${schumann.amplitude.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppTheme.secondaryGold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    )
      .animate(onPlay: (controller) => controller.repeat())
      .shimmer(
        duration: 3000.ms,
        color: schumann.isAnomalous ? Colors.red.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3),
      );
  }
  
  /// ERDBEBEN-DETAILS BOTTOM SHEET
  Widget _buildEarthquakeBottomSheet() {
    final eq = _selectedEarthquake!;
    final color = _getEarthquakeColor(eq.magnitude);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            setState(() => _selectedEarthquake = null);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
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
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textWhite.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header mit Magnitude
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  eq.magnitude.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'M',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                eq.magnitudeClass,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(eq.time),
                                style: TextStyle(
                                  color: AppTheme.secondaryGold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on, color: color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            eq.place,
                            style: const TextStyle(
                              color: AppTheme.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Details Grid
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.textWhite.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            '🌍 Koordinaten',
                            '${eq.latitude.toStringAsFixed(4)}°, ${eq.longitude.toStringAsFixed(4)}°',
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            '⬇️ Tiefe',
                            '${eq.depth.toStringAsFixed(1)} km',
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            '⏰ Zeit',
                            '${DateTime.now().difference(eq.time).inMinutes} Minuten her',
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: color, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Live-Daten vom USGS Earthquake Hazards Program',
                              style: TextStyle(
                                color: AppTheme.textWhite.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: eq.url != null ? () {
                              // USGS URL im Browser öffnen
                              _openUSGSUrl(eq.url!);
                            } : null,
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('USGS Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _selectedEarthquake = null);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceDark,
                            side: BorderSide(color: color),
                          ),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate()
          .slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOut),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textWhite.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  /// VOLLSTÄNDIGE EVENT-DETAILS IN MODAL ANZEIGEN
  void _showFullEventDetails(HistoricalEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: _getCategoryColor(event.category)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textWhite.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
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
                            Text(event.categoryEmoji, style: const TextStyle(fontSize: 18)),
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
                          Icon(Icons.calendar_today, size: 18, color: AppTheme.secondaryGold),
                          const SizedBox(width: 8),
                          Text(
                            event.date.year < 0 
                                ? '${event.date.year.abs()} v.Chr.'
                                : DateFormat('dd.MM.yyyy').format(event.date),
                            style: const TextStyle(fontSize: 16, color: AppTheme.textWhite),
                          ),
                        ],
                      ),
                      
                      if (event.locationName != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 18, color: AppTheme.secondaryGold),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event.locationName!,
                                style: const TextStyle(fontSize: 16, color: AppTheme.textWhite),
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
                            style: const TextStyle(fontSize: 16, color: AppTheme.textWhite),
                          ),
                        ],
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
                            child: Text(
                              _getPerspectiveName(p),
                              style: const TextStyle(fontSize: 14, color: AppTheme.textWhite),
                            ),
                          );
                        }).toList(),
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
        ),
      ),
    );
  }
  
  /// Perspektiven-Namen Helper
  String _getPerspectiveName(PerspectiveType type) {
    switch (type) {
      case PerspectiveType.mainstream:
        return '🏛️ Mainstream';
      case PerspectiveType.alternative:
        return '🔍 Alternativ';
      case PerspectiveType.conspiracy:
        return '🕵️ Verschwörung';
      case PerspectiveType.spiritual:
        return '🧘 Spirituell';
      case PerspectiveType.scientific:
        return '🔬 Wissenschaftlich';
      case PerspectiveType.alien:
        return '👽 Alien';
      case PerspectiveType.occult:
        return '🔮 Okkult';
    }
  }
  
  /// USGS URL im Browser öffnen
  Future<void> _openUSGSUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konnte USGS-Link nicht öffnen'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Öffnen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
