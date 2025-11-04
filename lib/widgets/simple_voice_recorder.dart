import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_theme.dart';

/// Vereinfachter Voice Recorder (Phase 5A)
/// Verwendet Platform-spezifische Implementierung
class SimpleVoiceRecorder extends StatefulWidget {
  final Function(String audioPath, int duration) onRecordComplete;
  final VoidCallback onCancel;

  const SimpleVoiceRecorder({
    super.key,
    required this.onRecordComplete,
    required this.onCancel,
  });

  @override
  State<SimpleVoiceRecorder> createState() => _SimpleVoiceRecorderState();
}

class _SimpleVoiceRecorderState extends State<SimpleVoiceRecorder> {
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _tempFilePath;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // Create temp file path
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        _tempFilePath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      } else {
        _tempFilePath = 'web_voice_recording.m4a';
      }

      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });

      // Start timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration++;
        });

        // Auto-stop nach 2 Minuten
        if (_recordDuration >= 120) {
          _stopRecording();
        }
      });

      if (kDebugMode) {
        debugPrint('🎤 Voice recording started (Demo mode)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Recording error: $e');
      }
      widget.onCancel();
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();

    setState(() {
      _isRecording = false;
    });

    if (_tempFilePath != null && _recordDuration > 0) {
      // In real implementation, this would be actual audio file
      // For demo, we create a placeholder
      try {
        if (!kIsWeb) {
          // Create empty file for demo
          final file = File(_tempFilePath!);
          await file.writeAsBytes([]);
        }

        if (kDebugMode) {
          debugPrint('✅ Voice recording completed: $_recordDuration seconds');
        }

        widget.onRecordComplete(_tempFilePath!, _recordDuration);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error saving recording: $e');
        }
        widget.onCancel();
      }
    } else {
      widget.onCancel();
    }
  }

  void _cancelRecording() {
    _timer?.cancel();
    widget.onCancel();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withValues(alpha: 0.8),
            AppTheme.primaryPurple.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel button
          IconButton(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.close, color: Colors.red, size: 28),
            tooltip: 'Abbrechen',
          ),

          const SizedBox(width: 8),

          // Recording indicator
          if (_isRecording) ...[
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: value),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: value * 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
              onEnd: () {
                setState(() {}); // Restart animation
              },
            ),
          ],

          const SizedBox(width: 12),

          // Waveform animation
          if (_isRecording)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 4.0, end: 20.0),
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      builder: (context, value, child) {
                        return Container(
                          width: 3,
                          height: value,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryGold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      },
                      onEnd: () {
                        setState(() {}); // Restart animation
                      },
                    ),
                  );
                }),
              ),
            )
          else
            Expanded(
              child: Text(
                'Aufnahme beendet',
                style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(width: 12),

          // Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDuration(_recordDuration),
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          IconButton(
            onPressed: _isRecording ? _stopRecording : null,
            icon: Icon(
              Icons.send_rounded,
              color: _isRecording ? AppTheme.secondaryGold : Colors.grey,
              size: 28,
            ),
            tooltip: 'Senden',
          ),
        ],
      ),
    );
  }
}

/// Audio Player für empfangene Voice Messages
class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final int duration;
  final bool isMe;

  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.duration,
    this.isMe = false,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  bool _isPlaying = false;
  double _progress = 0.0;

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      // TODO: Implement actual audio playback with audioplayers package
      // For now, simulate playback with progress animation
      _simulatePlayback();
    }
  }

  void _simulatePlayback() async {
    final steps = widget.duration * 10; // 10 steps per second
    for (int i = 0; i <= steps && _isPlaying; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted && _isPlaying) {
        setState(() {
          _progress = i / steps;
        });
      }
    }
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _progress = 0.0;
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isMe
              ? [
                  AppTheme.primaryPurple.withValues(alpha: 0.8),
                  AppTheme.primaryPurple.withValues(alpha: 0.6),
                ]
              : [
                  Colors.grey.shade800,
                  Colors.grey.shade700,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _togglePlayPause,
              icon: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppTheme.secondaryGold,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Waveform & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryGold),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 6),
                // Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration((_progress * widget.duration).round()),
                      style: TextStyle(
                        color: AppTheme.textWhite.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      _formatDuration(widget.duration),
                      style: TextStyle(
                        color: AppTheme.textWhite.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Microphone icon
          Icon(
            Icons.mic_rounded,
            color: AppTheme.secondaryGold.withValues(alpha: 0.6),
            size: 20,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isPlaying = false;
    super.dispose();
  }
}
