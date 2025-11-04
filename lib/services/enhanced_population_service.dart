import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enhanced_population_data.dart';

/// Enhanced Population Service mit Live-Streaming
/// 
/// Features:
/// - Weltbevölkerungs-Echtzeit-Counter
/// - Geburten/Todesfälle pro Sekunde
/// - Kontinentale & länderspezifische Daten
/// - Population Density Heatmap Daten
/// - Live Birth/Death Event Markers
class EnhancedPopulationService {
  static final EnhancedPopulationService _instance = EnhancedPopulationService._internal();
  factory EnhancedPopulationService() => _instance;
  EnhancedPopulationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Weltbevölkerungs-APIs
  static const String _worldometerApi = 'https://www.worldometers.info/world-population/';
  static const String _unDataApi = 'https://population.un.org/dataportal/api';
  
  // Baseline Daten (UN World Population Prospects 2024)
  static const double _baselinePopulation2024 = 8118836000; // 8.12 Milliarden
  static const double _annualGrowthRate = 0.0088; // 0.88% pro Jahr
  static const int _birthsPerDay = 385000; // ~385k Geburten/Tag
  static const int _deathsPerDay = 163000; // ~163k Todesfälle/Tag
  
  // Cache
  EnhancedPopulationData? _cachedData;
  DateTime? _lastUpdate;
  final Duration _cacheValidity = const Duration(minutes: 1);

