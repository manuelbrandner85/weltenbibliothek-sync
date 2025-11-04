import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// ImgBB Image Upload Service
/// 
/// Ermöglicht Upload von Bildern zu ImgBB (kostenlos & unbegrenzt)
/// Keine Storage-Bucket-Einrichtung nötig!
/// 
/// Features:
/// - Kostenloser unbegrenzter Storage
/// - Automatische CDN-Verteilung
/// - Direkte URLs für Firestore
/// - Unterstützt File und Uint8List (Web-kompatibel)
class ImgBBService {
  // ImgBB API Key (kostenlos bei https://imgbb.com/api)
  // WICHTIG: In Production sollte dieser Key als Umgebungsvariable gespeichert werden
  static const String _apiKey = '598264e651fd6c8dfe1ab1742375af34'; // ✅ Konfiguriert!
  static const String _uploadEndpoint = 'https://api.imgbb.com/1/upload';
  
  /// Upload eines Bildes zu ImgBB
  /// 
  /// [imageFile] - Das Bild als File-Objekt (Mobile)
  /// [imageBytes] - Das Bild als Bytes (Web-kompatibel)
  /// [name] - Optional: Name für das Bild
  /// 
  /// Returns: URL des hochgeladenen Bildes oder null bei Fehler
  static Future<String?> uploadImage({
    File? imageFile,
    Uint8List? imageBytes,
    String? name,
  }) async {
    try {
      // Validierung: Mindestens ein Parameter muss vorhanden sein
      if (imageFile == null && imageBytes == null) {
        if (kDebugMode) {
          debugPrint('❌ ImgBB Upload Error: Kein Bild übergeben');
        }
        return null;
      }
      
      // API Key Validierung
      if (_apiKey == 'dein_imgbb_api_key') {
        if (kDebugMode) {
          debugPrint('⚠️  ImgBB Warning: API Key nicht konfiguriert!');
          debugPrint('📝 Hol dir einen kostenlosen Key: https://api.imgbb.com/');
        }
        return null;
      }
      
      // Bild zu Base64 konvertieren
      String base64Image;
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        base64Image = base64Encode(bytes);
      } else {
        base64Image = base64Encode(imageBytes!);
      }
      
      if (kDebugMode) {
        debugPrint('📤 Uploading image to ImgBB...');
      }
      
      // HTTP POST Request
      final response = await http.post(
        Uri.parse(_uploadEndpoint),
        body: {
          'key': _apiKey,
          'image': base64Image,
          if (name != null) 'name': name,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout - Bitte Internetverbindung prüfen');
        },
      );
      
      // Response verarbeiten
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (jsonResponse['success'] == true) {
          final imageUrl = jsonResponse['data']['url'] as String;
          final displayUrl = jsonResponse['data']['display_url'] as String;
          final deleteUrl = jsonResponse['data']['delete_url'] as String;
          
          if (kDebugMode) {
            debugPrint('✅ ImgBB Upload successful!');
            debugPrint('🔗 Image URL: $imageUrl');
            debugPrint('📊 Size: ${jsonResponse['data']['size']} bytes');
          }
          
          // Optional: Delete URL für spätere Löschung speichern
          // (z.B. in Firestore mit dem Post/User-Dokument)
          
          return displayUrl; // Verwende display_url für beste Kompatibilität
        } else {
          if (kDebugMode) {
            debugPrint('❌ ImgBB Upload failed: ${jsonResponse['error']['message']}');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ ImgBB API Error: ${response.statusCode}');
          debugPrint('Response: ${response.body}');
        }
        return null;
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ImgBB Upload Exception: $e');
      }
      return null;
    }
  }
  
  /// Upload mehrerer Bilder gleichzeitig
  /// 
  /// Returns: Liste von URLs (null-Werte für fehlgeschlagene Uploads)
  static Future<List<String?>> uploadMultipleImages({
    List<File>? imageFiles,
    List<Uint8List>? imageBytesArray,
  }) async {
    if (imageFiles != null) {
      final futures = imageFiles.map((file) => uploadImage(imageFile: file));
      return await Future.wait(futures);
    } else if (imageBytesArray != null) {
      final futures = imageBytesArray.map((bytes) => uploadImage(imageBytes: bytes));
      return await Future.wait(futures);
    } else {
      return [];
    }
  }
  
  /// Hilfsmethode: Bild mit image_picker auswählen und hochladen
  /// 
  /// [pickFromGallery] - true = Galerie, false = Kamera
  /// 
  /// Returns: URL des hochgeladenen Bildes oder null
  static Future<String?> pickAndUploadImage({
    bool pickFromGallery = true,
  }) async {
    try {
      // Note: image_picker muss in pubspec.yaml sein
      final picker = await _getImagePicker();
      if (picker == null) return null;
      
      final pickedFile = await picker.pickImage(
        source: pickFromGallery ? ImageSource.gallery : ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85, // Komprimierung für schnelleren Upload
      );
      
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        return await uploadImage(imageFile: imageFile);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Pick & Upload Error: $e');
      }
      return null;
    }
  }
  
  /// Hilfsmethode: ImagePicker laden (lazy loading)
  static Future<dynamic> _getImagePicker() async {
    try {
      // Dynamic import um Compilation-Fehler zu vermeiden wenn image_picker fehlt
      return await Future.value(
        // ignore: avoid_dynamic_calls
        (await import('package:image_picker/image_picker.dart') as dynamic).ImagePicker(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️  image_picker nicht verfügbar: $e');
      }
      return null;
    }
  }
}

/// Enum für image_picker Source (zur Vermeidung von Import-Fehlern)
enum ImageSource {
  camera,
  gallery,
}

/// Extension für einfachere Verwendung
extension ImgBBUploadExtension on File {
  /// Upload dieses File zu ImgBB
  Future<String?> uploadToImgBB({String? name}) async {
    return await ImgBBService.uploadImage(
      imageFile: this,
      name: name,
    );
  }
}

extension ImgBBBytesExtension on Uint8List {
  /// Upload dieser Bytes zu ImgBB
  Future<String?> uploadToImgBB({String? name}) async {
    return await ImgBBService.uploadImage(
      imageBytes: this,
      name: name,
    );
  }
}
