import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Offline Storage Service
/// Verwaltet lokale Persistenz mit Hive für Offline-Zugriff
class OfflineStorageService {
  static const String _messagesBox = 'cached_messages';
  static const String _favoritesBox = 'favorites';
  static const String _readReceiptsBox = 'read_receipts';
  
  /// Initialisiere Hive
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Öffne Boxes
    await Hive.openBox<Map>(_messagesBox);
    await Hive.openBox<String>(_favoritesBox);
    await Hive.openBox<String>(_readReceiptsBox);
    
    if (kDebugMode) {
      debugPrint('✅ Offline Storage initialized');
    }
  }
  
  /// Cache Message
  Future<void> cacheMessage(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      final box = await Hive.openBox<Map>(_messagesBox);
      final key = '${collection}_$docId';
      
      await box.put(key, data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cache Message failed: $e');
      }
    }
  }
  
  /// Cache Multiple Messages
  Future<void> cacheMessages(
    String collection,
    List<QueryDocumentSnapshot> docs,
  ) async {
    try {
      final box = await Hive.openBox<Map>(_messagesBox);
      
      for (final doc in docs) {
        final key = '${collection}_${doc.id}';
        final data = doc.data() as Map<String, dynamic>;
        await box.put(key, data);
      }
      
      if (kDebugMode) {
        debugPrint('✅ Cached ${docs.length} messages for $collection');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cache Messages failed: $e');
      }
    }
  }
  
  /// Get Cached Messages
  Future<List<Map<String, dynamic>>> getCachedMessages(String collection) async {
    try {
      final box = await Hive.openBox<Map>(_messagesBox);
      final List<Map<String, dynamic>> messages = [];
      
      for (final key in box.keys) {
        if (key.toString().startsWith('${collection}_')) {
          final data = box.get(key);
          if (data != null) {
            messages.add(Map<String, dynamic>.from(data));
          }
        }
      }
      
      // Sort by timestamp (descending)
      messages.sort((a, b) {
        final aTime = a['timestamp'] ?? a['date'] ?? 0;
        final bTime = b['timestamp'] ?? b['date'] ?? 0;
        return bTime.compareTo(aTime);
      });
      
      return messages;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Get Cached Messages failed: $e');
      }
      return [];
    }
  }
  
  /// Clear Cache for Collection
  Future<void> clearCache(String collection) async {
    try {
      final box = await Hive.openBox<Map>(_messagesBox);
      final keysToDelete = <String>[];
      
      for (final key in box.keys) {
        if (key.toString().startsWith('${collection}_')) {
          keysToDelete.add(key.toString());
        }
      }
      
      await box.deleteAll(keysToDelete);
      
      if (kDebugMode) {
        debugPrint('✅ Cache cleared for $collection');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Clear Cache failed: $e');
      }
    }
  }
  
  /// Clear All Cache
  Future<void> clearAllCache() async {
    try {
      final box = await Hive.openBox<Map>(_messagesBox);
      await box.clear();
      
      if (kDebugMode) {
        debugPrint('✅ All cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Clear All Cache failed: $e');
      }
    }
  }
  
  /// Get Cache Size
  Future<int> getCacheSize() async {
    try {
      final box = await Hive.openBox<Map>(_messagesBox);
      return box.length;
    } catch (e) {
      return 0;
    }
  }
  
  /// Save Favorite
  Future<void> saveFavorite(String docId) async {
    try {
      final box = await Hive.openBox<String>(_favoritesBox);
      if (!box.containsKey(docId)) {
        await box.put(docId, docId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Save Favorite failed: $e');
      }
    }
  }
  
  /// Remove Favorite
  Future<void> removeFavorite(String docId) async {
    try {
      final box = await Hive.openBox<String>(_favoritesBox);
      await box.delete(docId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Remove Favorite failed: $e');
      }
    }
  }
  
  /// Get Favorites
  Future<List<String>> getFavorites() async {
    try {
      final box = await Hive.openBox<String>(_favoritesBox);
      return box.values.toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Save Read Receipt
  Future<void> saveReadReceipt(String docId) async {
    try {
      final box = await Hive.openBox<String>(_readReceiptsBox);
      if (!box.containsKey(docId)) {
        await box.put(docId, docId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Save Read Receipt failed: $e');
      }
    }
  }
  
  /// Get Read Receipts
  Future<List<String>> getReadReceipts() async {
    try {
      final box = await Hive.openBox<String>(_readReceiptsBox);
      return box.values.toList();
    } catch (e) {
      return [];
    }
  }
}
