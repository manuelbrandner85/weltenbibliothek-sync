import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:record/record.dart';  // DEAKTIVIERT - Build-Fehler
import '../config/app_theme.dart';

/// Voice Recorder Widget (Phase 5A)
class VoiceRecorderWidget extends StatefulWidget {
  final Function(String audioPath, int duration) onRecordComplete;
  final VoidCallback onCancel;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordComplete,
    required this.onCancel,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  // final AudioRecorder _audioRecorder = AudioRecorder();  // STUB
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // _audioRecorder.dispose();  // STUB
    super.dispose();
  }

  Future<void> _startRecording() async {
    // STUB IMPLEMENTATION - Voice recording requires native plugin
    // TODO: Implement with proper audio recording package when available
    setState(() {
      _isRecording = true;
      _recordDuration = 0;
    });

    // Simulate recording timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration++;
      });

      // Auto-stop nach 2 Minuten
      if (_recordDuration >= 120) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    // STUB IMPLEMENTATION
    _timer?.cancel();

    setState(() {
      _audioPath = '/tmp/stub_voice_message.m4a';  // Stub path
      _isRecording = false;
    });

    // Show info message
    debugPrint('⚠️ Voice recording is a stub - requires native audio plugin');
    
    // Simulate completion (in real app, this would be actual audio file)
    widget.onRecordComplete(_audioPath!, _recordDuration);
  }

  void _cancelRecording() async {
    // await _audioRecorder.stop();  // STUB
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
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel button
          IconButton(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Abbrechen',
          ),

          const SizedBox(width: 8),

          // Recording indicator
          if (_isRecording)
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),

          const SizedBox(width: 12),

          // Duration text
          Expanded(
            child: Text(
              _isRecording ? _formatDuration(_recordDuration) : 'Aufnahme beendet',
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Send button
          IconButton(
            onPressed: _isRecording ? _stopRecording : null,
            icon: Icon(
              Icons.send,
              color: _isRecording ? AppTheme.secondaryGold : Colors.grey,
            ),
            tooltip: 'Senden',
          ),
        ],
      ),
    );
  }
}

/// Audio Player Widget für empfangene Voice Messages
class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final int duration;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.duration,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isPlaying = false;
  int _currentPosition = 0;

  void _togglePlayPause() {
    // TODO: Implement audio playback mit just_audio
    setState(() {
      _isPlaying = !_isPlaying;
    });
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
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          IconButton(
            onPressed: _togglePlayPause,
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: AppTheme.secondaryGold,
            ),
          ),

          // Waveform/progress (simplified)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: _isPlaying ? 0.5 : 0,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryGold),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(widget.duration),
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Microphone icon
          const Icon(
            Icons.mic,
            color: AppTheme.textWhite,
            size: 20,
          ),
        ],
      ),
    );
  }
}
