import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/audio_player_service.dart';

/// Background Audio Player Widget
/// 
/// Minimal Player für den unteren Bildschirmrand, der immer sichtbar ist
class BackgroundAudioPlayerWidget extends StatelessWidget {
  const BackgroundAudioPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, audioService, child) {
        final currentTrack = audioService.currentTrack;
        
        if (currentTrack == null) {
          return const SizedBox.shrink();
        }
        
        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: audioService.duration.inMilliseconds > 0
                    ? audioService.position.inMilliseconds /
                        audioService.duration.inMilliseconds
                    : 0,
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryGold),
                minHeight: 2,
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Thumbnail
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                        ),
                        child: currentTrack.thumbnailUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  currentTrack.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.audiotrack, color: Colors.white),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Track Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentTrack.title,
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentTrack.artist,
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Controls
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white),
                        onPressed: () => audioService.playPrevious(),
                      ),
                      
                      IconButton(
                        icon: Icon(
                          audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: AppTheme.secondaryGold,
                          size: 32,
                        ),
                        onPressed: () => audioService.togglePlayPause(),
                      ),
                      
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: () => audioService.playNext(),
                      ),
                      
                      // Expand Button
                      IconButton(
                        icon: const Icon(Icons.expand_less, color: Colors.white),
                        onPressed: () => _showFullPlayer(context, audioService),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showFullPlayer(BuildContext context, AudioPlayerService audioService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FullAudioPlayerSheet(),
    );
  }
}

/// Full Audio Player Sheet (expanded view)
class FullAudioPlayerSheet extends StatelessWidget {
  const FullAudioPlayerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, audioService, child) {
        final currentTrack = audioService.currentTrack;
        
        if (currentTrack == null) {
          return const SizedBox.shrink();
        }
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Close Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.expand_more),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text('Jetzt läuft', style: AppTheme.headlineSmall),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showMoreOptions(context, audioService),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Large Thumbnail
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: currentTrack.thumbnailUrl != null
                      ? Image.network(
                          currentTrack.thumbnailUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                          child: const Icon(
                            Icons.audiotrack,
                            size: 100,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Track Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      currentTrack.title,
                      style: AppTheme.headlineSmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentTrack.artist,
                      style: AppTheme.bodyMedium.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Progress Slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Slider(
                      value: audioService.duration.inMilliseconds > 0
                          ? audioService.position.inMilliseconds.toDouble()
                          : 0,
                      max: audioService.duration.inMilliseconds.toDouble(),
                      activeColor: AppTheme.secondaryGold,
                      inactiveColor: Colors.grey.withValues(alpha: 0.3),
                      onChanged: (value) {
                        audioService.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(audioService.position),
                          style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                        ),
                        Text(
                          _formatDuration(audioService.duration),
                          style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Main Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shuffle
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: audioService.shuffleMode
                          ? AppTheme.secondaryGold
                          : Colors.grey,
                    ),
                    onPressed: () => audioService.toggleShuffleMode(),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Previous
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 40),
                    onPressed: () => audioService.playPrevious(),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Play/Pause
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryPurple,
                          AppTheme.secondaryGold,
                        ],
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 40,
                        color: Colors.white,
                      ),
                      onPressed: () => audioService.togglePlayPause(),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 40),
                    onPressed: () => audioService.playNext(),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Repeat
                  IconButton(
                    icon: Icon(
                      audioService.repeatMode == RepeatMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: audioService.repeatMode != RepeatMode.off
                          ? AppTheme.secondaryGold
                          : Colors.grey,
                    ),
                    onPressed: () => audioService.toggleRepeatMode(),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Queue Button
              TextButton.icon(
                onPressed: () => _showQueueSheet(context, audioService),
                icon: const Icon(Icons.queue_music),
                label: Text('Warteschlange (${audioService.queue.length})'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.secondaryGold,
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
  
  void _showMoreOptions(BuildContext context, AudioPlayerService audioService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Wiedergabe-Geschwindigkeit'),
            trailing: Text('${audioService.playbackSpeed}x'),
            onTap: () {
              Navigator.pop(context);
              _showSpeedSelector(context, audioService);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bedtime),
            title: const Text('Sleep-Timer'),
            subtitle: audioService.sleepDuration != null
                ? Text('Aktiv: ${audioService.sleepDuration!.inMinutes} Min.')
                : null,
            onTap: () {
              Navigator.pop(context);
              _showSleepTimer(context, audioService);
            },
          ),
        ],
      ),
    );
  }
  
  void _showSpeedSelector(BuildContext context, AudioPlayerService audioService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Wiedergabe-Geschwindigkeit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
            return RadioListTile<double>(
              value: speed,
              groupValue: audioService.playbackSpeed,
              title: Text('${speed}x'),
              activeColor: AppTheme.secondaryGold,
              onChanged: (value) {
                audioService.setPlaybackSpeed(value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showSleepTimer(BuildContext context, AudioPlayerService audioService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Sleep-Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('15 Minuten'),
              onTap: () {
                audioService.setSleepTimer(const Duration(minutes: 15));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('30 Minuten'),
              onTap: () {
                audioService.setSleepTimer(const Duration(minutes: 30));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('60 Minuten'),
              onTap: () {
                audioService.setSleepTimer(const Duration(minutes: 60));
                Navigator.pop(context);
              },
            ),
            if (audioService.sleepDuration != null)
              ListTile(
                title: const Text('Abbrechen'),
                textColor: Colors.red,
                onTap: () {
                  audioService.cancelSleepTimer();
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  void _showQueueSheet(BuildContext context, AudioPlayerService audioService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Warteschlange', style: AppTheme.headlineSmall),
                TextButton(
                  onPressed: () {
                    audioService.clearQueue();
                    Navigator.pop(context);
                  },
                  child: const Text('Alle löschen'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: audioService.queue.length,
              itemBuilder: (context, index) {
                final track = audioService.queue[index];
                final isCurrentTrack = index == audioService.currentIndex;
                
                return ListTile(
                  leading: isCurrentTrack
                      ? const Icon(Icons.play_arrow, color: AppTheme.secondaryGold)
                      : Text('${index + 1}'),
                  title: Text(
                    track.title,
                    style: TextStyle(
                      color: isCurrentTrack ? AppTheme.secondaryGold : null,
                      fontWeight: isCurrentTrack ? FontWeight.bold : null,
                    ),
                  ),
                  subtitle: Text(track.artist),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => audioService.removeFromQueue(index),
                  ),
                  onTap: () {
                    audioService.playTrackAt(index);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
