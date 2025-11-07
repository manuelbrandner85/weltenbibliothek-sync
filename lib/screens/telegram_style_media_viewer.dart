import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';
import '../services/telegram_embed_service.dart';

/// v2.32.0 - Telegram-Style Media Viewer
/// 
/// Zeigt Medien GENAU WIE TELEGRAM - direkt streamen, KEIN Download
/// Telegram-ähnliches UI und UX
class TelegramStyleMediaViewer extends StatefulWidget {
  final Map<String, dynamic> mediaData;
  final String mediaType;

  const TelegramStyleMediaViewer({
    super.key,
    required this.mediaData,
    required this.mediaType,
  });

  @override
  State<TelegramStyleMediaViewer> createState() => _TelegramStyleMediaViewerState();
}

class _TelegramStyleMediaViewerState extends State<TelegramStyleMediaViewer> {
  final TelegramEmbedService _embedService = TelegramEmbedService();
  final String _botToken = '7826102549:AAHMOTvl13GlR2vousHVTE4jO0xTYuVlS7k';
  
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isLoading = true;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  String? _streamUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  Future<void> _initializeMedia() async {
    try {
      debugPrint('🎬 Initialisiere Media: ${widget.mediaType}');
      
      // Hole Telegram Streaming-URL
      _streamUrl = await _getTelegramStreamUrl();
      
      if (_streamUrl == null) {
        // Prüfe ob es ein t.me Link ist
        if (widget.mediaData.containsKey('video_url') &&
            widget.mediaData['video_url'].toString().startsWith('https://t.me/')) {
          setState(() {
            _error = 'Dieses Video ist nur über Telegram verfügbar.\n\n'
                    'Bitte öffne: ${widget.mediaData['video_url']}\n\n'
                    '💡 Tipp: Admins können Medien zu Firebase Storage hochladen für direktes Streaming.';
            _isLoading = false;
          });
          return;
        }
        
        setState(() {
          _error = 'Streaming-URL konnte nicht geladen werden.\n\n'
                  '❌ Keine download_url oder file_id verfügbar';
          _isLoading = false;
        });
        return;
      }

      debugPrint('✅ Stream URL: $_streamUrl');

      // Initialisiere Player basierend auf Media-Typ
      switch (widget.mediaType) {
        case 'video':
          await _initializeVideo(_streamUrl!);
          break;
        case 'audio':
          await _initializeAudio(_streamUrl!);
          break;
        case 'image':
          setState(() => _isLoading = false);
          break;
        case 'pdf':
          setState(() => _isLoading = false);
          break;
      }

    } catch (e) {
      setState(() {
        _error = 'Fehler: $e';
        _isLoading = false;
      });
      debugPrint('❌ Init Error: $e');
    }
  }

  Future<String?> _getTelegramStreamUrl() async {
    try {
      // PRIORITÄT 1: Firebase Storage download_url (direkte URL)
      if (widget.mediaData.containsKey('download_url') && 
          widget.mediaData['download_url'] != null &&
          widget.mediaData['download_url'].toString().isNotEmpty) {
        final downloadUrl = widget.mediaData['download_url'].toString();
        debugPrint('✅ Verwende Firebase Storage URL');
        debugPrint('🔗 URL: $downloadUrl');
        return downloadUrl;
      }
      
      // PRIORITÄT 2: video_url/audio_url (falls direkt verfügbar)
      if (widget.mediaData.containsKey('video_url') && 
          widget.mediaData['video_url'] != null) {
        debugPrint('✅ Verwende video_url');
        return widget.mediaData['video_url'].toString();
      }
      
      if (widget.mediaData.containsKey('audio_url') && 
          widget.mediaData['audio_url'] != null) {
        debugPrint('✅ Verwende audio_url');
        return widget.mediaData['audio_url'].toString();
      }
      
      // PRIORITÄT 3: Telegram Bot API (Fallback - weniger zuverlässig)
      final fileId = widget.mediaData['file_id'];
      
      if (fileId == null || fileId.isEmpty) {
        debugPrint('❌ Keine URL oder file_id gefunden');
        return null;
      }

      debugPrint('⚠️  Fallback zu Telegram Bot API (langsamer)');
      
      // Telegram Bot API: getFile
      final url = 'https://api.telegram.org/bot$_botToken/getFile?file_id=$fileId';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Telegram API Timeout');
        },
      );
      
      if (response.statusCode != 200) {
        debugPrint('❌ Telegram API Error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      
      if (data['ok'] != true) {
        debugPrint('❌ Telegram API returned ok=false: ${data['description']}');
        return null;
      }

      final filePath = data['result']['file_path'];
      final streamUrl = 'https://api.telegram.org/file/bot$_botToken/$filePath';
      
      debugPrint('⚠️  Telegram URL: $streamUrl');
      return streamUrl;
      
    } catch (e) {
      debugPrint('❌ Get Stream URL Error: $e');
      return null;
    }
  }

