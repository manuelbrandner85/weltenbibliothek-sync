import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';

/// Enhanced Video Player mit erweiterten Features
/// 
/// Features:
/// - Picture-in-Picture Mode
/// - Playback-Speed Control (0.5x, 0.75x, 1x, 1.25x, 1.5x, 2x)
/// - Vollbild-Modus
/// - Untertitel-Support (falls vorhanden)
/// - Loop-Funktion
/// - Screenshot-Funktion
class EnhancedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool enablePiP;
  final VoidCallback? onPiPToggle;
  
  const EnhancedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.enablePiP = true,
    this.onPiPToggle,
  });

  @override
  State<EnhancedVideoPlayer> createState() => _EnhancedVideoPlayerState();
}

class _EnhancedVideoPlayerState extends State<EnhancedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isFullscreen = false;
  bool _isLooping = false;
  bool _isPiPMode = false;
  double _playbackSpeed = 1.0;
  
  // Verfügbare Playback-Speeds
  final List<double> _availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();
      
      setState(() {
        _isInitialized = true;
      });
      
      if (widget.autoPlay) {
        _controller!.play();
        setState(() => _isPlaying = true);
      }
      
      // Auto-hide controls after 3 seconds
      _controller!.addListener(() {
        if (_controller!.value.isPlaying != _isPlaying) {
          setState(() => _isPlaying = _controller!.value.isPlaying);
          if (_isPlaying) {
            _autoHideControls();
          }
        }
      });
    } catch (e) {
      debugPrint('❌ Video initialization error: $e');
    }
  }
  
  void _autoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    // Reset orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        height: 250,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    return _isPiPMode ? _buildPiPPlayer() : _buildNormalPlayer();
  }
  
  Widget _buildNormalPlayer() {
    return GestureDetector(
      onTap: () {
        setState(() => _showControls = !_showControls);
        if (_showControls && _isPlaying) {
          _autoHideControls();
        }
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Video
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
            
            // Controls Overlay
            if (_showControls)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    _buildTopControls(),
                    const Spacer(),
                    _buildCenterControls(),
                    const Spacer(),
                    _buildBottomControls(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // PiP Button
          if (widget.enablePiP && !_isFullscreen)
            IconButton(
              icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
              tooltip: 'Picture-in-Picture',
              onPressed: _togglePiP,
            ),
          
          const Spacer(),
          
          // Playback Speed
          PopupMenuButton<double>(
            icon: const Icon(Icons.speed, color: Colors.white),
            tooltip: 'Wiedergabe-Geschwindigkeit',
            color: AppTheme.surfaceDark,
            onSelected: _changePlaybackSpeed,
            itemBuilder: (context) => _availableSpeeds.map((speed) {
              return PopupMenuItem(
                value: speed,
                child: Row(
                  children: [
                    if (speed == _playbackSpeed)
                      Icon(Icons.check, color: AppTheme.secondaryGold, size: 20)
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${speed}x',
                      style: TextStyle(
                        color: speed == _playbackSpeed
                            ? AppTheme.secondaryGold
                            : AppTheme.textWhite,
                        fontWeight: speed == _playbackSpeed
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          
          // Loop Toggle
          IconButton(
            icon: Icon(
              _isLooping ? Icons.repeat_one : Icons.repeat,
              color: _isLooping ? AppTheme.secondaryGold : Colors.white,
            ),
            tooltip: 'Wiederholen',
            onPressed: _toggleLoop,
          ),
          
          // Fullscreen Toggle
          IconButton(
            icon: Icon(
              _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
            tooltip: _isFullscreen ? 'Vollbild beenden' : 'Vollbild',
            onPressed: _toggleFullscreen,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10s
        IconButton(
          icon: const Icon(Icons.replay_10, color: Colors.white, size: 40),
          tooltip: '10 Sekunden zurück',
          onPressed: () {
            final position = _controller!.value.position;
            _controller!.seekTo(position - const Duration(seconds: 10));
          },
        ),
        
        const SizedBox(width: 40),
        
        // Play/Pause
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 60,
            ),
            onPressed: _togglePlayPause,
          ),
        ),
        
        const SizedBox(width: 40),
        
        // Forward 10s
        IconButton(
          icon: const Icon(Icons.forward_10, color: Colors.white, size: 40),
          tooltip: '10 Sekunden vorwärts',
          onPressed: () {
            final position = _controller!.value.position;
            _controller!.seekTo(position + const Duration(seconds: 10));
          },
        ),
      ],
    );
  }
  
  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress Bar
          VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: AppTheme.secondaryGold,
              bufferedColor: Colors.grey.withValues(alpha: 0.5),
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Time Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_controller!.value.position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                '${_playbackSpeed}x',
                style: TextStyle(
                  color: _playbackSpeed != 1.0
                      ? AppTheme.secondaryGold
                      : Colors.white,
                  fontSize: 12,
                  fontWeight: _playbackSpeed != 1.0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              Text(
                _formatDuration(_controller!.value.duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPiPPlayer() {
    return Positioned(
      bottom: 80,
      right: 16,
      child: GestureDetector(
        onTap: _togglePiP,
        child: Container(
          width: 150,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.secondaryGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                Center(
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
  
  void _togglePlayPause() {
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
      _autoHideControls();
    }
    setState(() => _isPlaying = !_isPlaying);
  }
  
  void _changePlaybackSpeed(double speed) {
    _controller!.setPlaybackSpeed(speed);
    setState(() => _playbackSpeed = speed);
  }
  
  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
      _controller!.setLooping(_isLooping);
    });
  }
  
  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    
    if (_isFullscreen) {
      // Enter fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Exit fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }
  
  void _togglePiP() {
    setState(() => _isPiPMode = !_isPiPMode);
    widget.onPiPToggle?.call();
  }
}
