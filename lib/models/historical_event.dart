import 'package:cloud_firestore/cloud_firestore.dart';

enum EventCategory {
  lostCivilizations,
  alienContact,
  secretSocieties,
  techMysteries,
  dimensionalAnomalies,
  occultEvents,
  forbiddenKnowledge,
  ufoFleets,
  energyPhenomena,
  globalConspiracies,
}

enum PerspectiveType {
  mainstream,
  alternative,
  conspiracy,
  spiritual,
  scientific,
}

class HistoricalEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final EventCategory category;
  final List<PerspectiveType> perspectives;
  final List<String> sources;
  final int trustLevel; // 1-5
  final List<String> mediaUrls;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final Map<String, dynamic>? additionalData;

  HistoricalEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    required this.perspectives,
    required this.sources,
    required this.trustLevel,
    this.mediaUrls = const [],
    this.latitude,
    this.longitude,
    this.locationName,
    this.additionalData,
  });

  factory HistoricalEvent.fromFirestore(Map<String, dynamic> data, String id) {
    return HistoricalEvent(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: EventCategory.values.firstWhere(
        (e) => e.toString().split('.').last == (data['category'] as String? ?? ''),
        orElse: () => EventCategory.lostCivilizations,
      ),
      perspectives: ((data['perspectives'] as List?) ?? [])
          .map((p) => PerspectiveType.values.firstWhere(
                (e) => e.toString().split('.').last == p,
                orElse: () => PerspectiveType.mainstream,
              ))
          .toList(),
      sources: List<String>.from(data['sources'] as List? ?? []),
      trustLevel: (data['trustLevel'] as num?)?.toInt() ?? 1,
      mediaUrls: List<String>.from(data['mediaUrls'] as List? ?? []),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      locationName: data['locationName'] as String?,
      additionalData: data['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'category': category.toString().split('.').last,
      'perspectives': perspectives.map((p) => p.toString().split('.').last).toList(),
      'sources': sources,
      'trustLevel': trustLevel,
      'mediaUrls': mediaUrls,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'additionalData': additionalData,
    };
  }

  String get categoryEmoji {
    switch (category) {
      case EventCategory.lostCivilizations:
        return '🏛️';
      case EventCategory.alienContact:
        return '👽';
      case EventCategory.secretSocieties:
        return '🔺';
      case EventCategory.techMysteries:
        return '📡';
      case EventCategory.dimensionalAnomalies:
        return '🌀';
      case EventCategory.occultEvents:
        return '🔮';
      case EventCategory.forbiddenKnowledge:
        return '📜';
      case EventCategory.ufoFleets:
        return '🛸';
      case EventCategory.energyPhenomena:
        return '⚡';
      case EventCategory.globalConspiracies:
        return '🌍';
    }
  }

  String get categoryName {
    switch (category) {
      case EventCategory.lostCivilizations:
        return 'Verlorene Zivilisationen';
      case EventCategory.alienContact:
        return 'Außerirdische Kontakte';
      case EventCategory.secretSocieties:
        return 'Geheimgesellschaften';
      case EventCategory.techMysteries:
        return 'Technologie-Mysterien';
      case EventCategory.dimensionalAnomalies:
        return 'Dimensionale Anomalien';
      case EventCategory.occultEvents:
        return 'Okkulte Ereignisse';
      case EventCategory.forbiddenKnowledge:
        return 'Verbotenes Wissen';
      case EventCategory.ufoFleets:
        return 'UFO-Flotten';
      case EventCategory.energyPhenomena:
        return 'Energiephänomene';
      case EventCategory.globalConspiracies:
        return 'Globale Verschwörungen';
    }
  }
}
