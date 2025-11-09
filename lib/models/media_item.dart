import 'package:cloud_firestore/cloud_firestore.dart';

/// Media Item Model - Passt zu Ihrem Firestore-Schema
/// Collection: 'medien'
/// Felder: title, description, ftp_url, media_type, upload_date
class MediaItem {
  final String id;
  final String title;
  final String description;
  final String ftpUrl;
  final String mediaType; // "video", "audio", "image", "pdf"
  final DateTime? uploadDate;
  
  MediaItem({
    required this.id,
    required this.title,
    required this.description,
    required this.ftpUrl,
    required this.mediaType,
    this.uploadDate,
  });
  
  /// Firestore → Dart Object
  factory MediaItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MediaItem(
      id: doc.id,
      title: data['title'] as String? ?? 'Unbenannt',
      description: data['description'] as String? ?? '',
      ftpUrl: data['ftp_url'] as String? ?? '',
      mediaType: data['media_type'] as String? ?? 'other',
      uploadDate: data['upload_date'] != null 
          ? (data['upload_date'] as Timestamp).toDate()
          : null,
    );
  }
  
  /// Dart Object → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'ftp_url': ftpUrl,
      'media_type': mediaType,
      'upload_date': uploadDate != null ? Timestamp.fromDate(uploadDate!) : null,
    };
  }
  
  /// HTTP-URL generieren (FTP → HTTP Konvertierung)
  /// WICHTIG: Flutter kann nicht direkt FTP abspielen!
  String get httpUrl {
    // Konvertiere FTP zu HTTP für Flutter-Kompatibilität
    // ftp://user:pass@host:21/path → http://host:8080/path
    
    if (ftpUrl.startsWith('ftp://')) {
      final uri = Uri.parse(ftpUrl);
      // Extrahiere Host und Pfad, ignoriere User/Pass
      final host = uri.host;
      final path = uri.path;
      
      // Verwende HTTP Port 8080 (oder Ihren konfigurierten Port)
      return 'http://$host:8080$path';
    }
    
    // Falls schon HTTP, direkt zurückgeben
    return ftpUrl;
  }
  
  /// Extrahiere Dateiname aus URL
  String get fileName {
    try {
      final uri = Uri.parse(ftpUrl);
      return uri.pathSegments.last;
    } catch (e) {
      return 'unknown_file';
    }
  }
  
  /// Icon-Emoji basierend auf Medientyp
  String get iconEmoji {
    switch (mediaType) {
      case 'video':
        return '🎬';
      case 'audio':
        return '🎵';
      case 'image':
        return '🖼️';
      case 'pdf':
        return '📄';
      default:
        return '📁';
    }
  }
}
