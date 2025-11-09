import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/ftp_media_service.dart';

/// Beispiel Widget für FTP Media Player
/// Zeigt wie man Medien vom FTP Server abspielt
class FTPMediaPlayerExample extends StatefulWidget {
  final String mediaFilename;
  final String mediaCategory;
  
  const FTPMediaPlayerExample({
    super.key,
    required this.mediaFilename,
    required this.mediaCategory,
  });

  @override
  State<FTPMediaPlayerExample> createState() => _FTPMediaPlayerExampleState();
}

class _FTPMediaPlayerExampleState extends State<FTPMediaPlayerExample> {
  final FTPMediaService _mediaService = FTPMediaService();
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Generiere Media URL
      final mediaUrl = _mediaService.getMediaUrl(
        widget.mediaCategory,
        widget.mediaFilename,
      );

      // Prüfe ob Media existiert (optional)
      final exists = await _mediaService.checkMediaExists(mediaUrl);
      if (!exists) {
        setState(() {
          _error = 'Media nicht gefunden';
          _isLoading = false;
        });
        return;
      }

      // Initialisiere Video Player (für Videos)
      if (widget.mediaCategory == 'videos') {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(mediaUrl),
        );

        await _videoController!.initialize();
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // Für andere Media-Typen (Audio, Bilder, PDFs)
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Header
          ListTile(
            leading: _getCategoryIcon(widget.mediaCategory),
            title: Text(widget.mediaFilename),
            subtitle: Text('Kategorie: ${widget.mediaCategory}'),
          ),
          
          // Media Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
              ),
            )
          else
            _buildMediaContent(),
          
          // Controls
          if (!_isLoading && _error == null)
            _buildControls(),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    switch (widget.mediaCategory) {
      case 'videos':
        return _videoController != null
            ? AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
            : const SizedBox();
      
      case 'images':
        return Image.network(
          _mediaService.getImageUrl(widget.mediaFilename),
          fit: BoxFit.cover,
        );
      
      case 'audios':
        return const Padding(
          padding: EdgeInsets.all(32.0),
          child: Icon(Icons.audiotrack, size: 64),
        );
      
      case 'pdfs':
        return const Padding(
          padding: EdgeInsets.all(32.0),
          child: Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
        );
      
      default:
        return const Padding(
          padding: EdgeInsets.all(32.0),
          child: Icon(Icons.insert_drive_file, size: 64),
        );
    }
  }

  Widget _buildControls() {
    if (widget.mediaCategory == 'videos' && _videoController != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              _videoController!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
            ),
            onPressed: () {
              setState(() {
                _videoController!.value.isPlaying
                    ? _videoController!.pause()
                    : _videoController!.play();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () {
              _videoController!.pause();
              _videoController!.seekTo(Duration.zero);
              setState(() {});
            },
          ),
        ],
      );
    }
    
    // Für andere Media-Typen: Download-Button
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.download),
        label: const Text('Herunterladen'),
        onPressed: () {
          // TODO: Implement download
          final url = _mediaService.getMediaUrl(
            widget.mediaCategory,
            widget.mediaFilename,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download: $url')),
          );
        },
      ),
    );
  }

  Icon _getCategoryIcon(String category) {
    switch (category) {
      case 'videos':
        return const Icon(Icons.video_library, color: Colors.blue);
      case 'audios':
        return const Icon(Icons.audiotrack, color: Colors.purple);
      case 'images':
        return const Icon(Icons.image, color: Colors.green);
      case 'pdfs':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      default:
        return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }
}

/// Beispiel Screen zur Demonstration
class FTPMediaGalleryScreen extends StatelessWidget {
  const FTPMediaGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Beispiel-Medien (später dynamisch laden)
    final exampleMedia = [
      {'filename': 'video1.mp4', 'category': 'videos'},
      {'filename': 'podcast1.mp3', 'category': 'audios'},
      {'filename': 'image1.jpg', 'category': 'images'},
      {'filename': 'document1.pdf', 'category': 'pdfs'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FTP Media Gallery'),
      ),
      body: ListView.builder(
        itemCount: exampleMedia.length,
        itemBuilder: (context, index) {
          final media = exampleMedia[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: FTPMediaPlayerExample(
              mediaFilename: media['filename'] as String,
              mediaCategory: media['category'] as String,
            ),
          );
        },
      ),
    );
  }
}
