import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../config/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════
/// VIDEO PLAYER VIEWER
/// ═══════════════════════════════════════════════════════════════════

class VideoPlayerViewer extends StatefulWidget {
  final String videoUrl;
  final String title;
  
  const VideoPlayerViewer({
    super.key,
    required this.videoUrl,
    this.title = 'Video',
  });

  @override
  State<VideoPlayerViewer> createState() => _VideoPlayerViewerState();
}

class _VideoPlayerViewerState extends State<VideoPlayerViewer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Video-Fehler: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator(color: AppTheme.primaryTeal)
            : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.white))
                : _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : const Text('Video nicht verfügbar', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════
/// IMAGE GALLERY VIEWER (mit Text und Zoom)
/// ═══════════════════════════════════════════════════════════════════

class ImageGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final String? text;
  final int initialIndex;
  
  const ImageGalleryViewer({
    super.key,
    required this.imageUrls,
    this.text,
    this.initialIndex = 0,
  });

  @override
  State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showText = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Bildergalerie mit Zoom
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.imageUrls.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(widget.imageUrls[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: 'image_$index'),
              );
            },
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
          
          // App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              title: Text('Bild ${_currentIndex + 1} von ${widget.imageUrls.length}'),
              backgroundColor: Colors.black.withOpacity(0.7),
              foregroundColor: Colors.white,
              actions: [
                if (widget.text != null && widget.text!.isNotEmpty)
                  IconButton(
                    icon: Icon(_showText ? Icons.text_fields : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _showText = !_showText;
                      });
                    },
                  ),
              ],
            ),
          ),
          
          // Text-Overlay (wenn mehrere Bilder und Text vorhanden)
          if (widget.text != null && widget.text!.isNotEmpty && _showText)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.text!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          
          // Page Indicator (wenn mehrere Bilder)
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: widget.imageUrls.length,
                  effect: const WormEffect(
                    dotColor: Colors.white38,
                    activeDotColor: AppTheme.primaryTeal,
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════
/// PDF VIEWER
/// ═══════════════════════════════════════════════════════════════════

class PDFViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  
  const PDFViewerScreen({
    super.key,
    required this.pdfUrl,
    this.title = 'PDF',
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _downloadPDF();
  }

  Future<void> _downloadPDF() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(response.bodyBytes);
      
      setState(() {
        _localPath = file.path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 16)),
            if (_totalPages > 0)
              Text(
                'Seite ${_currentPage + 1} von $_totalPages',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: AppTheme.surfaceDark,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _localPath != null
                  ? PDFView(
                      filePath: _localPath!,
                      autoSpacing: true,
                      pageFling: true,
                      pageSnap: true,
                      onPageChanged: (page, total) {
                        setState(() {
                          _currentPage = page ?? 0;
                          _totalPages = total ?? 0;
                        });
                      },
                      onError: (error) {
                        setState(() {
                          _error = error.toString();
                        });
                      },
                    )
                  : const Center(child: Text('PDF nicht verfügbar')),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════
/// AUDIO PLAYER (Hörbücher, Podcasts)
/// ═══════════════════════════════════════════════════════════════════

class AudioPlayerScreen extends StatefulWidget {
  final String audioUrl;
  final String title;
  final String? subtitle;
  
  const AudioPlayerScreen({
    super.key,
    required this.audioUrl,
    this.title = 'Audio',
    this.subtitle,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await _audioPlayer.setSourceUrl(widget.audioUrl);
      
      _audioPlayer.onDurationChanged.listen((duration) {
        setState(() {
          _duration = duration;
        });
      });
      
      _audioPlayer.onPositionChanged.listen((position) {
        setState(() {
          _position = position;
        });
      });
      
      _audioPlayer.onPlayerStateChanged.listen((state) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      });
      
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.resume();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${minutes}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Audio Player'),
        backgroundColor: AppTheme.surfaceDark,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Audio Icon
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.headphones,
                  size: 100,
                  color: AppTheme.primaryTeal,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (widget.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.subtitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              
              const SizedBox(height: 48),
              
              // Progress Slider
              Slider(
                value: _position.inSeconds.toDouble(),
                max: _duration.inSeconds.toDouble(),
                onChanged: (value) {
                  _audioPlayer.seek(Duration(seconds: value.toInt()));
                },
                activeColor: AppTheme.primaryTeal,
                inactiveColor: AppTheme.surfaceDark,
              ),
              
              // Time Labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Play/Pause Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rewind 10s
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    iconSize: 40,
                    color: AppTheme.textPrimary,
                    onPressed: () {
                      final newPosition = _position - const Duration(seconds: 10);
                      _audioPlayer.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
                    },
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Play/Pause
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      iconSize: 40,
                      color: Colors.white,
                      onPressed: _togglePlayPause,
                    ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Forward 10s
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    iconSize: 40,
                    color: AppTheme.textPrimary,
                    onPressed: () {
                      final newPosition = _position + const Duration(seconds: 10);
                      _audioPlayer.seek(newPosition > _duration ? _duration : newPosition);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
