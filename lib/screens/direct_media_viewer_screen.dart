import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';
import '../services/telegram_embed_service.dart';

/// v2.31.0 - Direct Media Viewer (OHNE Telegram Embed)
/// 
/// Lädt Dateien direkt über Telegram Bot API und spielt sie IN DER APP ab
/// Unterstützt: Videos, PDFs, Bilder, Audio (Hörbücher, Podcasts)
class DirectMediaViewerScreen extends StatefulWidget {
  final Map<String, dynamic> mediaData;
  final String mediaType; // 'video', 'pdf', 'image', 'audio'

  const DirectMediaViewerScreen({
    super.key,
    required this.mediaData,
    required this.mediaType,
  });

  @override
  State<DirectMediaViewerScreen> createState() => _DirectMediaViewerScreenState();
}

class _DirectMediaViewerScreenState extends State<DirectMediaViewerScreen> {
  final TelegramEmbedService _embedService = TelegramEmbedService();
  final String _botToken = '7826102549:AAHMOTvl13GlR2vousHVTE4jO0xTYuVlS7k';
  
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isLoading = true;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  String? _mediaUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  Future<void> _initializeMedia() async {
    try {
      // Hole Telegram File URL über Bot API
      final fileId = widget.mediaData['file_id'];
      
      if (fileId != null && fileId.isNotEmpty) {
        // Methode 1: Verwende file_id mit Bot API
        _mediaUrl = await _getFileUrlFromFileId(fileId);
      } else if (widget.mediaData['video_url'] != null) {
        // Methode 2: Für Videos - verwende direkte video_url
        // Konvertiere Telegram-Link zu direkter Datei-URL
        final videoUrl = widget.mediaData['video_url'] as String;
        if (videoUrl.contains('t.me/')) {
          // Extrahiere Channel und Message ID
          final uri = Uri.parse(videoUrl);
          final pathSegments = uri.pathSegments;
          if (pathSegments.length >= 2) {
            final channel = pathSegments[0];
            final messageId = pathSegments[1];
            
            // Versuche über Bot API die Datei zu holen
            // TODO: Implementiere Channel Message Fetch
            _mediaUrl = videoUrl; // Fallback
          }
        } else {
          _mediaUrl = videoUrl;
        }
      }

      if (_mediaUrl == null) {
        setState(() {
          _error = 'Keine Datei-URL gefunden';
          _isLoading = false;
        });
        return;
      }

      // Initialisiere entsprechenden Player
      switch (widget.mediaType) {
        case 'video':
          await _initializeVideo(_mediaUrl!);
          break;
        case 'audio':
          await _initializeAudio(_mediaUrl!);
          break;
        case 'image':
          // Bilder brauchen keine Initialisierung
          setState(() => _isLoading = false);
          break;
        case 'pdf':
          // PDFs werden extern geöffnet
          setState(() => _isLoading = false);
          break;
      }

    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
      debugPrint('❌ Media Load Error: $e');
    }
  }

