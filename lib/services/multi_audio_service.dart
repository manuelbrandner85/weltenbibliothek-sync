import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Multi Audio Upload Service mit Fallback-Optionen
/// 
/// Versucht mehrere kostenlose Audio-Hosting-Services:
/// 1. Catbox.moe (primär)
/// 2. File.io (fallback 1 - temporär, 14 Tage)
/// 3. 0x0.st (fallback 2 - permanentere Alternative)
class MultiAudioService {
  /// Upload mit automatischem Fallback
  static Future<String?> uploadAudio({
    required File audioFile,
    String? fileName,
  }) async {
    try {
      // Validierung
      if (!await audioFile.exists()) {
        if (kDebugMode) {
          debugPrint('❌ Audio-Datei existiert nicht: ${audioFile.path}');
        }
        return null;
      }
      
      final fileSize = await audioFile.length();
      if (kDebugMode) {
        debugPrint('🔊 Starting audio upload...');
        debugPrint('   File: ${audioFile.path}');
        debugPrint('   Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      }
      
      // 1. Versuch: Catbox (beste Option - permanent & unbegrenzt)
      String? url = await _uploadToCatbox(audioFile, fileName);
      if (url != null) {
        if (kDebugMode) debugPrint('✅ Catbox upload successful');
        return url;
      }
      
      if (kDebugMode) debugPrint('⚠️ Catbox failed, trying File.io...');
      
      // 2. Versuch: File.io (temporär 14 Tage, aber zuverlässig)
      url = await _uploadToFileIo(audioFile, fileName);
      if (url != null) {
        if (kDebugMode) debugPrint('✅ File.io upload successful (expires in 14 days)');
        return url;
      }
      
      if (kDebugMode) debugPrint('⚠️ File.io failed, trying 0x0.st...');
      
      // 3. Versuch: 0x0.st (permanent, einfache API)
      url = await _uploadTo0x0(audioFile, fileName);
      if (url != null) {
        if (kDebugMode) debugPrint('✅ 0x0.st upload successful');
        return url;
      }
      
      if (kDebugMode) {
        debugPrint('❌ All upload methods failed');
      }
      return null;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Audio upload exception: $e');
      }
      return null;
    }
  }
  
  /// Catbox.moe Upload (primär)
  static Future<String?> _uploadToCatbox(File audioFile, String? fileName) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://catbox.moe/user/api.php'),
      );
      
      request.fields['reqtype'] = 'fileupload';
      
      final multipartFile = await http.MultipartFile.fromPath(
        'fileToUpload',
        audioFile.path,
        filename: fileName ?? audioFile.path.split('/').last,
      );
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final url = response.body.trim();
        if (url.startsWith('https://files.catbox.moe/')) {
          return url;
        }
      }
      
      if (kDebugMode) {
        debugPrint('Catbox error: ${response.statusCode} - ${response.body}');
      }
      return null;
      
    } catch (e) {
      if (kDebugMode) debugPrint('Catbox exception: $e');
      return null;
    }
  }
  
  /// File.io Upload (fallback 1 - temporär 14 Tage)
  static Future<String?> _uploadToFileIo(File audioFile, String? fileName) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://file.io'),
      );
      
      // Expires nach 1 Download oder 14 Tage (was zuerst kommt)
      request.fields['expires'] = '14d';
      request.fields['maxDownloads'] = '0'; // Unbegrenzte Downloads
      
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
        filename: fileName ?? audioFile.path.split('/').last,
      );
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['link'] as String;
        }
      }
      
      if (kDebugMode) {
        debugPrint('File.io error: ${response.statusCode} - ${response.body}');
      }
      return null;
      
    } catch (e) {
      if (kDebugMode) debugPrint('File.io exception: $e');
      return null;
    }
  }
  
  /// 0x0.st Upload (fallback 2 - einfach & zuverlässig)
  static Future<String?> _uploadTo0x0(File audioFile, String? fileName) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://0x0.st'),
      );
      
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
        filename: fileName ?? audioFile.path.split('/').last,
      );
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final url = response.body.trim();
        if (url.startsWith('https://0x0.st/')) {
          return url;
        }
      }
      
      if (kDebugMode) {
        debugPrint('0x0.st error: ${response.statusCode} - ${response.body}');
      }
      return null;
      
    } catch (e) {
      if (kDebugMode) debugPrint('0x0.st exception: $e');
      return null;
    }
  }
}

/// Extension für einfachere Verwendung
extension MultiAudioExtension on File {
  /// Upload dieser Audio-Datei mit automatischem Fallback
  Future<String?> uploadAudio({String? fileName}) async {
    return await MultiAudioService.uploadAudio(
      audioFile: this,
      fileName: fileName,
    );
  }
}
