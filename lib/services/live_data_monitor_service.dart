import 'dart:async';
import 'package:flutter/foundation.dart';
import 'live_data_service.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';

/// Service for monitoring live data and triggering alerts when thresholds are exceeded
class LiveDataMonitorService {
  static final LiveDataMonitorService _instance = LiveDataMonitorService._internal();
  factory LiveDataMonitorService() => _instance;
  LiveDataMonitorService._internal();

  final LiveDataService _liveDataService = LiveDataService();
  final NotificationService _notificationService = NotificationService();

  Timer? _monitorTimer;
  bool _isMonitoring = false;

  // Last alert timestamps to prevent spam
  DateTime? _lastEarthquakeAlert;
  DateTime? _lastVolcanoAlert;
  DateTime? _lastSolarStormAlert;
  DateTime? _lastSchumannAlert;

  /// Start monitoring live data
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    debugPrint('🔍 Live Data Monitoring STARTED');

    // Check every 5 minutes
    _monitorTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _checkAllThresholds();
    });

    // Initial check
    await _checkAllThresholds();
  }

  /// Stop monitoring
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;
    debugPrint('🛑 Live Data Monitoring STOPPED');
  }

  /// Check all thresholds and send alerts
  Future<void> _checkAllThresholds() async {
    try {
      final settings = await _notificationService.getSettings();

      // Get latest live data
      final earthquakes = await _liveDataService.getEarthquakes();
      final schumann = await _liveDataService.getSchumannResonance();
      final solarActivity = await _liveDataService.getSolarActivity();

      // Check each threshold
      if (settings.enableEarthquakes) {
        await _checkEarthquakes(earthquakes, settings.earthquakeMagnitude);
      }

      if (settings.enableSchumannSpikes) {
        await _checkSchumann(schumann, settings.schumannThreshold);
      }

      if (settings.enableSolarStorms) {
        await _checkSolarStorms(solarActivity, settings.solarStormKpIndex);
      }

      debugPrint('✅ Threshold check completed');
    } catch (e) {
      debugPrint('❌ Error checking thresholds: $e');
    }
  }

  /// Check earthquake threshold
  Future<void> _checkEarthquakes(List<EarthquakeData> earthquakes, double threshold) async {
    // Only alert once per hour for same magnitude range
    if (_lastEarthquakeAlert != null &&
        DateTime.now().difference(_lastEarthquakeAlert!) < const Duration(hours: 1)) {
      return;
    }

    // Find significant earthquakes
    final significant = earthquakes.where((eq) => eq.magnitude >= threshold).toList();

    if (significant.isEmpty) return;

    // Get strongest earthquake
    significant.sort((a, b) => b.magnitude.compareTo(a.magnitude));
    final strongest = significant.first;

    // Send alert
    await _notificationService.showLocalNotification(
      title: '🌊 Erdbeben-Alarm!',
      body: 'Magnitude ${strongest.magnitude.toStringAsFixed(1)} in ${strongest.place}',
      payload: 'earthquake:${strongest.id}',
    );

    _lastEarthquakeAlert = DateTime.now();
    debugPrint('🚨 Earthquake alert sent: ${strongest.magnitude}');
  }

  /// Check Schumann Resonance threshold
  Future<void> _checkSchumann(SchumannResonance schumann, double threshold) async {
    // Only alert once per 2 hours
    if (_lastSchumannAlert != null &&
        DateTime.now().difference(_lastSchumannAlert!) < const Duration(hours: 2)) {
      return;
    }

    if (schumann.currentValue >= threshold) {
      // Send alert
      await _notificationService.showLocalNotification(
        title: '⚡ Schumann-Resonanz Anomalie!',
        body: 'Aktuelle Frequenz: ${schumann.currentValue.toStringAsFixed(2)} Hz (Normal: 7.83 Hz)',
        payload: 'schumann:spike',
      );

      _lastSchumannAlert = DateTime.now();
      debugPrint('🚨 Schumann spike alert sent: ${schumann.currentValue} Hz');
    }
  }

  /// Check solar storm threshold
  Future<void> _checkSolarStorms(List<SolarActivity> solarActivity, int kpThreshold) async {
    // Only alert once per 3 hours
    if (_lastSolarStormAlert != null &&
        DateTime.now().difference(_lastSolarStormAlert!) < const Duration(hours: 3)) {
      return;
    }

    if (solarActivity.isEmpty) return;

    // Check latest solar activity
    final latest = solarActivity.last;
    
    // Simulate KP index from solar flux (real API would provide actual KP)
    final estimatedKp = (latest.intensity / 1e-6).clamp(0, 9).toInt();

    if (estimatedKp >= kpThreshold) {
      // Send alert
      await _notificationService.showLocalNotification(
        title: '☀️ Geomagnetischer Sturm!',
        body: 'KP-Index: $estimatedKp - Erhöhte Sonnenaktivität detektiert',
        payload: 'solar:storm',
      );

      _lastSolarStormAlert = DateTime.now();
      debugPrint('🚨 Solar storm alert sent: KP $estimatedKp');
    }
  }

  /// Manual threshold check (for testing)
  Future<void> checkNow() async {
    debugPrint('🔍 Manual threshold check triggered');
    await _checkAllThresholds();
  }

  /// Get monitoring status
  bool get isMonitoring => _isMonitoring;
}