  Future<String?> _getFileUrlFromFileId(String fileId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.telegram.org/bot$_botToken/getFile?file_id=$fileId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          final filePath = data['result']['file_path'];
          return 'https://api.telegram.org/file/bot$_botToken/$filePath';
        }
      }
      
      debugPrint('❌ Bot API Error: ${response.statusCode}');
      return null;
      
    } catch (e) {
      debugPrint('❌ File URL Error: $e');
      return null;
    }
  }

  Future<void> _initializeVideo(String url) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Video konnte nicht geladen werden: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeAudio(String url) async {
    try {
      await _audioPlayer.setSourceUrl(url);
      
      _audioPlayer.onDurationChanged.listen((duration) {
        setState(() => _duration = duration);
      });
      
      _audioPlayer.onPositionChanged.listen((position) {
        setState(() => _position = position);
      });
      
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      });
      
      setState(() => _isLoading = false);
      
    } catch (e) {
      setState(() {
        _error = 'Audio konnte nicht geladen werden: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _embedService.getDisplayName(widget.mediaData);
    final description = _embedService.getDescription(widget.mediaData);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryPurple,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.mediaData['channel_username'] != null)
              Text(
                widget.mediaData['channel_username'],
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: AppTheme.secondaryGold),
            onPressed: _downloadMedia,
          ),
        ],
      ),
      body: _buildContent(description),
    );
  }

  Widget _buildContent(String description) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.secondaryGold),
            SizedBox(height: 16),
            Text(
              'Lade Inhalt...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Media Content
        Expanded(
          child: _buildMediaWidget(),
        ),
        
        // Beschreibung (Original Telegram Caption)
        if (description.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.description, color: AppTheme.secondaryGold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Beschreibung',
                      style: TextStyle(
                        color: AppTheme.secondaryGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMediaWidget() {
    switch (widget.mediaType) {
      case 'video':
        return _buildVideoPlayer();
      case 'audio':
        return _buildAudioPlayer();
      case 'image':
        return _buildImageViewer();
      case 'pdf':
        return _buildPdfViewer();
      default:
        return const Center(
          child: Text(
            'Nicht unterstütztes Format',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.secondaryGold),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoController!),
            // Play/Pause Button
            IconButton(
              icon: Icon(
                _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                size: 64,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              onPressed: () {
                setState(() {
                  _videoController!.value.isPlaying
                      ? _videoController!.pause()
                      : _videoController!.play();
                });
              },
            ),
            // Progress Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppTheme.secondaryGold,
                  bufferedColor: Colors.white38,
                  backgroundColor: Colors.black26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    final displayName = _embedService.getDisplayName(widget.mediaData);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Audio Icon
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.music_note,
                  size: 100,
                  color: AppTheme.secondaryGold,
                ),
              ),
              const SizedBox(height: 32),
              
              // Titel
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Progress Slider
              Slider(
                value: _position.inMilliseconds.toDouble(),
                max: _duration.inMilliseconds.toDouble() > 0 
                    ? _duration.inMilliseconds.toDouble()
                    : 1.0,
                onChanged: (value) async {
                  await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                },
                activeColor: AppTheme.secondaryGold,
                inactiveColor: Colors.white38,
              ),
              
              // Time Display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // -10s Button
                  IconButton(
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                    iconSize: 36,
                    onPressed: () async {
                      final newPos = _position - const Duration(seconds: 10);
                      await _audioPlayer.seek(
                        newPos < Duration.zero ? Duration.zero : newPos
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  
                  // Play/Pause Button
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: AppTheme.secondaryGold,
                    ),
                    iconSize: 72,
                    onPressed: () async {
                      if (_isPlaying) {
                        await _audioPlayer.pause();
                      } else {
                        await _audioPlayer.resume();
                      }
                      setState(() => _isPlaying = !_isPlaying);
                    },
                  ),
                  const SizedBox(width: 16),
                  
                  // +10s Button
                  IconButton(
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    iconSize: 36,
                    onPressed: () async {
                      final newPos = _position + const Duration(seconds: 10);
                      await _audioPlayer.seek(
                        newPos > _duration ? _duration : newPos
                      );
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

  Widget _buildImageViewer() {
    if (_mediaUrl == null) {
      return const Center(
        child: Text(
          'Bild-URL nicht verfügbar',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: _mediaUrl!,
          placeholder: (context, url) => const CircularProgressIndicator(
            color: AppTheme.secondaryGold,
          ),
          errorWidget: (context, url, error) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Fehler beim Laden',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.picture_as_pdf,
            size: 100,
            color: AppTheme.secondaryGold,
          ),
          const SizedBox(height: 24),
          const Text(
            'PDF-Dokument',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_mediaUrl != null)
            ElevatedButton.icon(
              onPressed: () => _openPdfExternal(),
              icon: const Icon(Icons.open_in_new),
              label: const Text('In externem Viewer öffnen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _openPdfExternal() async {
    if (_mediaUrl == null) return;
    
    final uri = Uri.parse(_mediaUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF konnte nicht geöffnet werden')),
        );
      }
    }
  }

  Future<void> _downloadMedia() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download-Funktion wird vorbereitet...'),
          backgroundColor: AppTheme.primaryPurple,
        ),
      );
    }
    // TODO: Implementiere Download
  }
}
