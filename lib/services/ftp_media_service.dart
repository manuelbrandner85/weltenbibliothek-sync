import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// FTP Media Service
/// Lädt Medien-Metadaten vom FTP Server oder HTTP Proxy
class FTPMediaService {
  // FTP/HTTP Server Configuration
  static const String _ftpHost = 'your-ftp-server.com';
  static const String _ftpBasePath = '/weltenbibliothek';
  
  // Optional: HTTP Proxy für FTP-Zugriff
  static const String _httpProxyUrl = 'https://your-domain.com/media';
  static const bool _useHttpProxy = true; // Empfohlen für Flutter Web
  
  // Singleton Pattern
  static final FTPMediaService _instance = FTPMediaService._internal();
  factory FTPMediaService() => _instance;
  FTPMediaService._internal();
  
  /// Generiere Media URL
  String getMediaUrl(String category, String filename) {
    if (_useHttpProxy) {
      // HTTP Proxy (empfohlen für Flutter)
      return '$_httpProxyUrl/$category/$filename';
    } else {
      // Direkter FTP Zugriff
      return 'ftp://$_ftpHost$_ftpBasePath/$category/$filename';
    }
  }
  
  /// Lade Video URL
  String getVideoUrl(String filename) {
    return getMediaUrl('videos', filename);
  }
  
  /// Lade Audio URL
  String getAudioUrl(String filename) {
    return getMediaUrl('audios', filename);
  }
  
  /// Lade Bild URL
  String getImageUrl(String filename) {
    return getMediaUrl('images', filename);
  }
  
  /// Lade PDF URL
  String getPDFUrl(String filename) {
    return getMediaUrl('pdfs', filename);
  }
  
  /// Prüfe ob Media existiert (nur für HTTP Proxy)
  Future<bool> checkMediaExists(String url) async {
    if (!_useHttpProxy) {
      // FTP unterstützt keine HEAD-Requests einfach
      return true;
    }
    
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Media check failed: $e');
      }
      return false;
    }
  }
  
  /// Lade Medien-Liste aus Verzeichnis (benötigt HTTP Proxy mit Directory Listing)
  Future<List<MediaFile>> listMedia(String category) async {
    if (!_useHttpProxy) {
      throw UnsupportedError('Directory listing nur mit HTTP Proxy verfügbar');
    }
    
    try {
      // Beispiel: HTTP Proxy mit JSON Directory Listing
      final url = '$_httpProxyUrl/$category/index.json';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => MediaFile.fromJson(item)).toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ List media failed: $e');
      }
      return [];
    }
  }
}

/// Media File Model
class MediaFile {
  final String filename;
  final String url;
  final String category;
  final int? size;
  final DateTime? uploadDate;
  
  MediaFile({
    required this.filename,
    required this.url,
    required this.category,
    this.size,
    this.uploadDate,
  });
  
  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      filename: json['filename'] as String,
      url: json['url'] as String,
      category: json['category'] as String,
      size: json['size'] as int?,
      uploadDate: json['uploadDate'] != null 
          ? DateTime.parse(json['uploadDate'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'url': url,
      'category': category,
      'size': size,
      'uploadDate': uploadDate?.toIso8601String(),
    };
  }
}
