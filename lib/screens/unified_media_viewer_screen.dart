import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_theme.dart';

/// Unified Media Viewer v1.0
/// 
/// Öffnet und spielt alle Medientypen direkt ab:
/// - Videos → Video Player
/// - PDFs → WebView PDF Viewer  
/// - Bilder → Fullscreen Image Viewer
/// - Audio → Audio Player
class UnifiedMediaViewerScreen extends StatefulWidget {
  final Map<String, dynamic> mediaData;

  const UnifiedMediaViewerScreen({
    super.key,
    required this.mediaData,
  });

  @override
  State<UnifiedMediaViewerScreen> createState() => _UnifiedMediaViewerScreenState();
}

class _UnifiedMediaViewerScreenState extends State<UnifiedMediaViewerScreen> {
  // Video Player
  VideoPlayerController? _videoController;
  
  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  
  // PDF WebView
  late WebViewController _webViewController;
  
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeMedia() async {
    final type = widget.mediaData['type'];
    final downloadUrl = widget.mediaData['download_url'];

    if (downloadUrl == null || downloadUrl.isEmpty) {
      setState(() {
        _error = 'Keine Download-URL verfügbar';
        _isLoading = false;
      });
      return;
    }

    try {
      switch (type) {
        case 'video':
          await _initializeVideo(downloadUrl);
          break;
        case 'audio':
          await _initializeAudio(downloadUrl);
          break;
        case 'pdf':
          _initializePDF(downloadUrl);
          break;
        case 'image':
          setState(() => _isLoading = false);
          break;
        default:
          setState(() {
            _error = 'Unbekannter Medientyp: $type';
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

  Future<void> _initializeVideo(String url) async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoController!.initialize();
    setState(() => _isLoading = false);
    _videoController!.play();
  }

  Future<void> _initializeAudio(String url) async {
    await _audioPlayer.setSourceUrl(url);
    
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _audioDuration = d);
    });
    
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _audioPosition = p);
    });
    
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingAudio = false);
    });
    
    setState(() => _isLoading = false);
  }

  void _initializePDF(String url) {
    // Use Google Docs Viewer for PDF
    final googleDocsUrl = 'https://docs.google.com/gview?embedded=true&url=$url';
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(googleDocsUrl));
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.mediaData['type'];
    final title = widget.mediaData['title'] ?? 'Unbekannt';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _buildMediaContent(type),
    );
  }

  Widget _buildMediaContent(String type) {
    switch (type) {
      case 'video':
        return _buildVideoPlayer();
      case 'audio':
        return _buildAudioPlayer();
      case 'pdf':
        return _buildPDFViewer();
      case 'image':
        return _buildImageViewer();
      default:
        return const Center(
          child: Text(
            'Unbekannter Medientyp',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoController!),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: Icon(
                    _videoController!.value.isPlaying ? null : Icons.play_circle_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppTheme.primaryPurple,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    final title = widget.mediaData['title'] ?? 'Audio';
    final description = widget.mediaData['description'] ?? '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.orange.shade700],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.audiotrack, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 32),
            // Progress Slider
            Slider(
              value: _audioPosition.inSeconds.toDouble(),
              max: _audioDuration.inSeconds.toDouble(),
              onChanged: (value) {
                _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
              activeColor: Colors.orange,
              inactiveColor: Colors.white24,
            ),
            // Time Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_audioPosition),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    _formatDuration(_audioDuration),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Play/Pause Button
            IconButton(
              onPressed: () {
                if (_isPlayingAudio) {
                  _audioPlayer.pause();
                } else {
                  _audioPlayer.resume();
                }
                setState(() => _isPlayingAudio = !_isPlayingAudio);
              },
              icon: Icon(
                _isPlayingAudio ? Icons.pause_circle : Icons.play_circle,
                size: 64,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPDFViewer() {
    return WebViewWidget(controller: _webViewController);
  }

  Widget _buildImageViewer() {
    final downloadUrl = widget.mediaData['download_url'];
    
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: downloadUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
          errorWidget: (context, url, error) => const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
