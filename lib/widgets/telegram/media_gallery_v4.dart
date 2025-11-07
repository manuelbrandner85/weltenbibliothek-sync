import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// MediaGalleryV4 - Intelligente Medien-Galerie mit Cache-Support
/// 
/// FEATURES:
/// - Grid-Ansicht für Fotos/Videos
/// - Cache-Status-Anzeige (Offline verfügbar)
/// - Streaming-Badge für streambare Medien
/// - Thumbnail-Vorschau
/// - Vollbild-Ansicht bei Tap
/// - Typ-spezifische Icons (Foto, Video, Audio, Dokument)
/// - Kompakt-Modus für Nachrichtenkarten
class MediaGalleryV4 extends StatelessWidget {
  final List<dynamic> mediaFiles;
  final bool compact;
  final int maxItemsCompact;
  
  const MediaGalleryV4({
    super.key,
    required this.mediaFiles,
    this.compact = false,
    this.maxItemsCompact = 4,
  });

  @override
  Widget build(BuildContext context) {
    final displayItems = compact 
      ? mediaFiles.take(maxItemsCompact).toList()
      : mediaFiles;
    
    final hasMore = compact && mediaFiles.length > maxItemsCompact;
    final moreCount = mediaFiles.length - maxItemsCompact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 2 : 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            final media = displayItems[index];
            return _MediaTile(
              media: media,
              onTap: () => _showFullScreen(context, media),
            );
          },
        ),
        
        if (hasMore)
          GestureDetector(
            onTap: () => _showAllMedia(context),
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+ $moreCount weitere Medien anzeigen',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showFullScreen(BuildContext context, Map<String, dynamic> media) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenMedia(media: media),
      ),
    );
  }

  void _showAllMedia(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Alle Medien (${mediaFiles.length})'),
          ),
          body: MediaGalleryV4(
            mediaFiles: mediaFiles,
            compact: false,
          ),
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final Map<String, dynamic> media;
  final VoidCallback onTap;
  
  const _MediaTile({
    required this.media,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCached = media['is_cached'] ?? false;
    final bool isStreamable = media['is_streamable'] ?? false;
    final String? mimeType = media['mime_type'];
    final String? localPath = media['local_path'];
    final String? thumbnailPath = media['thumbnail_local_path'];
    final String? downloadUrl = media['download_url'];
    
    // Determine media type
    final MediaType type = _getMediaType(mimeType);
    
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildPreview(type, localPath, thumbnailPath, downloadUrl),
          ),
          
          // Overlay Gradient
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          
          // Type Icon
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTypeIcon(type),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          // Cache Badge
          if (isCached)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.offline_pin,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Streamable Badge
          if (isStreamable)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Stream',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview(
    MediaType type,
    String? localPath,
    String? thumbnailPath,
    String? downloadUrl,
  ) {
    // Try thumbnail first
    if (thumbnailPath != null && File(thumbnailPath).existsSync()) {
      return Image.file(
        File(thumbnailPath),
        fit: BoxFit.cover,
      );
    }
    
    // Try local path for images
    if (type == MediaType.image && localPath != null && File(localPath).existsSync()) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
      );
    }
    
    // Try download URL for images
    if (type == MediaType.image && downloadUrl != null) {
      return CachedNetworkImage(
        imageUrl: downloadUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(type),
      );
    }
    
    // Fallback: Type-specific placeholder
    return _buildPlaceholder(type);
  }

  Widget _buildPlaceholder(MediaType type) {
    Color bgColor;
    IconData icon;
    
    switch (type) {
      case MediaType.video:
        bgColor = Colors.red.withOpacity(0.2);
        icon = Icons.video_library;
        break;
      case MediaType.audio:
        bgColor = Colors.purple.withOpacity(0.2);
        icon = Icons.audio_file;
        break;
      case MediaType.document:
        bgColor = Colors.blue.withOpacity(0.2);
        icon = Icons.description;
        break;
      case MediaType.image:
      default:
        bgColor = Colors.grey.withOpacity(0.2);
        icon = Icons.image;
    }
    
    return Container(
      color: bgColor,
      child: Center(
        child: Icon(icon, size: 48, color: Colors.grey[600]),
      ),
    );
  }

  MediaType _getMediaType(String? mimeType) {
    if (mimeType == null) return MediaType.unknown;
    
    if (mimeType.startsWith('image/')) return MediaType.image;
    if (mimeType.startsWith('video/')) return MediaType.video;
    if (mimeType.startsWith('audio/')) return MediaType.audio;
    if (mimeType.contains('pdf') || mimeType.contains('document')) {
      return MediaType.document;
    }
    
    return MediaType.unknown;
  }

  IconData _getTypeIcon(MediaType type) {
    switch (type) {
      case MediaType.image:
        return Icons.image;
      case MediaType.video:
        return Icons.videocam;
      case MediaType.audio:
        return Icons.audiotrack;
      case MediaType.document:
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}

enum MediaType {
  image,
  video,
  audio,
  document,
  unknown,
}

class _FullScreenMedia extends StatefulWidget {
  final Map<String, dynamic> media;
  
  const _FullScreenMedia({required this.media});

  @override
  State<_FullScreenMedia> createState() => _FullScreenMediaState();
}

class _FullScreenMediaState extends State<_FullScreenMedia> {
  VideoPlayerController? _videoController;
  
  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeMedia() {
    final String? mimeType = widget.media['mime_type'];
    final String? localPath = widget.media['local_path'];
    final String? downloadUrl = widget.media['download_url'];
    final bool isStreamable = widget.media['is_streamable'] ?? false;
    
    if (mimeType != null && mimeType.startsWith('video/')) {
      // Initialize video player
      if (localPath != null && File(localPath).existsSync()) {
        _videoController = VideoPlayerController.file(File(localPath));
      } else if (isStreamable && downloadUrl != null) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(downloadUrl));
      }
      
      _videoController?.initialize().then((_) {
        setState(() {});
        _videoController?.play();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? mimeType = widget.media['mime_type'];
    final String? localPath = widget.media['local_path'];
    final String? downloadUrl = widget.media['download_url'];
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _buildMediaContent(mimeType, localPath, downloadUrl),
      ),
    );
  }

  Widget _buildMediaContent(String? mimeType, String? localPath, String? downloadUrl) {
    if (mimeType == null) {
      return const Text('Medientyp unbekannt', style: TextStyle(color: Colors.white));
    }
    
    if (mimeType.startsWith('image/')) {
      if (localPath != null && File(localPath).existsSync()) {
        return InteractiveViewer(
          child: Image.file(File(localPath)),
        );
      } else if (downloadUrl != null) {
        return InteractiveViewer(
          child: CachedNetworkImage(imageUrl: downloadUrl),
        );
      }
    }
    
    if (mimeType.startsWith('video/') && _videoController != null) {
      if (_videoController!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        );
      } else {
        return const CircularProgressIndicator(color: Colors.white);
      }
    }
    
    return const Text('Medienvorschau nicht verfügbar', style: TextStyle(color: Colors.white));
  }
}
