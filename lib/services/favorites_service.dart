import 'package:shared_preferences/shared_preferences.dart';

/// Service für Favoriten-Verwaltung mit SharedPreferences
class FavoritesService {
  static const String _favoritesKey = 'favorite_events';
  
  /// Lädt alle favorisierten Event-IDs
  Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    return Set<String>.from(favoritesJson);
  }
  
  /// Fügt ein Event zu Favoriten hinzu
  Future<bool> addFavorite(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.add(eventId);
    return await prefs.setStringList(_favoritesKey, favorites.toList());
  }
  
  /// Entfernt ein Event aus Favoriten
  Future<bool> removeFavorite(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.remove(eventId);
    return await prefs.setStringList(_favoritesKey, favorites.toList());
  }
  
  /// Togglet Favoriten-Status eines Events
  Future<bool> toggleFavorite(String eventId) async {
    final favorites = await getFavorites();
    if (favorites.contains(eventId)) {
      return await removeFavorite(eventId);
    } else {
      return await addFavorite(eventId);
    }
  }
  
  /// Prüft ob ein Event favorisiert ist
  Future<bool> isFavorite(String eventId) async {
    final favorites = await getFavorites();
    return favorites.contains(eventId);
  }
  
  /// Löscht alle Favoriten
  Future<bool> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_favoritesKey);
  }
  
  /// Anzahl der Favoriten
  Future<int> getFavoritesCount() async {
    final favorites = await getFavorites();
    return favorites.length;
  }
}