  Future<void> _initializeVideo(String url) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      setState(() => _isLoading = false);
      debugPrint('✅ Video initialized');
    } catch (e) {
      setState(() {
        _error = 'Video-Fehler: $e';
        _isLoading = false;
      });
      debugPrint('❌ Video Error: $e');
    }
  }

  Future<void> _initializeAudio(String url) async {
    try {
      await _audioPlayer.setSourceUrl(url);
      
      _audioPlayer.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      });
      
      _audioPlayer.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      });
      
      setState(() => _isLoading = false);
      debugPrint('✅ Audio initialized');
      
    } catch (e) {
      setState(() {
        _error = 'Audio-Fehler: $e';
        _isLoading = false;
      });
      debugPrint('❌ Audio Error: $e');
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
    final channelUsername = widget.mediaData['channel_username'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (channelUsername.isNotEmpty)
              Text(
                channelUsername,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
      body: _buildContent(description),
    );
  }

  Widget _buildContent(String description) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Media Content (nimmt verfügbaren Platz)
        Expanded(
          child: _buildMediaWidget(),
        ),
        
        // Telegram-style Beschreibung (nur wenn vorhanden)
        if (description.isNotEmpty)
          _buildDescriptionPanel(description),
      ],
    );
  }

  Widget _buildMediaWidget() {
    switch (widget.mediaType) {
      case 'video':
        return _buildTelegramStyleVideo();
      case 'audio':
        return _buildTelegramStyleAudio();
      case 'image':
        return _buildTelegramStyleImage();
      case 'pdf':
        return _buildTelegramStylePDF();
      default:
        return const Center(
          child: Text('Nicht unterstützt', style: TextStyle(color: Colors.white)),
        );
    }
  }

  Widget _buildTelegramStyleVideo() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _videoController!.value.isPlaying 
            ? _videoController!.pause()
            : _videoController!.play();
        });
      },
      child: Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoController!),
                
                // Play/Pause Icon (Telegram-Style)
                if (!_videoController!.value.isPlaying)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                
                // Progress Bar (unten)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white10,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelegramStyleAudio() {
    final displayName = _embedService.getDisplayName(widget.mediaData);
    final fileSize = widget.mediaData['file_size'] ?? 0;
    final duration = widget.mediaData['duration'] ?? 0;

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Telegram-style Audio Icon
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade300,
                  Colors.blue.shade600,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.headphones,
              size: 90,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // Titel
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          if (fileSize > 0 || duration > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _buildAudioInfo(fileSize, duration),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ),
          
          const SizedBox(height: 32),
          
          // Telegram-style Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 2,
            ),
            child: Slider(
              value: _position.inMilliseconds.toDouble(),
              max: _duration.inMilliseconds > 0 
                  ? _duration.inMilliseconds.toDouble()
                  : 1.0,
              onChanged: (value) async {
                await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
          
          // Zeit
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Telegram-style Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                Icons.replay_10,
                () async {
                  final newPos = _position - const Duration(seconds: 10);
                  await _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
                },
              ),
              const SizedBox(width: 24),
              _buildPlayPauseButton(),
              const SizedBox(width: 24),
              _buildControlButton(
                Icons.forward_10,
                () async {
                  final newPos = _position + const Duration(seconds: 10);
                  await _audioPlayer.seek(newPos > _duration ? _duration : newPos);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelegramStyleImage() {
    if (_streamUrl == null) {
      return const Center(
        child: Text('Bild nicht verfügbar', style: TextStyle(color: Colors.white70)),
      );
    }

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: _streamUrl!,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (context, url, error) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                'Bild konnte nicht geladen werden',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelegramStylePDF() {
    final displayName = _embedService.getDisplayName(widget.mediaData);
    final fileSize = widget.mediaData['file_size'] ?? 0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (fileSize > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _formatBytes(fileSize),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 32),
          Text(
            'PDF-Dokumente können in einem\nexternen Viewer geöffnet werden',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionPanel(String description) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          description,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.black,
          size: 32,
        ),
        onPressed: () async {
          if (_isPlaying) {
            await _audioPlayer.pause();
          } else {
            await _audioPlayer.resume();
          }
          setState(() => _isPlaying = !_isPlaying);
        },
      ),
    );
  }

  String _buildAudioInfo(int fileSize, int duration) {
    final parts = <String>[];
    if (duration > 0) {
      final minutes = duration ~/ 60;
      parts.add('$minutes Min');
    }
    if (fileSize > 0) {
      parts.add(_formatBytes(fileSize));
    }
    return parts.join(' • ');
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
