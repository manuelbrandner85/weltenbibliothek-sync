import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/media_item.dart';

/// Media Service - Lädt Medien aus Firestore Collection 'medien'
/// Synchronisiert mit Python-Script: telegram_to_ftp_sync.py
class MediaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'medien'; // Ihre Firestore Collection
  
  // Singleton Pattern
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();
  
  /// Stream: Echtzeit-Updates aller Medien
  Stream<List<MediaItem>> getMediaStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('upload_date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MediaItem.fromFirestore(doc))
              .toList();
        });
  }
  
  /// Lade alle Medien (einmalig)
  Future<List<MediaItem>> getAllMedia() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('upload_date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => MediaItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden der Medien: $e');
      }
      return [];
    }
  }
  
  /// Filtere nach Medientyp
  Future<List<MediaItem>> getMediaByType(String mediaType) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('media_type', isEqualTo: mediaType)
          .orderBy('upload_date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => MediaItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Filtern nach Typ: $e');
      }
      return [];
    }
  }
  
  /// Suche in Titeln und Beschreibungen
  Future<List<MediaItem>> searchMedia(String query) async {
    try {
      // Firestore hat keine LIKE-Suche, also laden wir alles
      final allMedia = await getAllMedia();
      
      if (query.isEmpty) {
        return allMedia;
      }
      
      final lowerQuery = query.toLowerCase();
      return allMedia.where((media) {
        return media.title.toLowerCase().contains(lowerQuery) ||
               media.description.toLowerCase().contains(lowerQuery) ||
               media.fileName.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Suchfehler: $e');
      }
      return [];
    }
  }
  
  /// Statistiken über alle Medien
  Future<Map<String, int>> getMediaStatistics() async {
    try {
      final allMedia = await getAllMedia();
      
      final stats = <String, int>{
        'total': allMedia.length,
        'videos': 0,
        'audios': 0,
        'images': 0,
        'pdfs': 0,
      };
      
      for (final media in allMedia) {
        switch (media.mediaType) {
          case 'video':
            stats['videos'] = (stats['videos'] ?? 0) + 1;
            break;
          case 'audio':
            stats['audios'] = (stats['audios'] ?? 0) + 1;
            break;
          case 'image':
            stats['images'] = (stats['images'] ?? 0) + 1;
            break;
          case 'pdf':
            stats['pdfs'] = (stats['pdfs'] ?? 0) + 1;
            break;
        }
      }
      
      return stats;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Statistik-Fehler: $e');
      }
      return {
        'total': 0,
        'videos': 0,
        'audios': 0,
        'images': 0,
        'pdfs': 0,
      };
    }
  }
  
  /// Füge neues Medium zu Firestore hinzu (wird normalerweise vom Python-Script gemacht)
  Future<void> addMedia(MediaItem media) async {
    try {
      await _firestore
          .collection(_collectionName)
          .add(media.toFirestore());
      
      if (kDebugMode) {
        debugPrint('✅ Medium hinzugefügt: ${media.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Hinzufügen: $e');
      }
      rethrow;
    }
  }
  
  /// Lösche Medium aus Firestore
  Future<void> deleteMedia(String mediaId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(mediaId)
          .delete();
      
      if (kDebugMode) {
        debugPrint('✅ Medium gelöscht: $mediaId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Löschen: $e');
      }
      rethrow;
    }
  }
  
  /// Zähle Medien nach Typ
  Future<int> countMediaByType(String mediaType) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('media_type', isEqualTo: mediaType)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Zählen: $e');
      }
      return 0;
    }
  }
}
