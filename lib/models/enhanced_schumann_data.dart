import 'package:flutter/foundation.dart';

/// Enhanced Schumann Resonance data with historical trends and analysis
class EnhancedSchumannData {
  final double currentFrequency;
  final double currentAmplitude;
  final double currentQuality;
  final DateTime timestamp;
  final List<SchumannDataPoint> history24h;
  final List<SchumannDataPoint> history7d;
  final List<SchumannDataPoint> history30d;
  final SchumannTrend trend;
  final AnomalyLevel anomalyLevel;
  final List<double> harmonics; // [7.83, 14.1, 20.3, 26.4, 32.5] Hz
  final Map<String, double> correlations;
  
  EnhancedSchumannData({
    required this.currentFrequency,
    required this.currentAmplitude,
    required this.currentQuality,
    required this.timestamp,
    required this.history24h,
    required this.history7d,
    required this.history30d,
    required this.trend,
    required this.anomalyLevel,
    required this.harmonics,
    required this.correlations,
  });

  /// Normal Schumann base frequency
  static const double baseFrequency = 7.83;

  /// Get deviation from base frequency
  double get deviation => currentFrequency - baseFrequency;

  /// Get percentage deviation
  double get deviationPercent => (deviation / baseFrequency) * 100;

  /// Check if currently in anomaly state
  bool get isAnomaly => anomalyLevel != AnomalyLevel.normal;

  /// Get peak value in last 24h
  double get peak24h {
    if (history24h.isEmpty) return currentFrequency;
    return history24h.map((p) => p.frequency).reduce((a, b) => a > b ? a : b);
  }

  /// Get average value in last 24h
  double get average24h {
    if (history24h.isEmpty) return currentFrequency;
    final sum = history24h.map((p) => p.frequency).reduce((a, b) => a + b);
    return sum / history24h.length;
  }

  /// Get trend direction as string
  String get trendDirection {
    switch (trend) {
      case SchumannTrend.rising:
        return 'Steigend';
      case SchumannTrend.falling:
        return 'Fallend';
      case SchumannTrend.stable:
        return 'Stabil';
      case SchumannTrend.volatile:
        return 'Volatil';
    }
  }

  /// Get anomaly level description
  String get anomalyDescription {
    switch (anomalyLevel) {
      case AnomalyLevel.normal:
        return 'Normal (${baseFrequency.toStringAsFixed(2)} Hz)';
      case AnomalyLevel.low:
        return 'Leicht erhöht';
      case AnomalyLevel.moderate:
        return 'Mäßig erhöht';
      case AnomalyLevel.high:
        return 'Stark erhöht';
      case AnomalyLevel.extreme:
        return 'Extrem - Anomalie!';
    }
  }

  /// Get color for anomaly level
  String get anomalyColor {
    switch (anomalyLevel) {
      case AnomalyLevel.normal:
        return '#4CAF50'; // Green
      case AnomalyLevel.low:
        return '#8BC34A'; // Light Green
      case AnomalyLevel.moderate:
        return '#FFC107'; // Amber
      case AnomalyLevel.high:
        return '#FF9800'; // Orange
      case AnomalyLevel.extreme:
        return '#F44336'; // Red
    }
  }

  /// Calculate trend from historical data
  static SchumannTrend calculateTrend(List<SchumannDataPoint> history) {
    if (history.length < 10) return SchumannTrend.stable;

    // Calculate linear regression slope
    final recentData = history.length > 20 ? history.sublist(history.length - 20) : history;
    
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < recentData.length; i++) {
      sumX += i;
      sumY += recentData[i].frequency;
      sumXY += i * recentData[i].frequency;
      sumX2 += i * i;
    }
    
    final n = recentData.length;
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    
    // Calculate volatility (standard deviation)
    final mean = sumY / n;
    final variance = recentData
        .map((p) => (p.frequency - mean) * (p.frequency - mean))
        .reduce((a, b) => a + b) / n;
    final stdDev = _sqrt(variance);
    
    // Determine trend
    if (stdDev > 2.0) {
      return SchumannTrend.volatile;
    } else if (slope > 0.1) {
      return SchumannTrend.rising;
    } else if (slope < -0.1) {
      return SchumannTrend.falling;
    } else {
      return SchumannTrend.stable;
    }
  }

  /// Simple square root approximation
  static double _sqrt(double x) {
    if (x < 0) return 0;
    double result = x;
    double lastResult;
    do {
      lastResult = result;
      result = (result + x / result) / 2;
    } while ((result - lastResult).abs() > 0.0001);
    return result;
  }
}

/// Single data point for historical tracking
class SchumannDataPoint {
  final double frequency;
  final double amplitude;
  final double quality;
  final DateTime timestamp;

  SchumannDataPoint({
    required this.frequency,
    required this.amplitude,
    required this.quality,
    required this.timestamp,
  });

  /// Format timestamp for display
  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Format date for display
  String get formattedDate {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    return '$day.$month';
  }
}

/// Trend direction for Schumann frequency
enum SchumannTrend {
  rising,    // Frequency increasing
  falling,   // Frequency decreasing
  stable,    // Relatively constant
  volatile,  // High fluctuation
}

/// Anomaly severity levels
enum AnomalyLevel {
  normal,    // 7.5 - 8.5 Hz
  low,       // 8.5 - 10 Hz
  moderate,  // 10 - 15 Hz
  high,      // 15 - 20 Hz
  extreme,   // > 20 Hz
}

/// Calculate anomaly level from frequency
AnomalyLevel getAnomalyLevel(double frequency) {
  if (frequency < 8.5) {
    return AnomalyLevel.normal;
  } else if (frequency < 10.0) {
    return AnomalyLevel.low;
  } else if (frequency < 15.0) {
    return AnomalyLevel.moderate;
  } else if (frequency < 20.0) {
    return AnomalyLevel.high;
  } else {
    return AnomalyLevel.extreme;
  }
}
