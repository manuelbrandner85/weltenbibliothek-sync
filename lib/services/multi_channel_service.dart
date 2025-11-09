import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Multi-Channel Telegram Service
/// 
/// Verwaltet die 6 separaten Telegram-Channel-Collections:
/// - chat_messages (@Weltenbibliothekchat)
/// - pdf_documents (@WeltenbibliothekPDF)
/// - images (@weltenbibliothekbilder)
/// - wachauf_content (@WeltenbibliothekWachauf)
/// - archive_items (@ArchivWeltenBibliothek)
/// - audiobooks (@WeltenbibliothekHoerbuch)
class MultiChannelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Singleton Pattern
  static final MultiChannelService _instance = MultiChannelService._internal();
  factory MultiChannelService() => _instance;
  MultiChannelService._internal();
  
  // Channel-Konfiguration
  static const Map<String, ChannelConfig> channels = {
    'chat_messages': ChannelConfig(
      name: 'Chat Nachrichten',
      icon: '💬',
      channel: '@Weltenbibliothekchat',
      description: 'Allgemeine Chat-Nachrichten',
      color: 0xFF4ADE80, // Grün
    ),
    'pdf_documents': ChannelConfig(
      name: 'PDF Dokumente',
      icon: '📄',
      channel: '@WeltenbibliothekPDF',
      description: 'PDF-Dokumente und Bücher',
      color: 0xFFEF4444, // Rot
    ),
    'images': ChannelConfig(
      name: 'Bilder',
      icon: '🖼️',
      channel: '@weltenbibliothekbilder',
      description: 'Bilder und Fotos',
      color: 0xFF06B6D4, // Cyan
    ),
    'wachauf_content': ChannelConfig(
      name: 'Wach Auf',
      icon: '⚡',
      channel: '@WeltenbibliothekWachauf',
      description: 'Erweckende Inhalte',
      color: 0xFFFBBF24, // Gelb
    ),
    'archive_items': ChannelConfig(
      name: 'Archiv',
      icon: '📚',
      channel: '@ArchivWeltenBibliothek',
      description: 'Archivierte Inhalte',
      color: 0xFF8B5CF6, // Violett
    ),
    'audiobooks': ChannelConfig(
      name: 'Hörbücher',
      icon: '🎧',
      channel: '@WeltenbibliothekHoerbuch',
      description: 'Hörbücher und Audio-Inhalte',
      color: 0xFFEC4899, // Magenta
    ),
  };
  
  /// Stream für eine spezifische Collection
  Stream<List<Map<String, dynamic>>> getCollectionStream(
    String collectionName, {
    int limit = 50,
  }) {
    return _firestore
        .collection(collectionName)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['collection'] = collectionName;
        return data;
      }).toList();
    });
  }
  
  /// Stream für alle Channels kombiniert
  Stream<List<Map<String, dynamic>>> getAllChannelsStream({int limit = 20}) {
    final List<Stream<List<Map<String, dynamic>>>> streams = [];
    
    for (var collectionName in channels.keys) {
      streams.add(getCollectionStream(collectionName, limit: limit));
    }
    
    // Kombiniere alle Streams
    return StreamGroup.merge(streams).map((items) {
      // items ist bereits eine Liste von Maps
      final allItems = List<Map<String, dynamic>>.from(items);
      
      // Sortiere nach Datum (neueste zuerst)
      allItems.sort((a, b) {
        final aTime = _getTimestamp(a);
        final bTime = _getTimestamp(b);
        return bTime.compareTo(aTime);
      });
      
      // Limitiere Gesamtzahl
      return allItems.take(limit * channels.length).toList();
    });
  }
  
  /// Hole Dokumente aus einer Collection
  Future<List<Map<String, dynamic>>> getDocuments(
    String collectionName, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['collection'] = collectionName;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden von $collectionName: $e');
      }
      return [];
    }
  }
  
  /// Hole alle Dokumente von allen Channels
  Future<List<Map<String, dynamic>>> getAllDocuments({int limit = 20}) async {
    final List<Map<String, dynamic>> allDocs = [];
    
    for (var collectionName in channels.keys) {
      final docs = await getDocuments(collectionName, limit: limit);
      allDocs.addAll(docs);
    }
    
    // Sortiere nach Datum (neueste zuerst)
    allDocs.sort((a, b) {
      final aTime = _getTimestamp(a);
      final bTime = _getTimestamp(b);
      return bTime.compareTo(aTime);
    });
    
    return allDocs.take(limit * channels.length).toList();
  }
  
  /// Statistiken für alle Channels
  Future<Map<String, int>> getChannelStatistics() async {
    final stats = <String, int>{};
    
    for (var collectionName in channels.keys) {
      try {
        final snapshot = await _firestore
            .collection(collectionName)
            .count()
            .get();
        
        stats[collectionName] = snapshot.count ?? 0;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Fehler bei Stats für $collectionName: $e');
        }
        stats[collectionName] = 0;
      }
    }
    
    return stats;
  }
  
  /// Suche über alle Collections
  Future<List<Map<String, dynamic>>> searchAcrossChannels(
    String query, {
    int limit = 30,
  }) async {
    final results = <Map<String, dynamic>>[];
    final lowerQuery = query.toLowerCase();
    
    for (var collectionName in channels.keys) {
      try {
        final snapshot = await _firestore
            .collection(collectionName)
            .orderBy('timestamp', descending: true)
            .limit(100)
            .get();
        
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final text = (data['text'] ?? '').toString().toLowerCase();
          
          if (text.contains(lowerQuery)) {
            data['id'] = doc.id;
            data['collection'] = collectionName;
            results.add(data);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Fehler bei Suche in $collectionName: $e');
        }
      }
    }
    
    // Sortiere nach Relevanz und Datum
    results.sort((a, b) {
      final aTime = _getTimestamp(a);
      final bTime = _getTimestamp(b);
      return bTime.compareTo(aTime);
    });
    
    return results.take(limit).toList();
  }
  
  /// Hilfsfunktion: Extrahiere Timestamp aus Document
  DateTime _getTimestamp(Map<String, dynamic> doc) {
    try {
      final timestamp = doc['timestamp'];
      
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    } catch (e) {
      // Fallback
    }
    
    return DateTime.now();
  }
  
  /// Formatiere Nachricht für Anzeige
  static String formatMessage(Map<String, dynamic> doc) {
    return doc['text'] ?? doc['message'] ?? 'Keine Nachricht';
  }
  
  /// Hole Media-URL
  static String? getMediaUrl(Map<String, dynamic> doc) {
    // Try different possible field names
    if (doc['mediaUrl'] != null && doc['mediaUrl'].toString().isNotEmpty) {
      return doc['mediaUrl'].toString();
    }
    if (doc['media_url'] != null && doc['media_url'].toString().isNotEmpty) {
      return doc['media_url'].toString();
    }
    if (doc['file_url'] != null && doc['file_url'].toString().isNotEmpty) {
      return doc['file_url'].toString();
    }
    if (doc['ftpPath'] != null && doc['ftpPath'].toString().isNotEmpty) {
      // Construct URL from FTP path
      final ftpPath = doc['ftpPath'].toString();
      return 'http://Weltenbibliothek.ddns.net:8080$ftpPath';
    }
    return null;
  }
  
  /// Hole Channel-Config für Collection
  static ChannelConfig? getChannelConfig(String collectionName) {
    return channels[collectionName];
  }
}

/// Channel-Konfiguration
class ChannelConfig {
  final String name;
  final String icon;
  final String channel;
  final String description;
  final int color;
  
  const ChannelConfig({
    required this.name,
    required this.icon,
    required this.channel,
    required this.description,
    required this.color,
  });
}

/// StreamGroup Helper (fallback implementation)
class StreamGroup<T> {
  static Stream<List<T>> merge<T>(List<Stream<List<T>>> streams) {
    final controller = StreamController<List<T>>();
    final allItems = <T>[];
    
    for (var stream in streams) {
      stream.listen((items) {
        allItems.addAll(items);
        controller.add(List.from(allItems));
      });
    }
    
    return controller.stream;
  }
}
