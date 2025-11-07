import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

/// v2.32.0 - Telegram File Downloader
/// 
/// Lädt Telegram-Dateien herunter und cached sie lokal
/// Ermöglicht Offline-Playback und schnelleres Laden
class TelegramFileDownloader {
  static final TelegramFileDownloader _instance = TelegramFileDownloader._internal();
  factory TelegramFileDownloader() => _instance;
  TelegramFileDownloader._internal();

  final String _botToken = '7826102549:AAHMOTvl13GlR2vousHVTE4jO0xTYuVlS7k';
  
  /// Download-Datei mit Progress-Callback
  Future<String?> downloadFile({
    required String fileId,
    required String fileName,
    Function(double progress)? onProgress,
  }) async {
    try {
      // 1. Hole File-Pfad von Telegram Bot API
      final fileInfoUrl = 'https://api.telegram.org/bot$_botToken/getFile?file_id=$fileId';
      final infoResponse = await http.get(Uri.parse(fileInfoUrl));
      
      if (infoResponse.statusCode != 200) {
        debugPrint('❌ Bot API Error: ${infoResponse.statusCode}');
        return null;
      }

      final infoData = json.decode(infoResponse.body);
      if (infoData['ok'] != true) {
        debugPrint('❌ Bot API returned ok=false');
        return null;
      }

      final filePath = infoData['result']['file_path'];
      final fileSize = infoData['result']['file_size'] ?? 0;
      
      debugPrint('✅ File info: $filePath (${_formatBytes(fileSize)})');

      // 2. Prüfe ob Datei bereits lokal existiert
      final localPath = await _getLocalFilePath(fileName);
      final localFile = File(localPath);
      
      if (await localFile.exists()) {
        final localSize = await localFile.length();
        if (localSize == fileSize) {
          debugPrint('✅ File bereits cached: $localPath');
          return localPath;
        } else {
          debugPrint('⚠️  Cached file size mismatch, re-downloading...');
          await localFile.delete();
        }
      }

      // 3. Lade Datei herunter
      final fileUrl = 'https://api.telegram.org/file/bot$_botToken/$filePath';
      debugPrint('📥 Downloading from: $fileUrl');
      
      final request = http.Request('GET', Uri.parse(fileUrl));
      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode != 200) {
        debugPrint('❌ Download failed: ${streamedResponse.statusCode}');
        return null;
      }

      // 4. Speichere mit Progress-Tracking
      final bytes = <int>[];
      int downloadedBytes = 0;
      
      await for (var chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
        downloadedBytes += chunk.length;
        
        if (onProgress != null && fileSize > 0) {
          final progress = downloadedBytes / fileSize;
          onProgress(progress);
        }
      }

      // 5. Schreibe in lokale Datei
      await localFile.writeAsBytes(bytes);
      debugPrint('✅ Downloaded: $localPath (${_formatBytes(bytes.length)})');
      
      return localPath;
      
    } catch (e) {
      debugPrint('❌ Download Error: $e');
      return null;
    }
  }

  /// Hole lokalen Dateipfad
  Future<String> _getLocalFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${directory.path}/telegram_cache');
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return '${cacheDir.path}/$fileName';
  }

  /// Prüfe ob Datei lokal existiert
  Future<bool> isFileCached(String fileName) async {
    final localPath = await _getLocalFilePath(fileName);
    return await File(localPath).exists();
  }

  /// Hole gecachte Datei (falls vorhanden)
  Future<String?> getCachedFilePath(String fileName) async {
    final localPath = await _getLocalFilePath(fileName);
    final file = File(localPath);
    
    if (await file.exists()) {
      return localPath;
    }
    return null;
  }

  /// Lösche gecachte Datei
  Future<bool> deleteCachedFile(String fileName) async {
    try {
      final localPath = await _getLocalFilePath(fileName);
      final file = File(localPath);
      
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️  Deleted cached file: $fileName');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Delete Error: $e');
      return false;
    }
  }

  /// Hole Cache-Größe
  Future<int> getCacheSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/telegram_cache');
      
      if (!await cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (var entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('❌ Cache size Error: $e');
      return 0;
    }
  }

  /// Lösche gesamten Cache
  Future<bool> clearCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/telegram_cache');
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        debugPrint('🗑️  Cache cleared');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Clear cache Error: $e');
      return false;
    }
  }

  /// Formatiere Bytes zu lesbarer Größe
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
