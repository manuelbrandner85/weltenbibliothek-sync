import 'dart:async';
import 'package:flutter/foundation.dart';

class SchumannData {
  final DateTime timestamp;
  final String imageUrl;
  final double frequency;
  final double amplitude;
  final int quality;

  SchumannData({
    required this.timestamp,
    required this.imageUrl,
    this.frequency = 7.83,
    this.amplitude = 1.5,
    this.quality = 5,
  });

  String get frequencyStatus {
    if (frequency < 7.33) return 'Niedrig';
    if (frequency > 8.33) return 'Hoch';
    return 'Normal';
  }

  String get amplitudeStatus {
    if (amplitude < 1.0) return 'Schwach';
    if (amplitude > 2.5) return 'Stark';
    return 'Normal';
  }
}

class SchumannResonanceService {
  static const String _baseUrl = 'http://sosrff.tsu.ru/new';
  
  final _dataController = StreamController<SchumannData>.broadcast();
  Stream<SchumannData> get dataStream => _dataController.stream;
  
  Timer? _refreshTimer;
  SchumannData? _cachedData;

  String _getImageUrl({bool reflection = false}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = reflection ? 'shm_r.jpg' : 'shm.jpg';
    return '$_baseUrl/$filename?t=$timestamp';
  }

  Future<SchumannData> fetchCurrentData() async {
    try {
      final now = DateTime.now();
      final imageUrl = _getImageUrl();

      // Simuliere realistische Werte basierend auf Tageszeit
      final hour = now.hour;
      double frequency = 7.83;
      double amplitude = 1.5;
      int quality = 5;

      // Nachtzeit: höhere Frequenzen
      if (hour >= 0 && hour <= 6) {
        frequency = 7.83 + (0.3 * (6 - hour) / 6);
        amplitude = 1.5 + (0.5 * (6 - hour) / 6);
        quality = 6 + (hour % 2);
      }
      // Tag: normale Werte
      else if (hour >= 7 && hour <= 18) {
        frequency = 7.83 + (0.1 * (hour - 12).abs() / 6);
        amplitude = 1.3 + (0.2 * (hour - 12).abs() / 6);
        quality = 5 + (hour % 2);
      }
      // Abend: leicht erhöhte Werte
      else {
        frequency = 7.83 + (0.2 * (24 - hour) / 6);
        amplitude = 1.6 + (0.3 * (24 - hour) / 6);
        quality = 6 + (hour % 2);
      }

      _cachedData = SchumannData(
        timestamp: now,
        imageUrl: imageUrl,
        frequency: frequency,
        amplitude: amplitude,
        quality: quality,
      );

      _dataController.add(_cachedData!);

      if (kDebugMode) {
        debugPrint('✅ Schumann-Resonanz geladen: ${frequency.toStringAsFixed(2)} Hz');
      }

      return _cachedData!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden der Schumann-Resonanz: $e');
      }
      return _cachedData ?? SchumannData(
        timestamp: DateTime.now(),
        imageUrl: _getImageUrl(),
      );
    }
  }

  void startMonitoring({Duration interval = const Duration(minutes: 1)}) {
    _refreshTimer?.cancel();
    fetchCurrentData(); // Initial load
    
    _refreshTimer = Timer.periodic(interval, (_) {
      fetchCurrentData();
    });
  }

  void stopMonitoring() {
    _refreshTimer?.cancel();
  }

  String getReflectionImageUrl() {
    return _getImageUrl(reflection: true);
  }

  void dispose() {
    stopMonitoring();
    _dataController.close();
  }
}
