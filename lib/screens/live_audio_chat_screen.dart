import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/live_audio_service.dart';
import '../services/auth_service.dart';

/// Live Audio Chat Screen - Clubhouse-style voice chat
class LiveAudioChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const LiveAudioChatScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<LiveAudioChatScreen> createState() => _LiveAudioChatScreenState();
}

class _LiveAudioChatScreenState extends State<LiveAudioChatScreen> {
  final LiveAudioService _audioService = LiveAudioService();
  final AuthService _authService = AuthService();
  
  bool _isMuted = true;
  bool _isSpeaking = false;
  bool _isHandRaised = false;

  @override
  void initState() {
    super.initState();
    _joinRoom();
  }

  @override
  void dispose() {
    _leaveRoom();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    try {
      await _audioService.joinAudioRoom(widget.roomId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Beitreten: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _leaveRoom() async {
    await _audioService.leaveAudioRoom(widget.roomId);
  }

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    
    await _audioService.toggleMute(widget.roomId, _isMuted);
    
    if (_isMuted) {
      setState(() => _isSpeaking = false);
      await _audioService.toggleSpeaking(widget.roomId, false);
    }
  }

  Future<void> _toggleSpeaking() async {
    if (_isMuted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Mikrofon aktivieren um zu sprechen'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSpeaking = !_isSpeaking);
    await _audioService.toggleSpeaking(widget.roomId, _isSpeaking);
  }

  Future<void> _toggleHandRaise() async {
    setState(() => _isHandRaised = !_isHandRaised);
    await _audioService.raiseHand(widget.roomId, _isHandRaised);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomName,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            StreamBuilder<Map<String, dynamic>?>(
              stream: _audioService.getAudioRoomStream(widget.roomId),
              builder: (context, snapshot) {
                final room = snapshot.data;
                final participantCount = (room?['activeParticipants'] as List?)?.length ?? 0;
                return Text(
                  '$participantCount Teilnehmer',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.secondaryGold),
            onPressed: () => _showRoomInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Participants Grid
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _audioService.getRoomParticipants(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.secondaryGold),
                  );
                }

                final participants = snapshot.data ?? [];

                if (participants.isEmpty) {
                  return const Center(
                    child: Text(
                      'Keine Teilnehmer',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final participant = participants[index];
                    return _buildParticipantCard(participant);
                  },
                );
              },
            ),
          ),

          // Control Panel
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(Map<String, dynamic> participant) {
    final userName = participant['userName'] ?? 'Unbekannt';
    final isSpeaking = participant['isSpeaking'] == true;
    final isMuted = participant['isMuted'] == true;
    final isHandRaised = participant['isHandRaised'] == true;
    final isCurrentUser = participant['userId'] == _authService.currentUserId;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSpeaking
              ? [AppTheme.secondaryGold.withValues(alpha: 0.3), AppTheme.primaryPurple.withValues(alpha: 0.3)]
              : [AppTheme.surfaceDark, AppTheme.surfaceDark.withValues(alpha: 0.5)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpeaking ? AppTheme.secondaryGold : AppTheme.primaryPurple.withValues(alpha: 0.3),
          width: isSpeaking ? 2 : 1,
        ),
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: AppTheme.secondaryGold.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryPurple, AppTheme.secondaryGold],
                  ),
                ),
                child: Center(
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (isSpeaking)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.secondaryGold,
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            userName,
            style: TextStyle(
              color: isCurrentUser ? AppTheme.secondaryGold : Colors.white,
              fontSize: 12,
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Status Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isMuted)
                Icon(
                  Icons.mic_off,
                  size: 14,
                  color: Colors.red.shade300,
                ),
              if (isHandRaised)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text('✋', style: TextStyle(fontSize: 14)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute/Unmute Button
            _buildControlButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              label: _isMuted ? 'Unmute' : 'Mute',
              color: _isMuted ? Colors.red : AppTheme.primaryPurple,
              onTap: _toggleMute,
            ),

            // Raise Hand Button
            _buildControlButton(
              icon: Icons.pan_tool,
              label: _isHandRaised ? 'Lower' : 'Raise',
              color: _isHandRaised ? AppTheme.secondaryGold : Colors.grey,
              onTap: _toggleHandRaise,
            ),

            // Leave Button
            _buildControlButton(
              icon: Icons.call_end,
              label: 'Verlassen',
              color: Colors.red,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Raum Info', style: TextStyle(color: Colors.white)),
        content: StreamBuilder<Map<String, dynamic>?>(
          stream: _audioService.getAudioRoomStream(widget.roomId),
          builder: (context, snapshot) {
            final room = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${room?['name'] ?? 'Unbekannt'}', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                Text('Beschreibung: ${room?['description'] ?? 'Keine'}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text('Host: ${room?['hostName'] ?? 'Unbekannt'}', style: const TextStyle(color: AppTheme.secondaryGold)),
                const SizedBox(height: 8),
                Text('Teilnehmer: ${(room?['activeParticipants'] as List?)?.length ?? 0}/${room?['maxParticipants'] ?? 20}', style: const TextStyle(color: Colors.white)),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen', style: TextStyle(color: AppTheme.secondaryGold)),
          ),
        ],
      ),
    );
  }
}
