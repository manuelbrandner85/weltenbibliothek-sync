import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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

  void dispose() {
    stopMonitoring();
    _issController.close();
    _solarController.close();
  }
}
