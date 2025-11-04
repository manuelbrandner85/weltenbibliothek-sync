enum NotificationType {
  comment,        // New comment on favorited event
  rating,         // New rating on favorited event
  newEvent,       // New event in favorite category
  earthquake,     // Earthquake alert
  volcano,        // Volcano activity alert
  ufoSighting,    // UFO sighting cluster
  solarStorm,     // Solar storm alert
  schumannSpike,  // Schumann resonance anomaly
}

enum NotificationPriority {
  low,      // Standard notifications
  normal,   // Regular updates
  high,     // Important alerts
  urgent,   // Critical warnings (earthquakes, disasters)
}

class AppNotification {
  final String id;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.body,
    this.data,
    required this.timestamp,
    this.isRead = false,
  });

  /// Get icon for notification type
  String get icon {
    switch (type) {
      case NotificationType.comment:
        return '💬';
      case NotificationType.rating:
        return '⭐';
      case NotificationType.newEvent:
        return '📅';
      case NotificationType.earthquake:
        return '🌊';
      case NotificationType.volcano:
        return '🌋';
      case NotificationType.ufoSighting:
        return '🛸';
      case NotificationType.solarStorm:
        return '☀️';
      case NotificationType.schumannSpike:
        return '⚡';
    }
  }

  /// Get color for notification priority
  String get priorityColor {
    switch (priority) {
      case NotificationPriority.low:
        return '#4A5568';      // Gray
      case NotificationPriority.normal:
        return '#3182CE';      // Blue
      case NotificationPriority.high:
        return '#ED8936';      // Orange
      case NotificationPriority.urgent:
        return '#E53E3E';      // Red
    }
  }

  /// Format time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return 'vor ${difference.inDays} Tag${difference.inDays > 1 ? "en" : ""}';
    } else if (difference.inHours > 0) {
      return 'vor ${difference.inHours} Stunde${difference.inHours > 1 ? "n" : ""}';
    } else if (difference.inMinutes > 0) {
      return 'vor ${difference.inMinutes} Minute${difference.inMinutes > 1 ? "n" : ""}';
    } else {
      return 'gerade eben';
    }
  }
}

/// Notification settings for user preferences
class AppNotificationSettings {
  final bool enableComments;
  final bool enableRatings;
  final bool enableNewEvents;
  final bool enableEarthquakes;
  final bool enableVolcanos;
  final bool enableUfoSightings;
  final bool enableSolarStorms;
  final bool enableSchumannSpikes;
  
  // Thresholds
  final double earthquakeMagnitude;    // Default: 5.0
  final int volcanoActivityLevel;      // Default: 3 (1-5)
  final int ufoSightingThreshold;      // Default: 10 in 24h
  final int solarStormKpIndex;         // Default: 5 (0-9)
  final double schumannThreshold;      // Default: 15.0 Hz (normal is 7.83 Hz)

  AppNotificationSettings({
    this.enableComments = true,
    this.enableRatings = true,
    this.enableNewEvents = true,
    this.enableEarthquakes = true,
    this.enableVolcanos = true,
    this.enableUfoSightings = true,
    this.enableSolarStorms = true,
    this.enableSchumannSpikes = true,
    this.earthquakeMagnitude = 5.0,
    this.volcanoActivityLevel = 3,
    this.ufoSightingThreshold = 10,
    this.solarStormKpIndex = 5,
    this.schumannThreshold = 15.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'enableComments': enableComments,
      'enableRatings': enableRatings,
      'enableNewEvents': enableNewEvents,
      'enableEarthquakes': enableEarthquakes,
      'enableVolcanos': enableVolcanos,
      'enableUfoSightings': enableUfoSightings,
      'enableSolarStorms': enableSolarStorms,
      'enableSchumannSpikes': enableSchumannSpikes,
      'earthquakeMagnitude': earthquakeMagnitude,
      'volcanoActivityLevel': volcanoActivityLevel,
      'ufoSightingThreshold': ufoSightingThreshold,
      'solarStormKpIndex': solarStormKpIndex,
      'schumannThreshold': schumannThreshold,
    };
  }

  factory AppNotificationSettings.fromMap(Map<String, dynamic> map) {
    return AppNotificationSettings(
      enableComments: map['enableComments'] as bool? ?? true,
      enableRatings: map['enableRatings'] as bool? ?? true,
      enableNewEvents: map['enableNewEvents'] as bool? ?? true,
      enableEarthquakes: map['enableEarthquakes'] as bool? ?? true,
      enableVolcanos: map['enableVolcanos'] as bool? ?? true,
      enableUfoSightings: map['enableUfoSightings'] as bool? ?? true,
      enableSolarStorms: map['enableSolarStorms'] as bool? ?? true,
      enableSchumannSpikes: map['enableSchumannSpikes'] as bool? ?? true,
      earthquakeMagnitude: map['earthquakeMagnitude'] as double? ?? 5.0,
      volcanoActivityLevel: map['volcanoActivityLevel'] as int? ?? 3,
      ufoSightingThreshold: map['ufoSightingThreshold'] as int? ?? 10,
      solarStormKpIndex: map['solarStormKpIndex'] as int? ?? 5,
      schumannThreshold: map['schumannThreshold'] as double? ?? 15.0,
    );
  }
}
