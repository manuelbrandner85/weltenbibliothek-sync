import 'package:flutter/material.dart';

/// Enhanced population statistics with detailed demographics
class EnhancedPopulationData {
  final int totalPopulation;
  final DateTime timestamp;
  final int birthsToday;
  final int deathsToday;
  final double growthPerSecond;
  final Map<String, int> byContinent;
  final Map<String, int> byCountry; // Top 20 countries
  final double medianAge;
  final double urbanPopulationPercent;
  final List<PopulationDensityPoint> densityPoints;
  final List<PopulationEvent> recentEvents;
  
  EnhancedPopulationData({
    required this.totalPopulation,
    required this.timestamp,
    required this.birthsToday,
    required this.deathsToday,
    required this.growthPerSecond,
    required this.byContinent,
    required this.byCountry,
    required this.medianAge,
    required this.urbanPopulationPercent,
    required this.densityPoints,
    required this.recentEvents,
  });

  /// Net growth today (births - deaths)
  int get netGrowthToday => birthsToday - deathsToday;

  /// Calculate current population with growth
  int getCurrentPopulation() {
    final secondsSinceTimestamp = DateTime.now().difference(timestamp).inSeconds;
    return (totalPopulation + (growthPerSecond * secondsSinceTimestamp)).toInt();
  }

  /// Calculate births per second
  double get birthsPerSecond => birthsToday / 86400; // 86400 seconds in a day

  /// Calculate deaths per second
  double get deathsPerSecond => deathsToday / 86400;
}

/// Population Density Point for Heatmap
class PopulationDensityPoint {
  final double latitude;
  final double longitude;
  final double density; // people per km²
  final String? cityName;

  PopulationDensityPoint({
    required this.latitude,
    required this.longitude,
    required this.density,
    this.cityName,
  });

  /// Get density category
  String getDensityCategory() {
    if (density < 1000) return 'Niedrig';
    if (density < 5000) return 'Mittel';
    if (density < 10000) return 'Hoch';
    if (density < 20000) return 'Sehr Hoch';
    return 'Extrem';
  }

  /// Get color based on density
  Color getDensityColor() {
    if (density < 1000) return const Color(0xFF90CAF9); // Light blue
    if (density < 5000) return const Color(0xFF42A5F5); // Blue
    if (density < 10000) return const Color(0xFFFFB74D); // Orange
    if (density < 20000) return const Color(0xFFEF5350); // Red
    return const Color(0xFFB71C1C); // Dark red
  }
}

/// Population Event (Birth/Death) for live visualization
class PopulationEvent {
  final PopulationEventType type;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  PopulationEvent({
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });
}

enum PopulationEventType {
  birth,
  death,
}
