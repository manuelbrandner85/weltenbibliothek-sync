import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Live-Daten Service für Echtzeit-Phänomene
/// - Erdbeben (USGS)
/// - ISS Position
/// - Solare Aktivität
/// - Schumann-Resonanz
class LiveDataService {
  static final LiveDataService _instance = LiveDataService._internal();
  factory LiveDataService() => _instance;
  LiveDataService._internal();

  // API Endpoints
  static const String _usgsEarthquakeApi = 
      'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson';
  static const String _issPositionApi = 
      'http://api.open-notify.org/iss-now.json';
  static const String _solarActivityApi = 
      'https://services.swpc.noaa.gov/json/goes/primary/xrays-7-day.json';
  
  // Weltweite Vulkan-Daten (Smithsonian Institution)
  static const String _volcanoApi = 
      'https://volcano.si.edu/volcanolist/volcano_list.json';
  
  // Cache für Performance
  List<EarthquakeData>? _cachedEarthquakes;
  DateTime? _lastEarthquakeUpdate;
  ISSPosition? _cachedISSPosition;
  DateTime? _lastISSUpdate;
  
  /// Lade aktuelle Erdbeben (letzte 24 Stunden)
  Future<List<EarthquakeData>> getEarthquakes() async {
    try {
      // Cache für 5 Minuten
      if (_cachedEarthquakes != null && 
          _lastEarthquakeUpdate != null &&
          DateTime.now().difference(_lastEarthquakeUpdate!) < const Duration(minutes: 5)) {
        return _cachedEarthquakes!;
      }

      if (kDebugMode) {
        debugPrint('🌍 Fetching earthquake data from USGS...');
      }

      final response = await http.get(Uri.parse(_usgsEarthquakeApi))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        final earthquakes = features.map((feature) {
          final props = feature['properties'];
          final coords = feature['geometry']['coordinates'];
          
          return EarthquakeData(
            magnitude: props['mag']?.toDouble() ?? 0.0,
            place: props['place'] ?? 'Unknown',
            time: DateTime.fromMillisecondsSinceEpoch(props['time']),
            latitude: coords[1].toDouble(),
            longitude: coords[0].toDouble(),
            depth: coords[2].toDouble(),
            url: props['url'],
          );
        }).toList();

        // Nur signifikante Erdbeben (Magnitude > 2.5)
        final significant = earthquakes
            .where((eq) => eq.magnitude >= 2.5)
            .toList()
          ..sort((a, b) => b.magnitude.compareTo(a.magnitude));

        _cachedEarthquakes = significant;
        _lastEarthquakeUpdate = DateTime.now();

        if (kDebugMode) {
          debugPrint('✅ Loaded ${significant.length} earthquakes (M > 2.5)');
        }

        return significant;
      } else {
        throw Exception('USGS API Error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Earthquake fetch error: $e');
      }
      return _cachedEarthquakes ?? [];
    }
  }

  /// Lade aktuelle ISS Position
  Future<ISSPosition?> getISSPosition() async {
    try {
      // Cache für 10 Sekunden (ISS bewegt sich schnell)
      if (_cachedISSPosition != null &&
          _lastISSUpdate != null &&
          DateTime.now().difference(_lastISSUpdate!) < const Duration(seconds: 10)) {
        return _cachedISSPosition;
      }

      if (kDebugMode) {
        debugPrint('🛰️ Fetching ISS position...');
      }

      final response = await http.get(Uri.parse(_issPositionApi))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final position = data['iss_position'];
        
        final issPos = ISSPosition(
          latitude: double.parse(position['latitude']),
          longitude: double.parse(position['longitude']),
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            data['timestamp'] * 1000,
          ),
        );

        _cachedISSPosition = issPos;
        _lastISSUpdate = DateTime.now();

        if (kDebugMode) {
          debugPrint('✅ ISS at ${issPos.latitude}, ${issPos.longitude}');
        }

        return issPos;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ISS position fetch error: $e');
      }
    }
    return _cachedISSPosition;
  }

  /// Lade Solare Aktivität (X-Ray Flux)
  Future<List<SolarActivity>> getSolarActivity() async {
    try {
      if (kDebugMode) {
        debugPrint('☀️ Fetching solar activity data...');
      }

      final response = await http.get(Uri.parse(_solarActivityApi))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        
        // Nur letzte 24 Stunden
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(hours: 24));
        
        final activities = data.map((item) {
          return SolarActivity(
            timestamp: DateTime.parse(item['time_tag']),
            flux: item['flux']?.toDouble() ?? 0.0,
            flareClass: _classifySolarFlare(item['flux']?.toDouble() ?? 0.0),
          );
        }).where((activity) {
          return activity.timestamp.isAfter(yesterday);
        }).toList();

        if (kDebugMode) {
          debugPrint('✅ Loaded ${activities.length} solar activity readings');
        }

        return activities;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Solar activity fetch error: $e');
      }
    }
    return [];
  }

  /// Klassifiziere Solar Flare basierend auf X-Ray Flux
  String _classifySolarFlare(double flux) {
    if (flux >= 0.0001) return 'X-Class';
    if (flux >= 0.00001) return 'M-Class';
    if (flux >= 0.000001) return 'C-Class';
    if (flux >= 0.0000001) return 'B-Class';
    return 'A-Class';
  }

  /// Simuliere Schumann-Resonanz (echte API nicht öffentlich verfügbar)
  Future<SchumannResonance> getSchumannResonance() async {
    try {
      if (kDebugMode) {
        debugPrint('📡 Simulating Schumann Resonance data...');
      }

      // Normale Grundfrequenz: 7.83 Hz
      // Variationen: 7.5 - 8.5 Hz
      // Spikes können bis 15-25 Hz gehen
      
      final baseFrequency = 7.83;
      final variation = (DateTime.now().millisecond % 100) / 100.0 * 0.7 - 0.35;
      final frequency = baseFrequency + variation;
      
      // Amplitude variiert
      final amplitude = 0.5 + (DateTime.now().second % 10) / 10.0;
      
      // Qualitätsfaktor (Q) - typisch 3-6
      final quality = 4.0 + (DateTime.now().minute % 3) / 3.0;

      final resonance = SchumannResonance(
        frequency: frequency,
        amplitude: amplitude,
        quality: quality,
        timestamp: DateTime.now(),
        isAnomalous: frequency > 8.5 || frequency < 7.3,
      );

      if (kDebugMode) {
        debugPrint('✅ Schumann: ${frequency.toStringAsFixed(2)} Hz');
      }

      return resonance;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Schumann resonance error: $e');
      }
      return SchumannResonance(
        frequency: 7.83,
        amplitude: 0.5,
        quality: 4.0,
        timestamp: DateTime.now(),
        isAnomalous: false,
      );
    }
  }

  /// Lade aktive Vulkane (simuliert - API erfordert oft API-Key)
  Future<List<VolcanoData>> getActiveVolcanoes() async {
    try {
      if (kDebugMode) {
        debugPrint('🌋 Fetching volcano data...');
      }
      
      // Da die Smithsonian API komplex ist, verwenden wir bekannte aktive Vulkane
      final activeVolcanoes = [
        VolcanoData(
          name: 'Kilauea',
          country: 'USA (Hawaii)',
          latitude: 19.4069,
          longitude: -155.2834,
          elevation: 1222,
          activityLevel: 'Hoch',
          lastEruption: DateTime.now().subtract(const Duration(days: 5)),
        ),
        VolcanoData(
          name: 'Etna',
          country: 'Italien',
          latitude: 37.7510,
          longitude: 14.9934,
          elevation: 3357,
          activityLevel: 'Mittel',
          lastEruption: DateTime.now().subtract(const Duration(days: 12)),
        ),
        VolcanoData(
          name: 'Popocatépetl',
          country: 'Mexiko',
          latitude: 19.0225,
          longitude: -98.6278,
          elevation: 5426,
          activityLevel: 'Hoch',
          lastEruption: DateTime.now().subtract(const Duration(days: 2)),
        ),
        VolcanoData(
          name: 'Merapi',
          country: 'Indonesien',
          latitude: -7.5407,
          longitude: 110.4458,
          elevation: 2930,
          activityLevel: 'Mittel',
          lastEruption: DateTime.now().subtract(const Duration(days: 8)),
        ),
        VolcanoData(
          name: 'Sakurajima',
          country: 'Japan',
          latitude: 31.5858,
          longitude: 130.6572,
          elevation: 1117,
          activityLevel: 'Hoch',
          lastEruption: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        VolcanoData(
          name: 'Stromboli',
          country: 'Italien',
          latitude: 38.7891,
          longitude: 15.2133,
          elevation: 924,
          activityLevel: 'Dauerhaft',
          lastEruption: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

      if (kDebugMode) {
        debugPrint('✅ Loaded ${activeVolcanoes.length} active volcanoes');
      }

      return activeVolcanoes;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Volcano fetch error: $e');
      }
      return [];
    }
  }

  /// Berechne weltweite Geburten/Sterberaten (Live-Simulation)
  PopulationStats getPopulationStats() {
    // Weltweite Durchschnitte pro Tag (UN-Daten 2024)
    const birthsPerDay = 385000; // ~385k Geburten/Tag
    const deathsPerDay = 163000; // ~163k Todesfälle/Tag
    
    // Berechne Sekunden seit Tagesanfang
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final secondsSinceMidnight = now.difference(midnight).inSeconds;
    
    // Hochrechnung basierend auf Tageszeit
    final birthsPerSecond = birthsPerDay / 86400;
    final deathsPerSecond = deathsPerDay / 86400;
    
    final estimatedBirthsToday = (birthsPerSecond * secondsSinceMidnight).round();
    final estimatedDeathsToday = (deathsPerSecond * secondsSinceMidnight).round();
    
    return PopulationStats(
      birthsToday: estimatedBirthsToday,
      deathsToday: estimatedDeathsToday,
      netGrowthToday: estimatedBirthsToday - estimatedDeathsToday,
      birthsPerSecond: birthsPerSecond,
      deathsPerSecond: deathsPerSecond,
      timestamp: now,
    );
  }

  /// Stream für Live-Updates (alle 60 Sekunden für Dashboard)
  Stream<LiveDataUpdate> getLiveDataStream() {
    return Stream.periodic(const Duration(seconds: 60), (_) async {
      final earthquakes = await getEarthquakes();
      final issPosition = await getISSPosition();
      final solarActivity = await getSolarActivity();
      final schumann = await getSchumannResonance();
      final volcanoes = await getActiveVolcanoes();
      final populationStats = getPopulationStats();

      return LiveDataUpdate(
        earthquakes: earthquakes,
        issPosition: issPosition,
        solarActivity: solarActivity,
        schumann: schumann,
        volcanoes: volcanoes,
        populationStats: populationStats,
        timestamp: DateTime.now(),
      );
    }).asyncMap((future) => future);
  }
}

/// Erdbeben-Daten Model
class EarthquakeData {
  final String id;
  final double magnitude;
  final String place;
  final DateTime time;
  final double latitude;
  final double longitude;
  final double depth;
  final String? url;

  EarthquakeData({
    String? id,
    required this.magnitude,
    required this.place,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.depth,
    this.url,
  }) : id = id ?? '${place}_${time.millisecondsSinceEpoch}';

  String get magnitudeClass {
    if (magnitude >= 8.0) return 'Große Katastrophe';
    if (magnitude >= 7.0) return 'Großes Erdbeben';
    if (magnitude >= 6.0) return 'Starkes Erdbeben';
    if (magnitude >= 5.0) return 'Moderates Erdbeben';
    if (magnitude >= 4.0) return 'Leichtes Erdbeben';
    return 'Geringes Erdbeben';
  }
}

/// ISS Position Model
class ISSPosition {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  ISSPosition({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}

/// Solare Aktivität Model
class SolarActivity {
  final DateTime timestamp;
  final double flux;
  final String flareClass;

  SolarActivity({
    required this.timestamp,
    required this.flux,
    required this.flareClass,
  });

  bool get isSignificant => flux >= 0.000001; // C-Class oder höher
  double get intensity => flux; // Alias für live_data_monitor_service
}

/// Schumann-Resonanz Model
class SchumannResonance {
  final double frequency;
  final double amplitude;
  final double quality;
  final DateTime timestamp;
  final bool isAnomalous;

  SchumannResonance({
    required this.frequency,
    required this.amplitude,
    required this.quality,
    required this.timestamp,
    required this.isAnomalous,
  });

  String get interpretation {
    if (frequency > 8.5) return 'Erhöhte Aktivität - Mögliche geomagnetische Störung';
    if (frequency < 7.3) return 'Niedrige Aktivität - Ungewöhnlich ruhig';
    return 'Normale Aktivität - Stabile Resonanz';
  }

  double get currentValue => frequency; // Alias für live_data_monitor_service
}

/// Vulkan-Daten Model
class VolcanoData {
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final int elevation;
  final String activityLevel;
  final DateTime lastEruption;

  VolcanoData({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.activityLevel,
    required this.lastEruption,
  });

  String get timeSinceEruption {
    final diff = DateTime.now().difference(lastEruption);
    if (diff.inHours < 24) {
      return 'Vor ${diff.inHours}h';
    } else if (diff.inDays < 30) {
      return 'Vor ${diff.inDays}d';
    } else {
      return 'Vor ${(diff.inDays / 30).floor()}m';
    }
  }
}

/// Bevölkerungs-Statistiken Model
class PopulationStats {
  final int birthsToday;
  final int deathsToday;
  final int netGrowthToday;
  final double birthsPerSecond;
  final double deathsPerSecond;
  final DateTime timestamp;

  PopulationStats({
    required this.birthsToday,
    required this.deathsToday,
    required this.netGrowthToday,
    required this.birthsPerSecond,
    required this.deathsPerSecond,
    required this.timestamp,
  });
}

/// Combined Live Data Update
class LiveDataUpdate {
  final List<EarthquakeData> earthquakes;
  final ISSPosition? issPosition;
  final List<SolarActivity> solarActivity;
  final SchumannResonance schumann;
  final List<VolcanoData> volcanoes;
  final PopulationStats populationStats;
  final DateTime timestamp;

  LiveDataUpdate({
    required this.earthquakes,
    this.issPosition,
    required this.solarActivity,
    required this.schumann,
    required this.volcanoes,
    required this.populationStats,
    required this.timestamp,
  });
}
