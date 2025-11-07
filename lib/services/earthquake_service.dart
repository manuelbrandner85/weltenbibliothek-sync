import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Earthquake {
  final String id;
  final double magnitude;
  final String place;
  final DateTime time;
  final double latitude;
  final double longitude;
  final double depth;

  Earthquake({
    required this.id,
    required this.magnitude,
    required this.place,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.depth,
  });

  factory Earthquake.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>;
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;

    return Earthquake(
      id: json['id'] as String? ?? '',
      magnitude: (properties['mag'] as num?)?.toDouble() ?? 0.0,
      place: properties['place'] as String? ?? 'Unbekannt',
      time: DateTime.fromMillisecondsSinceEpoch(
        (properties['time'] as num?)?.toInt() ?? 0,
      ),
      longitude: (coordinates[0] as num?)?.toDouble() ?? 0.0,
      latitude: (coordinates[1] as num?)?.toDouble() ?? 0.0,
      depth: (coordinates[2] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get magnitudeCategory {
    if (magnitude < 4.0) return 'Leicht';
    if (magnitude < 6.0) return 'Mittel';
    if (magnitude < 7.0) return 'Stark';
    return 'Sehr Stark';
  }

  bool get isSignificant => magnitude >= 6.0;
}

class EarthquakeService {
  static const String _baseUrl = 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson';
  
  final _earthquakesController = StreamController<List<Earthquake>>.broadcast();
  Stream<List<Earthquake>> get earthquakesStream => _earthquakesController.stream;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Timer? _refreshTimer;
  List<Earthquake> _cachedEarthquakes = [];

  Future<List<Earthquake>> fetchEarthquakes() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl)).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List;

        _cachedEarthquakes = features
            .map((feature) => Earthquake.fromJson(feature as Map<String, dynamic>))
            .toList();

        // Sortiere nach Magnitude (höchste zuerst)
        _cachedEarthquakes.sort((a, b) => b.magnitude.compareTo(a.magnitude));

        // ✅ NEU: Speichere in Firestore für persistente Echtzeit-Daten
        await _saveToFirestore(_cachedEarthquakes);

        _earthquakesController.add(_cachedEarthquakes);
        
        if (kDebugMode) {
          debugPrint('✅ Erdbeben geladen: ${_cachedEarthquakes.length}');
        }

        return _cachedEarthquakes;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden der Erdbeben: $e');
      }
      return _cachedEarthquakes;
    }
  }

  void startMonitoring({Duration interval = const Duration(minutes: 5)}) {
    _refreshTimer?.cancel();
    fetchEarthquakes(); // Initial load
    
    _refreshTimer = Timer.periodic(interval, (_) {
      fetchEarthquakes();
    });
  }

  void stopMonitoring() {
    _refreshTimer?.cancel();
  }

  List<Earthquake> getSignificantEarthquakes() {
    return _cachedEarthquakes.where((eq) => eq.isSignificant).toList();
  }

  /// ✅ NEU: Speichere Erdbeben-Daten in Firestore
  Future<void> _saveToFirestore(List<Earthquake> earthquakes) async {
    try {
      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      // Speichere nur signifikante Erdbeben (Magnitude >= 4.0) für bessere Performance
      final significantQuakes = earthquakes.where((eq) => eq.magnitude >= 4.0).toList();

      for (final quake in significantQuakes) {
        final docRef = _firestore.collection('earthquake_data').doc(quake.id);
        batch.set(docRef, {
          'id': quake.id,
          'magnitude': quake.magnitude,
          'place': quake.place,
          'time': Timestamp.fromDate(quake.time),
          'latitude': quake.latitude,
          'longitude': quake.longitude,
          'depth': quake.depth,
          'magnitude_category': quake.magnitudeCategory,
          'is_significant': quake.isSignificant,
          'synced_at': now,
          'source': 'usgs_api',
        }, SetOptions(merge: true));
      }

      await batch.commit();

      if (kDebugMode) {
        debugPrint('✅ ${significantQuakes.length} Erdbeben in Firestore gespeichert');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Speichern in Firestore: $e');
      }
    }
  }

  /// Lade Erdbeben-Daten aus Firestore (Echtzeit-Stream)
  Stream<List<Earthquake>> getEarthquakesFromFirestore() {
    return _firestore
        .collection('earthquake_data')
        .orderBy('magnitude', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Earthquake(
          id: data['id'] as String? ?? '',
          magnitude: (data['magnitude'] as num?)?.toDouble() ?? 0.0,
          place: data['place'] as String? ?? 'Unbekannt',
          time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
          latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
          depth: (data['depth'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    });
  }

  void dispose() {
    stopMonitoring();
    _earthquakesController.close();
  }
}
