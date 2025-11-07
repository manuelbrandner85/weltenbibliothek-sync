import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

/// v2.33.0 - Kiruna Magnetometer Live Data Service
/// 
/// Lädt LIVE-Daten vom Kiruna Suspended Magnetometer (IRF Sweden)
/// Update: Alle 5 Minuten automatisch
/// Datenquelle: Swedish Institute of Space Physics (IRF)
class KirunaMagnetometerService {
  static final KirunaMagnetometerService _instance = KirunaMagnetometerService._internal();
  factory KirunaMagnetometerService() => _instance;
  KirunaMagnetometerService._internal();

  // Live Data URLs (IRF Sweden)
  static const String _baseUrl = 'https://www2.irf.se/maggraphs';
  
  // Primary DTU Suspended Magnetometer (Live Data)
  static const String _lastHour1SecUrl = '$_baseUrl/rt_last_hour_1sec_primary.csv';
  static const String _lastHour1MinUrl = '$_baseUrl/rt_last_hour_1min_primary.csv';
  
  // Secondary Magnetometer (for comparison)
  static const String _lastHour1SecSecondaryUrl = '$_baseUrl/rt_iaga_last_hour_1sec_secondary.txt';
  
  // K-Index (Geomagnetic Activity)
  static const String _kIndexUrl = '$_baseUrl/preliminary_real_time_k_index_secondary';
  
  // Live Magnetogram Image
  static const String _quietCurveImageUrl = '$_baseUrl/kiraver.png';
  
  Timer? _autoUpdateTimer;
  DateTime? _lastUpdate;
  KirunaMagnetometerData? _currentData;
  
  final StreamController<KirunaMagnetometerData> _dataStreamController = 
      StreamController<KirunaMagnetometerData>.broadcast();
  
  /// Stream für Live-Updates
  Stream<KirunaMagnetometerData> get dataStream => _dataStreamController.stream;
  
  /// Aktuelle Daten
  KirunaMagnetometerData? get currentData => _currentData;
  
  /// Letzte Update-Zeit
  DateTime? get lastUpdate => _lastUpdate;

