import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Ultra-Robust Audio Upload Service
/// 
/// 5-stufiges Fallback-System mit verschiedenen Strategien:
/// 1. Catbox.moe (permanenter Upload)
/// 2. File.io (14 Tage)
/// 3. 0x0.st (180 Tage)
/// 4. Uguu.se (48 Stunden)
/// 5. ImgBB Base64 workaround (nur für kleine Dateien <5MB)
class AudioUploadService {
  /// Hauptmethode mit intelligentem Fallback
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
        debugPrint('🔊 Audio Upload Starting...');
        debugPrint('   File: ${audioFile.path}');
        debugPrint('   Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      }
      
      // Strategie basierend auf Dateigröße
      if (fileSize > 5 * 1024 * 1024) {
        // Große Dateien (>5MB): Nur Services mit großem Limit
        if (kDebugMode) debugPrint('📊 Large file detected, using high-capacity services');
        return await _uploadLargeFile(audioFile, fileName);
      } else {
        // Normale Dateien: Alle Services versuchen
        return await _uploadNormalFile(audioFile, fileName);
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Audio upload exception: $e');
      }
      return null;
    }
  }
  
  /// Upload für normale Dateien (alle Services)
  static Future<String?> _uploadNormalFile(File audioFile, String? fileName) async {
    String? url;
    
    // 1. Catbox
    url = await _uploadToCatbox(audioFile, fileName);
    if (url != null) return url;
    
    // 2. File.io
    url = await _uploadToFileIo(audioFile, fileName);
    if (url != null) return url;
    
    // 3. 0x0.st
    url = await _uploadTo0x0(audioFile, fileName);
    if (url != null) return url;
    
    // 4. Uguu.se
    url = await _uploadToUguu(audioFile, fileName);
    if (url != null) return url;
    
    // 5. ImgBB Base64 (nur für sehr kleine Dateien)
    final fileSize = await audioFile.length();
    if (fileSize < 2 * 1024 * 1024) {  // <2MB
      url = await _uploadToImgBBBase64(audioFile, fileName);
      if (url != null) return url;
    }
    
    return null;
  }
  
  /// Upload für große Dateien
  static Future<String?> _uploadLargeFile(File audioFile, String? fileName) async {
    String? url;
    
    // File.io unterstützt bis 2GB
    url = await _uploadToFileIo(audioFile, fileName);
    if (url != null) return url;
    
    // 0x0.st bis 512MB
    url = await _uploadTo0x0(audioFile, fileName);
    if (url != null) return url;
    
    // Catbox bis 200MB
    url = await _uploadToCatbox(audioFile, fileName);
    if (url != null) return url;
    
    return null;
  }
  
  /// 1. Catbox.moe Upload
  static Future<String?> _uploadToCatbox(File audioFile, String? fileName) async {
    try {
      if (kDebugMode) debugPrint('🔄 Trying Catbox...');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://catbox.moe/user/api.php'),
      );
      
      request.fields['reqtype'] = 'fileupload';
      
      final bytes = await audioFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'fileToUpload',
        bytes,
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
          if (kDebugMode) debugPrint('✅ Catbox success');
          return url;
        }
      }
      
      if (kDebugMode) debugPrint('❌ Catbox failed: ${response.statusCode}');
      return null;
      
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Catbox error: $e');
      return null;
    }
  }
  
  /// 2. File.io Upload
  static Future<String?> _uploadToFileIo(File audioFile, String? fileName) async {
    try {
      if (kDebugMode) debugPrint('🔄 Trying File.io...');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://file.io'),
      );
      
      request.fields['expires'] = '14d';
      request.fields['maxDownloads'] = '0';
      
      final bytes = await audioFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
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
          final url = jsonResponse['link'] as String;
          if (kDebugMode) debugPrint('✅ File.io success (14 days)');
          return url;
        }
      }
      
      if (kDebugMode) debugPrint('❌ File.io failed: ${response.statusCode}');
      return null;
      
    } catch (e) {
      if (kDebugMode) debugPrint('❌ File.io error: $e');
      return null;
    }
  }
  
  /// 3. 0x0.st Upload
  static Future<String?> _uploadTo0x0(File audioFile, String? fileName) async {
    try {
      if (kDebugMode) debugPrint('🔄 Trying 0x0.st...');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://0x0.st'),
      );
      
      final bytes = await audioFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
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
          if (kDebugMode) debugPrint('✅ 0x0.st success');
          return url;
        }
      }
      
      if (kDebugMode) debugPrint('❌ 0x0.st failed: ${response.statusCode}');
      return null;
      
    } catch (e) {
      if (kDebugMode) debugPrint('❌ 0x0.st error: $e');
      return null;
    }
  }
  
  /// 4. Uguu.se Upload (neu!)
  static Future<String?> _uploadToUguu(File audioFile, String? fileName) async {
    try {
      if (kDebugMode) debugPrint('🔄 Trying Uguu.se...');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://uguu.se/upload.php'),
      );
      
      final bytes = await audioFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'files[]',
        bytes,
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
          final files = jsonResponse['files'] as List;
          if (files.isNotEmpty) {
            final url = files[0]['url'] as String;
            if (kDebugMode) debugPrint('✅ Uguu.se success (48h)');
            return url;
          }
        }
      }
      
      if (kDebugMode) debugPrint('❌ Uguu.se failed: ${response.statusCode}');
      return null;
      
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Uguu.se error: $e');
      return null;
    }
  }
  
  /// 5. ImgBB Base64 Workaround (für sehr kleine Dateien)
  static Future<String?> _uploadToImgBBBase64(File audioFile, String? fileName) async {
    try {
      if (kDebugMode) debugPrint('🔄 Trying ImgBB Base64 workaround...');
      
      final bytes = await audioFile.readAsBytes();
      final base64 = base64Encode(bytes);
      
      // ImgBB akzeptiert nur Bilder, aber wir versuchen es trotzdem
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key': '598264e651fd6c8dfe1ab1742375af34',
          'image': base64,
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final url = jsonResponse['data']['display_url'] as String;
          if (kDebugMode) debugPrint('✅ ImgBB workaround success (unlikely)');
          return url;
        }
      }
      
      if (kDebugMode) debugPrint('❌ ImgBB workaround failed (expected)');
      return null;
      
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ImgBB workaround error: $e');
      return null;
    }
  }
}

/// Extension für einfachere Verwendung
extension AudioUploadExtension on File {
  Future<String?> uploadAudio({String? fileName}) async {
    return await AudioUploadService.uploadAudio(
      audioFile: this,
      fileName: fileName,
    );
  }
}
