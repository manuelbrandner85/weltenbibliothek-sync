import '../models/historical_event.dart';

// Import all category modules
import 'categories/lost_civilizations_events.dart';
import 'categories/alien_contact_events.dart';
import 'categories/secret_societies_events.dart';
import 'categories/tech_mysteries_events.dart';
import 'categories/dimensional_anomalies_events.dart';
import 'categories/occult_events.dart';
import 'categories/forbidden_knowledge_events.dart';
import 'categories/ufo_fleets_events.dart';
import 'categories/energy_phenomena_events.dart';
import 'categories/global_conspiracies_events.dart';

/// Massive Events Database - Über 160 mystische Ereignisse aus 10 Kategorien
/// Zeitspanne: 25.000 v.Chr. bis 2025 n.Chr.
/// 
/// 📚 Kategorien:
/// - Lost Civilizations: Versunkene Kulturen (11 Events)
/// - Alien Contact: UFO-Sichtungen & Entführungen (20 Events)
/// - Secret Societies: Geheimbünde & Machtstrukturen (20 Events)
/// - Tech Mysteries: Unerklärliche Technologien (20 Events)
/// - Dimensional Anomalies: Portale & Anomalien (15 Events)
/// - Occult Events: Okkultismus & Paranormales (15 Events)
/// - Forbidden Knowledge: Verborgenes Wissen (15 Events)
/// - UFO Fleets: Massen-UFO-Sichtungen (15 Events)
/// - Energy Phenomena: Energie-Phänomene (15 Events)
/// - Global Conspiracies: Weltweite Verschwörungen (15 Events)
///
/// Total: ~161 Events
class MassiveEventsData {
  /// Lädt ALLE Events aus allen Kategorien
  static List<HistoricalEvent> getAllEvents() {
    final allEvents = <HistoricalEvent>[];
    
    // Lost Civilizations (11 events)
    allEvents.addAll(LostCivilizationsEvents.getEvents());
    
    // Alien Contact (20 events)
    allEvents.addAll(AlienContactEvents.getEvents());
    
    // Secret Societies (20 events)
    allEvents.addAll(SecretSocietiesEvents.getEvents());
    
    // Tech Mysteries (20 events)
    allEvents.addAll(TechMysteriesEvents.getEvents());
    
    // Dimensional Anomalies (15 events)
    allEvents.addAll(DimensionalAnomaliesEvents.getEvents());
    
    // Occult Events (15 events)
    allEvents.addAll(OccultEventsData.getEvents());
    
    // Forbidden Knowledge (15 events)
    allEvents.addAll(ForbiddenKnowledgeEvents.getEvents());
    
    // UFO Fleets (15 events)
    allEvents.addAll(UfoFleetsEvents.getEvents());
    
    // Energy Phenomena (15 events)
    allEvents.addAll(EnergyPhenomenaEvents.getEvents());
    
    // Global Conspiracies (15 events)
    allEvents.addAll(GlobalConspiraciesEvents.getEvents());
    
    // Sortiere nach Datum (älteste zuerst)
    allEvents.sort((a, b) => a.date.compareTo(b.date));
    
    return allEvents;
  }
  
  /// Lädt Events einer spezifischen Kategorie
  static List<HistoricalEvent> getEventsByCategory(EventCategory category) {
    switch (category) {
      case EventCategory.lostCivilizations:
        return LostCivilizationsEvents.getEvents();
      case EventCategory.alienContact:
        return AlienContactEvents.getEvents();
      case EventCategory.secretSocieties:
        return SecretSocietiesEvents.getEvents();
      case EventCategory.techMysteries:
        return TechMysteriesEvents.getEvents();
      case EventCategory.dimensionalAnomalies:
        return DimensionalAnomaliesEvents.getEvents();
      case EventCategory.occultEvents:
        return OccultEventsData.getEvents();
      case EventCategory.forbiddenKnowledge:
        return ForbiddenKnowledgeEvents.getEvents();
      case EventCategory.ufoFleets:
        return UfoFleetsEvents.getEvents();
      case EventCategory.energyPhenomena:
        return EnergyPhenomenaEvents.getEvents();
      case EventCategory.globalConspiracies:
        return GlobalConspiraciesEvents.getEvents();
    }
  }
  
  /// Statistiken über die Datenbank
  static Map<String, dynamic> getStatistics() {
    final allEvents = getAllEvents();
    
    return {
      'total_events': allEvents.length,
      'earliest_event': allEvents.first.date,
      'latest_event': allEvents.last.date,
      'timespan_years': allEvents.last.date.year - allEvents.first.date.year,
      'categories': {
        'lost_civilizations': LostCivilizationsEvents.getEvents().length,
        'alien_contact': AlienContactEvents.getEvents().length,
        'secret_societies': SecretSocietiesEvents.getEvents().length,
        'tech_mysteries': TechMysteriesEvents.getEvents().length,
        'dimensional_anomalies': DimensionalAnomaliesEvents.getEvents().length,
        'occult_events': OccultEventsData.getEvents().length,
        'forbidden_knowledge': ForbiddenKnowledgeEvents.getEvents().length,
        'ufo_fleets': UfoFleetsEvents.getEvents().length,
        'energy_phenomena': EnergyPhenomenaEvents.getEvents().length,
        'global_conspiracies': GlobalConspiraciesEvents.getEvents().length,
      },
    };
  }
}