  /// Starte Auto-Update (alle 5 Minuten)
  void startAutoUpdate() {
    stopAutoUpdate();
    
    // Initiales Laden
    fetchLiveData();
    
    // Auto-Update alle 5 Minuten
    _autoUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      debugPrint('🔄 Auto-Update: Kiruna Magnetometer');
      fetchLiveData();
    });
    
    debugPrint('✅ Kiruna Auto-Update gestartet (alle 5 Min)');
  }

  /// Stoppe Auto-Update
  void stopAutoUpdate() {
    _autoUpdateTimer?.cancel();
    _autoUpdateTimer = null;
    debugPrint('⏹️  Kiruna Auto-Update gestoppt');
  }

  /// Lade Live-Daten
  Future<KirunaMagnetometerData?> fetchLiveData() async {
    try {
      debugPrint('📡 Lade Kiruna Magnetometer Live-Daten...');
      
      // Lade 1-Sekunden Daten (letzte Stunde)
      final response = await http.get(Uri.parse(_lastHour1SecUrl))
          .timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200) {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        return null;
      }

      // Parse CSV Daten
      final data = _parsePrimaryCSV(response.body);
      
      if (data != null) {
        _currentData = data;
        _lastUpdate = DateTime.now();
        _dataStreamController.add(data);
        
        debugPrint('✅ Kiruna Daten geladen: ${data.dataPoints.length} Punkte');
        return data;
      }
      
      return null;
      
    } catch (e) {
      debugPrint('❌ Kiruna Fetch Error: $e');
      return null;
    }
  }

  /// Parse Primary DTU CSV Format
  KirunaMagnetometerData? _parsePrimaryCSV(String csvData) {
    try {
      final lines = csvData.split('\n');
      final dataPoints = <MagnetometerDataPoint>[];
      
      // Header überspringen (erste Zeile)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final parts = line.split(',');
        if (parts.length < 4) continue;
        
        try {
          // Format: timestamp,X,Y,Z
          final timestamp = DateTime.parse(parts[0].trim());
          final x = double.parse(parts[1].trim());
          final y = double.parse(parts[2].trim());
          final z = double.parse(parts[3].trim());
          
          dataPoints.add(MagnetometerDataPoint(
            timestamp: timestamp,
            x: x,
            y: y,
            z: z,
          ));
          
        } catch (e) {
          // Parse-Fehler überspringen
          continue;
        }
      }
      
      if (dataPoints.isEmpty) {
        debugPrint('⚠️  Keine gültigen Datenpunkte gefunden');
        return null;
      }
      
      // Berechne Statistiken
      final stats = _calculateStatistics(dataPoints);
      
      return KirunaMagnetometerData(
        dataPoints: dataPoints,
        statistics: stats,
        lastUpdate: DateTime.now(),
        source: 'IRF Kiruna Primary DTU Suspended Magnetometer',
      );
      
    } catch (e) {
      debugPrint('❌ CSV Parse Error: $e');
      return null;
    }
  }

  /// Berechne Statistiken
  MagnetometerStatistics _calculateStatistics(List<MagnetometerDataPoint> points) {
    if (points.isEmpty) {
      return MagnetometerStatistics(
        xMin: 0, xMax: 0, xAvg: 0,
        yMin: 0, yMax: 0, yAvg: 0,
        zMin: 0, zMax: 0, zAvg: 0,
        totalFieldMin: 0, totalFieldMax: 0, totalFieldAvg: 0,
      );
    }
    
    double xMin = points[0].x, xMax = points[0].x, xSum = 0;
    double yMin = points[0].y, yMax = points[0].y, ySum = 0;
    double zMin = points[0].z, zMax = points[0].z, zSum = 0;
    double totalFieldMin = points[0].totalField, totalFieldMax = points[0].totalField, totalFieldSum = 0;
    
    for (final point in points) {
      // X
      if (point.x < xMin) xMin = point.x;
      if (point.x > xMax) xMax = point.x;
      xSum += point.x;
      
      // Y
      if (point.y < yMin) yMin = point.y;
      if (point.y > yMax) yMax = point.y;
      ySum += point.y;
      
      // Z
      if (point.z < zMin) zMin = point.z;
      if (point.z > zMax) zMax = point.z;
      zSum += point.z;
      
      // Total Field
      final tf = point.totalField;
      if (tf < totalFieldMin) totalFieldMin = tf;
      if (tf > totalFieldMax) totalFieldMax = tf;
      totalFieldSum += tf;
    }
    
    final count = points.length;
    
    return MagnetometerStatistics(
      xMin: xMin, xMax: xMax, xAvg: xSum / count,
      yMin: yMin, yMax: yMax, yAvg: ySum / count,
      zMin: zMin, zMax: zMax, zAvg: zSum / count,
      totalFieldMin: totalFieldMin,
      totalFieldMax: totalFieldMax,
      totalFieldAvg: totalFieldSum / count,
    );
  }

  /// Hole K-Index (Geomagnetische Aktivität)
  Future<int?> fetchKIndex() async {
    try {
      final response = await http.get(Uri.parse(_kIndexUrl))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Parse K-Index aus Response
        final text = response.body.trim();
        final match = RegExp(r':\s*(\d+)').firstMatch(text);
        if (match != null) {
          final kIndex = int.parse(match.group(1)!);
          debugPrint('✅ K-Index: $kIndex');
          return kIndex;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ K-Index Error: $e');
      return null;
    }
  }

  /// Hole Magnetogram Image URL (mit Cache-Buster)
  String getMagnetogramImageUrl() {
    // Füge Timestamp hinzu um Caching zu verhindern
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$_quietCurveImageUrl?t=$timestamp';
  }

  void dispose() {
    stopAutoUpdate();
    _dataStreamController.close();
  }
}

/// Magnetometer Datenpunkt
class MagnetometerDataPoint {
  final DateTime timestamp;
  final double x;  // Nord-Süd Komponente (nT)
  final double y;  // Ost-West Komponente (nT)
  final double z;  // Vertikal Komponente (nT)
  
  MagnetometerDataPoint({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
  });
  
  /// Berechne Gesamtfeld-Stärke
  double get totalField => _calculateMagnitude(x, y, z);
  
  double _calculateMagnitude(double x, double y, double z) {
    return (x * x + y * y + z * z);
  }
}

/// Magnetometer Statistiken
class MagnetometerStatistics {
  final double xMin, xMax, xAvg;
  final double yMin, yMax, yAvg;
  final double zMin, zMax, zAvg;
  final double totalFieldMin, totalFieldMax, totalFieldAvg;
  
  MagnetometerStatistics({
    required this.xMin, required this.xMax, required this.xAvg,
    required this.yMin, required this.yMax, required this.yAvg,
    required this.zMin, required this.zMax, required this.zAvg,
    required this.totalFieldMin, required this.totalFieldMax, required this.totalFieldAvg,
  });
}

/// Kiruna Magnetometer Daten
class KirunaMagnetometerData {
  final List<MagnetometerDataPoint> dataPoints;
  final MagnetometerStatistics statistics;
  final DateTime lastUpdate;
  final String source;
  
  KirunaMagnetometerData({
    required this.dataPoints,
    required this.statistics,
    required this.lastUpdate,
    required this.source,
  });
  
  /// Hole letzte X Minuten Daten
  List<MagnetometerDataPoint> getLastMinutes(int minutes) {
    final cutoff = DateTime.now().subtract(Duration(minutes: minutes));
    return dataPoints.where((p) => p.timestamp.isAfter(cutoff)).toList();
  }
}
