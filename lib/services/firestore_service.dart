import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/historical_event.dart';
import '../models/sighting.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Singleton Pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // ==================== HISTORICAL EVENTS ====================
  
  /// Lädt alle historischen Ereignisse aus Firestore
  Future<List<HistoricalEvent>> getHistoricalEvents({
    EventCategory? category,
    PerspectiveType? perspective,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection('events');
      
      // Filter nach Kategorie
      if (category != null) {
        query = query.where('category', isEqualTo: category.toString().split('.').last);
      }
      
      // Filter nach Perspektive
      if (perspective != null) {
        query = query.where('perspectives', arrayContains: perspective.toString().split('.').last);
      }
      
      // Sortierung nach Datum (neueste zuerst)
      query = query.orderBy('date', descending: true);
      
      // Limit
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => HistoricalEvent.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden der Events: $e');
      }
      return [];
    }
  }

  /// Lädt ein einzelnes Event
  Future<HistoricalEvent?> getEventById(String id) async {
    try {
      final doc = await _firestore.collection('events').doc(id).get();
      
      if (doc.exists) {
        return HistoricalEvent.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden des Events: $e');
      }
      return null;
    }
  }

  /// Speichert ein neues Event
  Future<String?> createEvent(HistoricalEvent event) async {
    try {
      final docRef = await _firestore.collection('events').add(event.toFirestore());
      
      if (kDebugMode) {
        debugPrint('✅ Event erstellt: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Erstellen des Events: $e');
      }
      return null;
    }
  }

  /// Aktualisiert ein Event
  Future<bool> updateEvent(String id, HistoricalEvent event) async {
    try {
      await _firestore.collection('events').doc(id).update(event.toFirestore());
      
      if (kDebugMode) {
        debugPrint('✅ Event aktualisiert: $id');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Aktualisieren des Events: $e');
      }
      return false;
    }
  }

  /// Löscht ein Event
  Future<bool> deleteEvent(String id) async {
    try {
      await _firestore.collection('events').doc(id).delete();
      
      if (kDebugMode) {
        debugPrint('✅ Event gelöscht: $id');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Löschen des Events: $e');
      }
      return false;
    }
  }

  /// Sucht Events nach Text
  Future<List<HistoricalEvent>> searchEvents(String query) async {
    try {
      // Firestore unterstützt keine Volltext-Suche, daher alle laden und filtern
      final allEvents = await getHistoricalEvents();
      
      final lowerQuery = query.toLowerCase();
      
      return allEvents.where((event) {
        return event.title.toLowerCase().contains(lowerQuery) ||
               event.description.toLowerCase().contains(lowerQuery) ||
               event.categoryName.toLowerCase().contains(lowerQuery) ||
               (event.locationName?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler bei der Suche: $e');
      }
      return [];
    }
  }

  // ==================== SIGHTINGS ====================

  /// Lädt alle Sichtungen
  Future<List<Sighting>> getSightings({
    SightingType? type,
    int? limit,
    bool verifiedOnly = false,
  }) async {
    try {
      Query query = _firestore.collection('sightings');
      
      // Filter nach Typ
      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }
      
      // Filter nach Verifizierung
      if (verifiedOnly) {
        query = query.where('verified', isEqualTo: true);
      }
      
      // Sortierung nach Timestamp (neueste zuerst)
      query = query.orderBy('timestamp', descending: true);
      
      // Limit
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => Sighting.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden der Sichtungen: $e');
      }
      return [];
    }
  }

  /// Erstellt eine neue Sichtung
  Future<String?> createSighting(Sighting sighting) async {
    try {
      final docRef = await _firestore.collection('sightings').add(sighting.toFirestore());
      
      if (kDebugMode) {
        debugPrint('✅ Sichtung erstellt: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Erstellen der Sichtung: $e');
      }
      return null;
    }
  }

  /// Lädt Sichtungen in einem bestimmten Radius
  Future<List<Sighting>> getSightingsNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      // Vereinfachte Implementierung: Alle Sichtungen laden und filtern
      final allSightings = await getSightings();
      
      return allSightings.where((sighting) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          sighting.latitude,
          sighting.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden naher Sichtungen: $e');
      }
      return [];
    }
  }

  // ==================== USER FAVORITES ====================

  /// Speichert Favoriten eines Benutzers
  Future<bool> saveFavorites(String userId, List<String> eventIds) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'favorites': eventIds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (kDebugMode) {
        debugPrint('✅ Favoriten gespeichert für User: $userId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Speichern der Favoriten: $e');
      }
      return false;
    }
  }

  /// Lädt Favoriten eines Benutzers
  Future<List<String>> getFavorites(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data();
        return List<String>.from(data?['favorites'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden der Favoriten: $e');
      }
      return [];
    }
  }

  // ==================== HELPER METHODS ====================

  /// Berechnet die Entfernung zwischen zwei Koordinaten (Haversine-Formel)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = (dLat / 2).sin() * (dLat / 2).sin() +
        _degreesToRadians(lat1).cos() *
            _degreesToRadians(lat2).cos() *
            (dLon / 2).sin() *
            (dLon / 2).sin();
    
    final c = 2 * (a.sqrt().asin());
    
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * 3.141592653589793 / 180.0;
  }

  // ==================== STREAM LISTENERS ====================

  /// Stream für Event-Updates
  Stream<List<HistoricalEvent>> eventsStream({
    EventCategory? category,
    int? limit,
  }) {
    Query query = _firestore.collection('events');
    
    if (category != null) {
      query = query.where('category', isEqualTo: category.toString().split('.').last);
    }
    
    query = query.orderBy('date', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => HistoricalEvent.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  /// Stream für Sichtungs-Updates
  Stream<List<Sighting>> sightingsStream({
    SightingType? type,
    int? limit,
  }) {
    Query query = _firestore.collection('sightings');
    
    if (type != null) {
      query = query.where('type', isEqualTo: type.toString().split('.').last);
    }
    
    query = query.orderBy('timestamp', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Sighting.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }
}
