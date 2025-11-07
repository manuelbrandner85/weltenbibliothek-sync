import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

/// Background Audio Player Service
/// 
/// Features:
/// - Background-Playback (Musik läuft im Hintergrund weiter)
/// - Queue-System (Warteschlange für mehrere Audios)
/// - Sleep-Timer (Audio nach X Minuten stoppen)
/// - Repeat/Shuffle Modes
/// - Playback-Speed Control
class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Queue Management
  final List<AudioTrack> _queue = [];
  int _currentIndex = -1;
  
  // Playback State
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  
  // Repeat & Shuffle
  RepeatMode _repeatMode = RepeatMode.off;
  bool _shuffleMode = false;
  
  // Sleep Timer
  Timer? _sleepTimer;
  Duration? _sleepDuration;
  
  // Getters
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  double get playbackSpeed => _playbackSpeed;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffleMode => _shuffleMode;
  List<AudioTrack> get queue => List.unmodifiable(_queue);
  AudioTrack? get currentTrack => _currentIndex >= 0 && _currentIndex < _queue.length
      ? _queue[_currentIndex]
      : null;
  int get currentIndex => _currentIndex;
  Duration? get sleepDuration => _sleepDuration;
  
  /// Initialize audio player
  Future<void> initialize() async {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });
    
    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      _position = position;
      notifyListeners();
    });
    
    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });
    
    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((event) {
      _handleTrackComplete();
    });
    
    if (kDebugMode) {
      print('✅ Audio Player Service initialized');
    }
  }
  
  /// Add track to queue
  void addToQueue(AudioTrack track) {
    _queue.add(track);
    notifyListeners();
    
    if (kDebugMode) {
      print('➕ Added to queue: ${track.title}');
    }
  }
  
  /// Add multiple tracks to queue
  void addMultipleToQueue(List<AudioTrack> tracks) {
    _queue.addAll(tracks);
    notifyListeners();
    
    if (kDebugMode) {
      print('➕ Added ${tracks.length} tracks to queue');
    }
  }
  
  /// Clear queue
  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    _audioPlayer.stop();
    notifyListeners();
    
    if (kDebugMode) {
      print('🗑️ Queue cleared');
    }
  }
  
  /// Remove track from queue
  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      final removed = _queue.removeAt(index);
      
      // Adjust current index if needed
      if (index < _currentIndex) {
        _currentIndex--;
      } else if (index == _currentIndex) {
        // Currently playing track removed, stop playback
        _audioPlayer.stop();
        _currentIndex = -1;
      }
      
      notifyListeners();
      
      if (kDebugMode) {
        print('🗑️ Removed from queue: ${removed.title}');
      }
    }
  }
  
  /// Play track at specific index
  Future<void> playTrackAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    
    _currentIndex = index;
    final track = _queue[index];
    
    try {
      _isLoading = true;
      notifyListeners();
      
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(track.url));
      await _audioPlayer.setPlaybackRate(_playbackSpeed);
      
      _isLoading = false;
      _isPlaying = true;
      notifyListeners();
      
      if (kDebugMode) {
        print('▶️ Playing: ${track.title}');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('❌ Error playing track: $e');
      }
    }
  }
  
  /// Play current track
  Future<void> play() async {
    if (_currentIndex >= 0) {
      await _audioPlayer.resume();
    } else if (_queue.isNotEmpty) {
      await playTrackAt(0);
    }
  }
  
  /// Pause playback
  Future<void> pause() async {
    await _audioPlayer.pause();
  }
  
  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }
  
  /// Stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
    _position = Duration.zero;
    notifyListeners();
  }
  
  /// Seek to position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }
  
  /// Play next track
  Future<void> playNext() async {
    if (_shuffleMode) {
      // Play random track
      final randomIndex = DateTime.now().millisecondsSinceEpoch % _queue.length;
      await playTrackAt(randomIndex);
    } else {
      final nextIndex = _currentIndex + 1;
      if (nextIndex < _queue.length) {
        await playTrackAt(nextIndex);
      } else if (_repeatMode == RepeatMode.all) {
        await playTrackAt(0);
      } else {
        await stop();
      }
    }
  }
  
  /// Play previous track
  Future<void> playPrevious() async {
    final prevIndex = _currentIndex - 1;
    if (prevIndex >= 0) {
      await playTrackAt(prevIndex);
    } else if (_repeatMode == RepeatMode.all) {
      await playTrackAt(_queue.length - 1);
    }
  }
  
  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _audioPlayer.setPlaybackRate(speed);
    notifyListeners();
    
    if (kDebugMode) {
      print('⚡ Playback speed: ${speed}x');
    }
  }
  
  /// Toggle repeat mode
  void toggleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
    
    if (kDebugMode) {
      print('🔁 Repeat mode: $_repeatMode');
    }
  }
  
  /// Toggle shuffle mode
  void toggleShuffleMode() {
    _shuffleMode = !_shuffleMode;
    notifyListeners();
    
    if (kDebugMode) {
      print('🔀 Shuffle mode: $_shuffleMode');
    }
  }
  
  /// Set sleep timer
  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepDuration = duration;
    
    _sleepTimer = Timer(duration, () {
      stop();
      _sleepDuration = null;
      notifyListeners();
      
      if (kDebugMode) {
        print('😴 Sleep timer expired');
      }
    });
    
    notifyListeners();
    
    if (kDebugMode) {
      print('😴 Sleep timer set: ${duration.inMinutes} minutes');
    }
  }
  
  /// Cancel sleep timer
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepDuration = null;
    notifyListeners();
    
    if (kDebugMode) {
      print('❌ Sleep timer cancelled');
    }
  }
  
  /// Handle track completion
  Future<void> _handleTrackComplete() async {
    if (_repeatMode == RepeatMode.one) {
      // Replay current track
      await playTrackAt(_currentIndex);
    } else {
      // Play next track
      await playNext();
    }
  }
  
  /// Dispose resources
  @override
  void dispose() {
    _audioPlayer.dispose();
    _sleepTimer?.cancel();
    super.dispose();
  }
}

/// Audio Track Model
class AudioTrack {
  final String id;
  final String title;
  final String artist;
  final String url;
  final String? thumbnailUrl;
  final Duration? duration;
  
  AudioTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    this.thumbnailUrl,
    this.duration,
  });
}

/// Repeat Mode Enum
enum RepeatMode {
  off,   // No repeat
  all,   // Repeat all tracks in queue
  one,   // Repeat current track
}
