import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Catbox Audio Upload Service
/// 
/// Kostenloser Audio-Hosting-Service als Ersatz für Firebase Storage
/// - Keine Registrierung erforderlich
/// - Unterstützt Audio-Dateien (m4a, mp3, wav, etc.)
/// - Max 200 MB pro Datei
/// - Unbegrenzte Uploads
/// - Dateien bleiben permanent gespeichert
/// 
/// API Dokumentation: https://catbox.moe/tools.php
class CatboxAudioService {
  static const String _uploadEndpoint = 'https://catbox.moe/user/api.php';
  
  /// Upload einer Audio-Datei zu Catbox
  /// 
  /// [audioFile] - Die Audio-Datei als File-Objekt
  /// [fileName] - Optional: Dateiname (mit Extension)
  /// 
  /// Returns: URL der hochgeladenen Audio-Datei oder null bei Fehler
  static Future<String?> uploadAudio({
    required File audioFile,
    String? fileName,
  }) async {
    try {
      // Validierung
      if (!await audioFile.exists()) {
        if (kDebugMode) {
          debugPrint('❌ Catbox Audio Upload Error: Datei existiert nicht');
        }
        return null;
      }
      
      // Dateigröße prüfen (max 200 MB)
      final fileSize = await audioFile.length();
      if (fileSize > 200 * 1024 * 1024) {
        if (kDebugMode) {
          debugPrint('❌ Catbox Upload Error: Datei zu groß (max 200 MB)');
        }
        throw Exception('Audio-Datei zu groß (max 200 MB)');
      }
      
      if (kDebugMode) {
        debugPrint('🔊 Uploading audio to Catbox...');
        debugPrint('   File: ${audioFile.path}');
        debugPrint('   Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      }
      
      // Multipart Request erstellen
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_uploadEndpoint),
      );
      
      // Request Type: fileupload
      request.fields['reqtype'] = 'fileupload';
      
      // Audio-Datei hinzufügen
      final multipartFile = await http.MultipartFile.fromPath(
        'fileToUpload',
        audioFile.path,
        filename: fileName ?? audioFile.path.split('/').last,
      );
      request.files.add(multipartFile);
      
      // Request senden mit Timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Upload timeout - Bitte Internetverbindung prüfen');
        },
      );
      
      // Response lesen
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final audioUrl = response.body.trim();
        
        // Validierung: URL sollte mit https://files.catbox.moe/ beginnen
        if (audioUrl.startsWith('https://files.catbox.moe/')) {
          if (kDebugMode) {
            debugPrint('✅ Catbox Audio Upload successful!');
            debugPrint('🔗 Audio URL: $audioUrl');
          }
          return audioUrl;
        } else {
          if (kDebugMode) {
            debugPrint('❌ Catbox Upload Error: Ungültige URL');
            debugPrint('Response: $audioUrl');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Catbox API Error: ${response.statusCode}');
          debugPrint('Response: ${response.body}');
        }
        return null;
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Catbox Upload Exception: $e');
      }
      return null;
    }
  }
  
  /// Audio-Datei löschen (nur möglich mit Userhash)
  /// 
  /// Hinweis: Ohne Account/Userhash können Dateien nicht gelöscht werden
  /// Alternative: Temporäre Links mit File.io nutzen (löschen sich automatisch)
  static Future<bool> deleteAudio({
    required String fileName,
    required String userHash,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_uploadEndpoint),
        body: {
          'reqtype': 'deletefiles',
          'userhash': userHash,
          'files': fileName,
        },
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Catbox Delete Exception: $e');
      }
      return false;
    }
  }
  
  /// Hilfsmethode: Dateiname aus URL extrahieren
  static String? getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.pathSegments.last;
    } catch (e) {
      return null;
    }
  }
  
  /// Hilfsmethode: Audio-Format validieren
  static bool isValidAudioFormat(String filePath) {
    final validExtensions = ['.m4a', '.mp3', '.wav', '.aac', '.ogg', '.opus'];
    final lowerPath = filePath.toLowerCase();
    return validExtensions.any((ext) => lowerPath.endsWith(ext));
  }
}

/// Extension für einfachere Verwendung
extension CatboxAudioExtension on File {
  /// Upload dieser Audio-Datei zu Catbox
  Future<String?> uploadToCatbox({String? fileName}) async {
    return await CatboxAudioService.uploadAudio(
      audioFile: this,
      fileName: fileName,
    );
  }
}
