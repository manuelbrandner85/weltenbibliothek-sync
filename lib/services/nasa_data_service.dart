import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ISSData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double velocity;
  final DateTime timestamp;

  ISSData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.velocity,
    required this.timestamp,
  });

  factory ISSData.fromJson(Map<String, dynamic> json) {
    final position = json['iss_position'] as Map<String, dynamic>;
    return ISSData(
      latitude: double.parse(position['latitude'] as String),
      longitude: double.parse(position['longitude'] as String),
      altitude: 408.0, // Durchschnittliche ISS-Höhe in km
      velocity: 27600.0, // Durchschnittliche ISS-Geschwindigkeit in km/h
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] as num).toInt() * 1000,
      ),
    );
  }
}

class SolarData {
  final double solarFlux;
  final int kIndex;
  final int sunspotNumber;
  final String stormLevel;
  final DateTime timestamp;

  SolarData({
    required this.solarFlux,
    required this.kIndex,
    required this.sunspotNumber,
    required this.stormLevel,
    required this.timestamp,
  });

  String get activityLevel {
    if (kIndex <= 2) return 'Ruhig';
    if (kIndex <= 4) return 'Unruhig';
    if (kIndex <= 6) return 'Aktiv';
    return 'Sturm';
  }

  bool get isStormWarning => kIndex >= 5;
}

class NASADataService {
  static const String _issApiUrl = 'http://api.open-notify.org/iss-now.json';
  
  final _issController = StreamController<ISSData>.broadcast();
  Stream<ISSData> get issStream => _issController.stream;
  
  final _solarController = StreamController<SolarData>.broadcast();
  Stream<SolarData> get solarStream => _solarController.stream;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Timer? _issTimer;
  Timer? _solarTimer;
  
  ISSData? _cachedISSData;
  SolarData? _cachedSolarData;

  Future<ISSData> fetchISSPosition() async {
    try {
      final response = await http.get(Uri.parse(_issApiUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _cachedISSData = ISSData.fromJson(data);
        
        // ✅ NEU: Speichere ISS-Position in Firestore
        await _saveISSToFirestore(_cachedISSData!);
        
        _issController.add(_cachedISSData!);
        
        if (kDebugMode) {
          debugPrint('✅ ISS Position geladen: ${_cachedISSData!.latitude.toStringAsFixed(2)}, ${_cachedISSData!.longitude.toStringAsFixed(2)}');
        }

        return _cachedISSData!;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden der ISS-Position: $e');
      }
      return _cachedISSData ?? ISSData(
        latitude: 0,
        longitude: 0,
        altitude: 408,
        velocity: 27600,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<SolarData> fetchSolarActivity() async {
    try {
      // Simuliere realistische Sonnendaten
      final now = DateTime.now();
      final random = now.millisecond % 100;
      
      _cachedSolarData = SolarData(
        solarFlux: 120.0 + (random % 30),
        kIndex: (random % 7) + 1,
        sunspotNumber: 50 + (random % 100),
        stormLevel: (random % 7) >= 5 ? 'G1' : 'None',
        timestamp: now,
      );

      // ✅ NEU: Speichere Solar-Daten in Firestore
      // ⚠️ WARNUNG: Diese Daten sind simuliert, nicht von echter API
      await _saveSolarToFirestore(_cachedSolarData!);

      _solarController.add(_cachedSolarData!);
      
      if (kDebugMode) {
        debugPrint('✅ Sonnenaktivität geladen: K-Index ${_cachedSolarData!.kIndex}');
      }

      return _cachedSolarData!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden der Sonnenaktivität: $e');
      }
      return _cachedSolarData ?? SolarData(
        solarFlux: 120,
        kIndex: 3,
        sunspotNumber: 50,
        stormLevel: 'None',
        timestamp: DateTime.now(),
      );
    }
  }

  void startISSMonitoring({Duration interval = const Duration(seconds: 10)}) {
    _issTimer?.cancel();
    fetchISSPosition(); // Initial load
    
    _issTimer = Timer.periodic(interval, (_) {
      fetchISSPosition();
    });
  }

  void startSolarMonitoring({Duration interval = const Duration(minutes: 15)}) {
    _solarTimer?.cancel();
    fetchSolarActivity(); // Initial load
    
    _solarTimer = Timer.periodic(interval, (_) {
      fetchSolarActivity();
    });
  }

  void stopMonitoring() {
    _issTimer?.cancel();
    _solarTimer?.cancel();
  }

  /// ✅ NEU: Speichere ISS-Position in Firestore
  Future<void> _saveISSToFirestore(ISSData issData) async {
    try {
      await _firestore.collection('nasa_data').add({
        'type': 'iss_position',
        'latitude': issData.latitude,
        'longitude': issData.longitude,
        'altitude': issData.altitude,
        'velocity': issData.velocity,
        'timestamp': Timestamp.fromDate(issData.timestamp),
        'synced_at': FieldValue.serverTimestamp(),
        'source': 'open_notify_api',
      });

      if (kDebugMode) {
        debugPrint('✅ ISS-Daten in Firestore gespeichert');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Speichern ISS-Daten: $e');
      }
    }
  }

  /// ✅ NEU: Speichere Solar-Daten in Firestore
  /// ⚠️ WARNUNG: Diese Daten sind simuliert!
  Future<void> _saveSolarToFirestore(SolarData solarData) async {
    try {
      await _firestore.collection('nasa_data').add({
        'type': 'solar_activity',
        'solar_flux': solarData.solarFlux,
        'k_index': solarData.kIndex,
        'sunspot_number': solarData.sunspotNumber,
        'storm_level': solarData.stormLevel,
        'activity_level': solarData.activityLevel,
        'is_storm_warning': solarData.isStormWarning,
        'timestamp': Timestamp.fromDate(solarData.timestamp),
        'synced_at': FieldValue.serverTimestamp(),
        'source': 'simulated', // ⚠️ Markiert als simuliert
      });

      if (kDebugMode) {
        debugPrint('⚠️  Solar-Daten (simuliert) in Firestore gespeichert');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Speichern Solar-Daten: $e');
      }
    }
  }

  /// Lade NASA-Daten aus Firestore (Echtzeit-Stream)
  Stream<List<ISSData>> getISSDataFromFirestore() {
    return _firestore
        .collection('nasa_data')
        .where('type', isEqualTo: 'iss_position')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ISSData(
          latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
          altitude: (data['altitude'] as num?)?.toDouble() ?? 408.0,
          velocity: (data['velocity'] as num?)?.toDouble() ?? 27600.0,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  void dispose() {
    stopMonitoring();
    _issController.close();
    _solarController.close();
  }
}
