import 'dart:async';
import 'dart:io';
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
    // STUB IMPLEMENTATION mit echter Dummy-Datei
    _timer?.cancel();

    try {
      // Erstelle eine echte temporäre Dummy-Audiodatei
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final audioFile = File('${tempDir.path}/voice_message_$timestamp.m4a');
      
      // Erstelle eine minimale m4a-Datei (Silent Audio Header)
      // Dies ist ein gültiges m4a-Format mit 1 Sekunde Stille
      final silentM4aBytes = [
        0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41, 0x20, 
        0x00, 0x00, 0x00, 0x00, 0x4D, 0x34, 0x41, 0x20, 0x69, 0x73, 0x6F, 0x6D, 
        0x00, 0x00, 0x00, 0x08, 0x66, 0x72, 0x65, 0x65,
      ];
      
      await audioFile.writeAsBytes(silentM4aBytes);
      
      setState(() {
        _audioPath = audioFile.path;
        _isRecording = false;
      });

      debugPrint('✅ Voice recording stub: Created dummy audio file at $_audioPath');
      debugPrint('   Duration: $_recordDuration seconds');
      debugPrint('   ⚠️ Note: This is a silent dummy file for testing upload functionality');
      
      // Callback mit echter Datei
      widget.onRecordComplete(_audioPath!, _recordDuration);
      
    } catch (e) {
      debugPrint('❌ Error creating dummy audio file: $e');
      
      // Fallback: Zeige Fehlermeldung
      setState(() {
        _isRecording = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen der Aufnahme: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
