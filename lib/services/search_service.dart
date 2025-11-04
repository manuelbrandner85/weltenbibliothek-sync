import '../models/historical_event.dart';

/// Service für Event-Suche mit mehreren Kriterien
class SearchService {
  /// Durchsucht Events nach Query (Name, Ort, Beschreibung)
  static List<HistoricalEvent> searchEvents(
    List<HistoricalEvent> events,
    String query,
  ) {
    if (query.isEmpty) return events;
    
    final lowerQuery = query.toLowerCase();
    
    return events.where((event) {
      // Suche in Titel
      if (event.title.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // Suche in Beschreibung
      if (event.description.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // Suche in Ort
      if (event.locationName?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }
      
      // Suche in Quellen
      if (event.sources.any((source) => source.toLowerCase().contains(lowerQuery))) {
        return true;
      }
      
      return false;
    }).toList();
  }
  
  /// Filtert Events nach Kategorie
  static List<HistoricalEvent> filterByCategory(
    List<HistoricalEvent> events,
    EventCategory? category,
  ) {
    if (category == null) return events;
    return events.where((e) => e.category == category).toList();
  }
  
  /// Filtert Events nach Zeitraum
  static List<HistoricalEvent> filterByDateRange(
    List<HistoricalEvent> events,
    int startYear,
    int endYear,
  ) {
    return events.where((e) {
      final year = e.date.year;
      return year >= startYear && year <= endYear;
    }).toList();
  }
  
  /// Filtert Events nach Trust Level
  static List<HistoricalEvent> filterByTrustLevel(
    List<HistoricalEvent> events,
    int minTrustLevel,
  ) {
    return events.where((e) => e.trustLevel >= minTrustLevel).toList();
  }
  
  /// Sortiert Events nach verschiedenen Kriterien
  static List<HistoricalEvent> sortEvents(
    List<HistoricalEvent> events,
    SortCriteria criteria,
  ) {
    final sortedEvents = List<HistoricalEvent>.from(events);
    
    switch (criteria) {
      case SortCriteria.dateAscending:
        sortedEvents.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortCriteria.dateDescending:
        sortedEvents.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortCriteria.nameAscending:
        sortedEvents.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortCriteria.nameDescending:
        sortedEvents.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SortCriteria.trustLevelDescending:
        sortedEvents.sort((a, b) => b.trustLevel.compareTo(a.trustLevel));
        break;
      case SortCriteria.trustLevelAscending:
        sortedEvents.sort((a, b) => a.trustLevel.compareTo(b.trustLevel));
        break;
    }
    
    return sortedEvents;
  }
  
  /// Kombinierte Suche und Filterung
  static List<HistoricalEvent> advancedSearch({
    required List<HistoricalEvent> events,
    String? query,
    EventCategory? category,
    int? minTrustLevel,
    int? startYear,
    int? endYear,
    SortCriteria? sortBy,
  }) {
    var results = events;
    
    // Textsuche
    if (query != null && query.isNotEmpty) {
      results = searchEvents(results, query);
    }
    
    // Kategorie-Filter
    if (category != null) {
      results = filterByCategory(results, category);
    }
    
    // Trust Level Filter
    if (minTrustLevel != null) {
      results = filterByTrustLevel(results, minTrustLevel);
    }
    
    // Zeitraum-Filter
    if (startYear != null && endYear != null) {
      results = filterByDateRange(results, startYear, endYear);
    }
    
    // Sortierung
    if (sortBy != null) {
      results = sortEvents(results, sortBy);
    }
    
    return results;
  }
}

/// Sortier-Kriterien für Events
enum SortCriteria {
  dateAscending,
  dateDescending,
  nameAscending,
  nameDescending,
  trustLevelAscending,
  trustLevelDescending,
}