  /// Hauptmethode: Lade Enhanced Population Daten
  Future<EnhancedPopulationData> getEnhancedPopulationData() async {
    try {
      // Check cache (nur 1 Minute, da Live-Counter)
      if (_cachedData != null && 
          _lastUpdate != null &&
          DateTime.now().difference(_lastUpdate!) < _cacheValidity) {
        if (kDebugMode) {
          debugPrint('👥 Returning cached population data');
        }
        return _cachedData!;
      }

      if (kDebugMode) {
        debugPrint('👥 Fetching fresh population data...');
      }

      // Berechne aktuelle Bevölkerung basierend auf Wachstumsrate
      final now = DateTime.now();
      final baselineDate = DateTime(2024, 1, 1);
      final daysSinceBaseline = now.difference(baselineDate).inDays;
      
      final dailyGrowth = (_birthsPerDay - _deathsPerDay).toDouble();
      final totalGrowth = dailyGrowth * daysSinceBaseline;
      final currentPopulation = (_baselinePopulation2024 + totalGrowth).toInt();

      // Berechne Geburten/Todesfälle heute
      final midnight = DateTime(now.year, now.month, now.day);
      final secondsSinceMidnight = now.difference(midnight).inSeconds;
      
      final birthsPerSecond = _birthsPerDay / 86400.0;
      final deathsPerSecond = _deathsPerDay / 86400.0;
      final growthPerSecond = birthsPerSecond - deathsPerSecond;
      
      final birthsToday = (birthsPerSecond * secondsSinceMidnight).round();
      final deathsToday = (deathsPerSecond * secondsSinceMidnight).round();

      // Kontinentale Verteilung (UN 2024 Daten)
      final byContinent = {
        'Asien': (currentPopulation * 0.593).toInt(),           // 59.3%
        'Afrika': (currentPopulation * 0.182).toInt(),          // 18.2%
        'Europa': (currentPopulation * 0.094).toInt(),          // 9.4%
        'Lateinamerika': (currentPopulation * 0.083).toInt(),   // 8.3%
        'Nordamerika': (currentPopulation * 0.046).toInt(),     // 4.6%
        'Ozeanien': (currentPopulation * 0.005).toInt(),        // 0.5%
      };

      // Top 20 Länder nach Bevölkerung
      final byCountry = {
        'China': 1425671352,
        'Indien': 1428627663,
        'USA': 339996563,
        'Indonesien': 277534122,
        'Pakistan': 240485658,
        'Nigeria': 223804632,
        'Brasilien': 216422446,
        'Bangladesch': 172954319,
        'Russland': 144444359,
        'Mexiko': 128455567,
        'Japan': 123294513,
        'Äthiopien': 126527060,
        'Philippinen': 117337368,
        'Ägypten': 112716598,
        'Vietnam': 98858950,
        'DR Kongo': 102262808,
        'Iran': 89172767,
        'Türkei': 85816199,
        'Deutschland': 83294633,
        'Thailand': 71801279,
      };

      // Demographische Daten
      const medianAge = 30.5; // Weltweites Median-Alter
      const urbanPopulationPercent = 57.5; // 57.5% leben in Städten

      // Density Points für Heatmap
      final densityPoints = await _generateDensityPoints();

      // Live Events (letzte 10 Sekunden)
      final recentEvents = _generateRecentEvents(
        birthsPerSecond,
        deathsPerSecond,
      );

      final enhancedData = EnhancedPopulationData(
        totalPopulation: currentPopulation,
        timestamp: now,
        birthsToday: birthsToday,
        deathsToday: deathsToday,
        growthPerSecond: growthPerSecond,
        byContinent: byContinent,
        byCountry: byCountry,
        medianAge: medianAge,
        urbanPopulationPercent: urbanPopulationPercent,
        densityPoints: densityPoints,
        recentEvents: recentEvents,
      );

      _cachedData = enhancedData;
      _lastUpdate = now;

      // Speichere Snapshot in Firestore (einmal pro Stunde)
      if (now.minute == 0 && now.second < 60) {
        await _savePopulationSnapshot(enhancedData);
      }

      if (kDebugMode) {
        debugPrint('✅ Population data ready: ${_formatPopulation(currentPopulation)}');
        debugPrint('   Births today: $birthsToday, Deaths: $deathsToday');
      }

      return enhancedData;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching population data: $e');
      }
      
      // Fallback: Basis-Berechnung
      return _generateFallbackData();
    }
  }

  /// Generiere Population Density Points für Heatmap
  Future<List<PopulationDensityPoint>> _generateDensityPoints() async {
    try {
      // Lade gespeicherte Density Daten aus Firestore
      final snapshot = await _firestore
          .collection('population_density')
          .limit(500)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return PopulationDensityPoint(
            latitude: data['latitude'] as double,
            longitude: data['longitude'] as double,
            density: data['density'] as double,
            cityName: data['cityName'] as String?,
          );
        }).toList();
      }

      // Fallback: Generiere bekannte Großstädte
      return _generateKnownCitiesDensity();

    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Using fallback density data: $e');
      }
      return _generateKnownCitiesDensity();
    }
  }

  /// Generiere Density Points für bekannte Großstädte
  List<PopulationDensityPoint> _generateKnownCitiesDensity() {
    return [
      // Asien - sehr hohe Dichte
      PopulationDensityPoint(latitude: 35.6762, longitude: 139.6503, density: 6158.0, cityName: 'Tokyo'),
      PopulationDensityPoint(latitude: 28.7041, longitude: 77.1025, density: 11320.0, cityName: 'Delhi'),
      PopulationDensityPoint(latitude: 31.2304, longitude: 121.4737, density: 3826.0, cityName: 'Shanghai'),
      PopulationDensityPoint(latitude: 22.3193, longitude: 114.1694, density: 6659.0, cityName: 'Hong Kong'),
      PopulationDensityPoint(latitude: 37.5665, longitude: 126.9780, density: 16364.0, cityName: 'Seoul'),
      PopulationDensityPoint(latitude: 19.0760, longitude: 72.8777, density: 20694.0, cityName: 'Mumbai'),
      PopulationDensityPoint(latitude: 39.9042, longitude: 116.4074, density: 1312.0, cityName: 'Beijing'),
      PopulationDensityPoint(latitude: -6.2088, longitude: 106.8456, density: 15342.0, cityName: 'Jakarta'),
      PopulationDensityPoint(latitude: 1.3521, longitude: 103.8198, density: 7953.0, cityName: 'Singapur'),
      PopulationDensityPoint(latitude: 13.7563, longitude: 100.5018, density: 5300.0, cityName: 'Bangkok'),
      
      // Europa - mittlere bis hohe Dichte
      PopulationDensityPoint(latitude: 51.5074, longitude: -0.1278, density: 5701.0, cityName: 'London'),
      PopulationDensityPoint(latitude: 48.8566, longitude: 2.3522, density: 21067.0, cityName: 'Paris'),
      PopulationDensityPoint(latitude: 52.5200, longitude: 13.4050, density: 4115.0, cityName: 'Berlin'),
      PopulationDensityPoint(latitude: 55.7558, longitude: 37.6173, density: 4900.0, cityName: 'Moskau'),
      PopulationDensityPoint(latitude: 41.9028, longitude: 12.4964, density: 2232.0, cityName: 'Rom'),
      
      // Nordamerika - mittlere Dichte
      PopulationDensityPoint(latitude: 40.7128, longitude: -74.0060, density: 10933.0, cityName: 'New York'),
      PopulationDensityPoint(latitude: 34.0522, longitude: -118.2437, density: 3276.0, cityName: 'Los Angeles'),
      PopulationDensityPoint(latitude: 19.4326, longitude: -99.1332, density: 6000.0, cityName: 'Mexiko-Stadt'),
      PopulationDensityPoint(latitude: 43.6532, longitude: -79.3832, density: 4334.0, cityName: 'Toronto'),
      
      // Südamerika - mittlere Dichte
      PopulationDensityPoint(latitude: -23.5505, longitude: -46.6333, density: 7821.0, cityName: 'São Paulo'),
      PopulationDensityPoint(latitude: -34.6037, longitude: -58.3816, density: 14450.0, cityName: 'Buenos Aires'),
      PopulationDensityPoint(latitude: -22.9068, longitude: -43.1729, density: 5265.0, cityName: 'Rio de Janeiro'),
      
      // Afrika - niedrige bis mittlere Dichte
      PopulationDensityPoint(latitude: 30.0444, longitude: 31.2357, density: 19376.0, cityName: 'Kairo'),
      PopulationDensityPoint(latitude: 6.5244, longitude: 3.3792, density: 2594.0, cityName: 'Lagos'),
      PopulationDensityPoint(latitude: -26.2041, longitude: 28.0473, density: 2364.0, cityName: 'Johannesburg'),
      
      // Ozeanien - niedrige Dichte
      PopulationDensityPoint(latitude: -33.8688, longitude: 151.2093, density: 433.0, cityName: 'Sydney'),
      PopulationDensityPoint(latitude: -37.8136, longitude: 144.9631, density: 508.0, cityName: 'Melbourne'),
    ];
  }

  /// Generiere kürzliche Geburts/Todes-Events
  List<PopulationEvent> _generateRecentEvents(double birthRate, double deathRate) {
    final now = DateTime.now();
    final random = Random(now.millisecondsSinceEpoch);
    final events = <PopulationEvent>[];

    // Generiere Events für letzte 10 Sekunden
    for (int i = 10; i > 0; i--) {
      final timestamp = now.subtract(Duration(seconds: i));
      
      // Berechne erwartete Events in diesem Zeitfenster
      final expectedBirths = birthRate;
      final expectedDeaths = deathRate;
      
      // Geburten
      if (random.nextDouble() < expectedBirths) {
        // Zufällige Position (bevölkerungsgewichtet)
        final latLng = _getRandomPopulationWeightedLocation(random);
        events.add(PopulationEvent(
          type: PopulationEventType.birth,
          timestamp: timestamp,
          latitude: latLng.$1,
          longitude: latLng.$2,
        ));
      }
      
      // Todesfälle
      if (random.nextDouble() < expectedDeaths) {
        final latLng = _getRandomPopulationWeightedLocation(random);
        events.add(PopulationEvent(
          type: PopulationEventType.death,
          timestamp: timestamp,
          latitude: latLng.$1,
          longitude: latLng.$2,
        ));
      }
    }

    return events;
  }

  /// Generiere zufällige Position bevölkerungsgewichtet
  (double, double) _getRandomPopulationWeightedLocation(Random random) {
    // Kontinente mit Wahrscheinlichkeit basierend auf Bevölkerung
    final continent = random.nextDouble();
    
    if (continent < 0.593) {
      // Asien - 59.3%
      return (
        20.0 + random.nextDouble() * 30.0, // Lat: 20-50 N
        70.0 + random.nextDouble() * 70.0, // Lon: 70-140 E
      );
    } else if (continent < 0.775) {
      // Afrika - 18.2%
      return (
        -30.0 + random.nextDouble() * 50.0, // Lat: 30 S - 20 N
        -20.0 + random.nextDouble() * 60.0, // Lon: 20 W - 40 E
      );
    } else if (continent < 0.869) {
      // Europa - 9.4%
      return (
        35.0 + random.nextDouble() * 35.0, // Lat: 35-70 N
        -10.0 + random.nextDouble() * 50.0, // Lon: 10 W - 40 E
      );
    } else if (continent < 0.952) {
      // Lateinamerika - 8.3%
      return (
        -55.0 + random.nextDouble() * 70.0, // Lat: 55 S - 15 N
        -90.0 + random.nextDouble() * 55.0, // Lon: 90 W - 35 W
      );
    } else if (continent < 0.998) {
      // Nordamerika - 4.6%
      return (
        25.0 + random.nextDouble() * 45.0, // Lat: 25-70 N
        -130.0 + random.nextDouble() * 60.0, // Lon: 130 W - 70 W
      );
    } else {
      // Ozeanien - 0.5%
      return (
        -45.0 + random.nextDouble() * 50.0, // Lat: 45 S - 5 N
        110.0 + random.nextDouble() * 70.0, // Lon: 110-180 E
      );
    }
  }

  /// Speichere Population Snapshot in Firestore
  Future<void> _savePopulationSnapshot(EnhancedPopulationData data) async {
    try {
      await _firestore.collection('population_history').add({
        'population': data.totalPopulation,
        'birthsToday': data.birthsToday,
        'deathsToday': data.deathsToday,
        'timestamp': Timestamp.fromDate(data.timestamp),
      });

      if (kDebugMode) {
        debugPrint('💾 Saved population snapshot to Firestore');
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving population snapshot: $e');
      }
    }
  }

  /// Generiere Fallback-Daten
  EnhancedPopulationData _generateFallbackData() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final secondsSinceMidnight = now.difference(midnight).inSeconds;
    
    final birthsPerSecond = _birthsPerDay / 86400.0;
    final deathsPerSecond = _deathsPerDay / 86400.0;
    
    return EnhancedPopulationData(
      totalPopulation: _baselinePopulation2024.toInt(),
      timestamp: now,
      birthsToday: (birthsPerSecond * secondsSinceMidnight).round(),
      deathsToday: (deathsPerSecond * secondsSinceMidnight).round(),
      growthPerSecond: birthsPerSecond - deathsPerSecond,
      byContinent: {},
      byCountry: {},
      medianAge: 30.5,
      urbanPopulationPercent: 57.5,
      densityPoints: _generateKnownCitiesDensity(),
      recentEvents: [],
    );
  }

  /// Stream für kontinuierliche Updates (jede Sekunde für Live-Counter)
  Stream<EnhancedPopulationData> getPopulationStream() {
    return Stream.periodic(const Duration(seconds: 1), (_) async {
      return await getEnhancedPopulationData();
    }).asyncMap((future) => future);
  }

  /// Formatiere Bevölkerungszahl
  String _formatPopulation(int population) {
    if (population >= 1000000000) {
      return '${(population / 1000000000).toStringAsFixed(2)} Mrd';
    } else if (population >= 1000000) {
      return '${(population / 1000000).toStringAsFixed(1)} Mio';
    } else {
      return population.toString();
    }
  }

  /// Lade historische Population Daten
  Future<List<PopulationHistoryPoint>> getHistoricalData(int days) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(days: days));
      
      final snapshot = await _firestore
          .collection('population_history')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoffTime))
          .get();

      final points = snapshot.docs.map((doc) {
        final data = doc.data();
        return PopulationHistoryPoint(
          population: data['population'] as int,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();

      points.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return points;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading historical population data: $e');
      }
      return [];
    }
  }
}

/// Population History Point für Charts
class PopulationHistoryPoint {
  final int population;
  final DateTime timestamp;

  PopulationHistoryPoint({
    required this.population,
    required this.timestamp,
  });
}
