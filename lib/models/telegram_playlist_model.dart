import 'package:cloud_firestore/cloud_firestore.dart';

/// Telegram Playlist Model
/// 
/// Nutzer können eigene Playlists erstellen und Telegram-Inhalte
/// darin organisieren.
class TelegramPlaylist {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String ownerName;
  final List<String> messageIds;
  final String? coverImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final List<String> collaborators;
  final int viewCount;
  final int shareCount;
  final Map<String, dynamic>? tags;
  
  TelegramPlaylist({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.messageIds,
    this.coverImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = false,
    this.collaborators = const [],
    this.viewCount = 0,
    this.shareCount = 0,
    this.tags,
  });
  
  factory TelegramPlaylist.fromFirestore(Map<String, dynamic> data, String id) {
    return TelegramPlaylist(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      ownerId: data['owner_id'] as String? ?? '',
      ownerName: data['owner_name'] as String? ?? '',
      messageIds: (data['message_ids'] as List<dynamic>?)?.cast<String>() ?? [],
      coverImageUrl: data['cover_image_url'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublic: data['is_public'] as bool? ?? false,
      collaborators: (data['collaborators'] as List<dynamic>?)?.cast<String>() ?? [],
      viewCount: data['view_count'] as int? ?? 0,
      shareCount: data['share_count'] as int? ?? 0,
      tags: data['tags'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'message_ids': messageIds,
      'cover_image_url': coverImageUrl,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_public': isPublic,
      'collaborators': collaborators,
      'view_count': viewCount,
      'share_count': shareCount,
      'tags': tags,
    };
  }
}
