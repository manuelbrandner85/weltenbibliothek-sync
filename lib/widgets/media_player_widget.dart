import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/media_item.dart';
import '../config/app_theme.dart';

/// Media Player Widget - Spielt Videos, Audio, Bilder und PDFs ab
/// Unterstützt FTP → HTTP Konvertierung für Flutter-Kompatibilität
class MediaPlayerWidget extends StatefulWidget {
  final MediaItem media;
  
  const MediaPlayerWidget({super.key, required this.media});

  @override
  State<MediaPlayerWidget> createState() => _MediaPlayerWidgetState();
}

class _MediaPlayerWidgetState extends State<MediaPlayerWidget> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isLoading = true;
  bool _isPlaying = false;
  String? _error;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  Future<void> _initializePlayer() async {
    try {
      switch (widget.media.mediaType) {
        case 'video':
          await _initializeVideoPlayer();
          break;
        case 'audio':
          await _initializeAudioPlayer();
          break;
        default:
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
  
  Future<void> _initializeVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.media.httpUrl),
      );
      
      await _videoController!.initialize();
      
      _videoController!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _videoController!.value.isPlaying;
            _currentPosition = _videoController!.value.position;
            _totalDuration = _videoController!.value.duration;
          });
        }
      });
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Video konnte nicht geladen werden. Prüfen Sie die HTTP-Verbindung zum FTP-Server.';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _initializeAudioPlayer() async {
    try {
      _audioPlayer = AudioPlayer();
      
      // Position-Listener
      _audioPlayer!.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      });
      
      // Duration-Listener
      _audioPlayer!.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() {
            _totalDuration = duration;
          });
        }
      });
      
      // Player State-Listener
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Audio-Player konnte nicht initialisiert werden: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.media.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: isDark ? AppTheme.backgroundDark : _getMediaColor(widget.media.mediaType),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryGold),
            )
          : _error != null
              ? _buildErrorState()
              : _buildMediaContent(),
    );
  }
  
  Widget _buildMediaContent() {
    switch (widget.media.mediaType) {
      case 'video':
        return _buildVideoPlayer();
      case 'audio':
        return _buildAudioPlayer();
      case 'image':
        return _buildImageViewer();
      case 'pdf':
        return _buildPDFViewer();
      default:
        return _buildDefaultViewer();
    }
  }
  
  /// VIDEO PLAYER
  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: Text('Video-Controller nicht initialisiert'),
      );
    }
    
    return Column(
      children: [
        // Video-Anzeige
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
        ),
        
        // Video-Controls
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Progress Bar
              VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: AppTheme.accentBlue,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.grey[800]!,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              
              const SizedBox(height: 12),
              
              // Zeit-Anzeige
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_currentPosition),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    _formatDuration(_totalDuration),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Steuerungs-Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                    iconSize: 32,
                    onPressed: () {
                      final newPosition = _currentPosition - const Duration(seconds: 10);
                      _videoController!.seekTo(
                        newPosition < Duration.zero ? Duration.zero : newPosition,
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: AppTheme.secondaryGold,
                    ),
                    iconSize: 72,
                    onPressed: () {
                      setState(() {
                        _isPlaying
                            ? _videoController!.pause()
                            : _videoController!.play();
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    iconSize: 32,
                    onPressed: () {
                      final newPosition = _currentPosition + const Duration(seconds: 10);
                      _videoController!.seekTo(
                        newPosition > _totalDuration ? _totalDuration : newPosition,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Media-Info
        _buildMediaInfo(),
      ],
    );
  }
  
  /// AUDIO PLAYER
  Widget _buildAudioPlayer() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Audio Icon mit Animation
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withOpacity(0.3),
                        Colors.purple.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.music_note : Icons.audiotrack,
                    size: 100,
                    color: Colors.purple,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Zeit-Anzeige
                Text(
                  '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                
                const SizedBox(height: 16),
                
                // Progress-Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Slider(
                    value: _currentPosition.inMilliseconds.toDouble(),
                    max: _totalDuration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                    onChanged: (value) {
                      _audioPlayer!.seek(Duration(milliseconds: value.toInt()));
                    },
                    activeColor: Colors.purple,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Steuerungs-Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      iconSize: 32,
                      onPressed: () {
                        final newPosition = _currentPosition - const Duration(seconds: 10);
                        _audioPlayer!.seek(
                          newPosition < Duration.zero ? Duration.zero : newPosition,
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: Colors.purple,
                      ),
                      iconSize: 72,
                      onPressed: () async {
                        if (_isPlaying) {
                          await _audioPlayer!.pause();
                        } else {
                          await _audioPlayer!.play(UrlSource(widget.media.httpUrl));
                        }
                      },
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.forward_10),
                      iconSize: 32,
                      onPressed: () {
                        final newPosition = _currentPosition + const Duration(seconds: 10);
                        _audioPlayer!.seek(
                          newPosition > _totalDuration ? _totalDuration : newPosition,
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Stop-Button
                TextButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Stoppen'),
                  onPressed: () async {
                    await _audioPlayer!.stop();
                    setState(() {
                      _currentPosition = Duration.zero;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        
        // Media-Info
        _buildMediaInfo(),
      ],
    );
  }
  
  /// IMAGE VIEWER
  Widget _buildImageViewer() {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  widget.media.httpUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppTheme.secondaryGold,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Bild konnte nicht geladen werden',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'URL: ${widget.media.httpUrl}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        _buildMediaInfo(),
      ],
    );
  }
  
  /// PDF VIEWER
  Widget _buildPDFViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, size: 128, color: Colors.red),
          const SizedBox(height: 32),
          const Text(
            'PDF-Dokument',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.media.title,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('In Browser öffnen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () => _launchUrl(widget.media.httpUrl),
          ),
          const SizedBox(height: 16),
          _buildMediaInfo(),
        ],
      ),
    );
  }
  
  /// DEFAULT VIEWER
  Widget _buildDefaultViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 128, color: Colors.grey),
          const SizedBox(height: 32),
          const Text(
            'Dateityp nicht unterstützt',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Herunterladen'),
            onPressed: () => _launchUrl(widget.media.httpUrl),
          ),
          const SizedBox(height: 32),
          _buildMediaInfo(),
        ],
      ),
    );
  }
  
  /// ERROR STATE
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mögliche Lösungen:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Stellen Sie sicher, dass der HTTP-Server läuft\n'
              '• Prüfen Sie die Firewall-Einstellungen\n'
              '• Verifizieren Sie die FTP → HTTP Konfiguration',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zurück'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// MEDIA INFO PANEL
  Widget _buildMediaInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.media.iconEmoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.media.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.media.description.isNotEmpty)
                      Text(
                        widget.media.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(_getMediaTypeName(widget.media.mediaType)),
                backgroundColor: _getMediaColor(widget.media.mediaType),
                labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              Chip(
                label: Text(widget.media.fileName),
                backgroundColor: Colors.grey[300],
                labelStyle: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// HILFSFUNKTIONEN
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konnte URL nicht öffnen: $url')),
        );
      }
    }
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  Color _getMediaColor(String mediaType) {
    switch (mediaType) {
      case 'video':
        return Colors.blue;
      case 'audio':
        return Colors.purple;
      case 'image':
        return Colors.green;
      case 'pdf':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getMediaTypeName(String mediaType) {
    switch (mediaType) {
      case 'video':
        return 'VIDEO';
      case 'audio':
        return 'AUDIO';
      case 'image':
        return 'BILD';
      case 'pdf':
        return 'PDF';
      default:
        return 'DATEI';
    }
  }
}
