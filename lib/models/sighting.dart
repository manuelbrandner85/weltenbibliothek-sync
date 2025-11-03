import 'package:cloud_firestore/cloud_firestore.dart';

enum SightingType {
  lights,
  ufoUap,
  paranormal,
  energyAnomalies,
  sounds,
  dimensionalDisturbances,
}

class Sighting {
  final String id;
  final String userId;
  final String title;
  final String description;
  final SightingType type;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String? locationName;
  final List<String> mediaUrls;
  final int trustScore; // 0-100
  final bool verified;
  final int reportCount;

  Sighting({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.mediaUrls = const [],
    this.trustScore = 50,
    this.verified = false,
    this.reportCount = 1,
  });

  factory Sighting.fromFirestore(Map<String, dynamic> data, String id) {
    return Sighting(
      id: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: SightingType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] as String? ?? ''),
        orElse: () => SightingType.lights,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      locationName: data['locationName'] as String?,
      mediaUrls: List<String>.from(data['mediaUrls'] as List? ?? []),
      trustScore: (data['trustScore'] as num?)?.toInt() ?? 50,
      verified: data['verified'] as bool? ?? false,
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'mediaUrls': mediaUrls,
      'trustScore': trustScore,
      'verified': verified,
      'reportCount': reportCount,
    };
  }

  String get typeEmoji {
    switch (type) {
      case SightingType.lights:
        return '💡';
      case SightingType.ufoUap:
        return '🛸';
      case SightingType.paranormal:
        return '👻';
      case SightingType.energyAnomalies:
        return '⚡';
      case SightingType.sounds:
        return '🔊';
      case SightingType.dimensionalDisturbances:
        return '🌀';
    }
  }

  String get typeName {
    switch (type) {
      case SightingType.lights:
        return 'Lichter';
      case SightingType.ufoUap:
        return 'UFO/UAP';
      case SightingType.paranormal:
        return 'Paranormal';
      case SightingType.energyAnomalies:
        return 'Energie-Anomalien';
      case SightingType.sounds:
        return 'Geräusche';
      case SightingType.dimensionalDisturbances:
        return 'Dimensionale Störungen';
    }
  }
}
