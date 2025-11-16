/// Audio Call Screen
/// Minimalist interface for audio-only calls
///
/// Features:
/// - Audio call controls
/// - Call timer
/// - Network quality indicator
/// - Minimizable to background

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/agora_rtc_service.dart';
import '../config/app_theme.dart';

class AudioCallScreen extends StatefulWidget {
  final String callId;
  final String channelId;
  final String otherPartyName;
  final String otherPartyId;
  final bool isOutgoing;
  
  const AudioCallScreen({
    super.key,
    required this.callId,
    required this.channelId,
    required this.otherPartyName,
    required this.otherPartyId,
    this.isOutgoing = false,
  });
  
  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen>
    with SingleTickerProviderStateMixin {
  Timer? _callTimer;
  int _callDuration = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeCall();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  Future<void> _initializeCall() async {
    final agoraService = context.read<AgoraRtcService>();
    
    // Join the channel
    final token = '';  // In production, get token from your server
    final uid = DateTime.now().millisecondsSinceEpoch % 1000000;
    
    await agoraService.joinChannel(widget.channelId, token, uid);
    
    // Start call timer
    _startCallTimer();
  }
  
  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }
  
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  Future<void> _endCall() async {
    final agoraService = context.read<AgoraRtcService>();
    await agoraService.leaveChannel();
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
  
  @override
  void dispose() {
    _callTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AgoraRtcService>(
        builder: (context, agoraService, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.7),
                  AppTheme.secondaryColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar with back button
                  _buildTopBar(),
                  
                  const Spacer(),
                  
                  // User avatar and info
                  _buildUserInfo(),
                  
                  const SizedBox(height: 40),
                  
                  // Call status
                  _buildCallStatus(agoraService),
                  
                  const Spacer(),
                  
                  // Call controls
                  _buildControls(agoraService),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Minimize to background (not implemented yet)
              // For now, just end the call
              _endCall();
            },
          ),
          const Spacer(),
          // Network quality indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.signal_cellular_alt, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Gut',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserInfo() {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.otherPartyName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          widget.otherPartyName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCallStatus(AgoraRtcService agoraService) {
    String status;
    if (!agoraService.isInCall) {
      status = widget.isOutgoing ? 'Rufe an...' : 'Verbinde...';
    } else {
      status = _formatDuration(_callDuration);
    }
    
    return Column(
      children: [
        if (!agoraService.isInCall)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
        Text(
          status,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildControls(AgoraRtcService agoraService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: agoraService.isMuted ? Icons.mic_off : Icons.mic,
            label: agoraService.isMuted ? 'Unmute' : 'Mute',
            isActive: !agoraService.isMuted,
            onTap: () => agoraService.toggleMute(),
          ),
          _buildControlButton(
            icon: Icons.call_end,
            label: 'Auflegen',
            isEndCall: true,
            onTap: _endCall,
          ),
          _buildControlButton(
            icon: agoraService.isSpeakerOn
                ? Icons.volume_up
                : Icons.volume_off,
            label: agoraService.isSpeakerOn ? 'Lautsprecher' : 'Hörmuschel',
            isActive: agoraService.isSpeakerOn,
            onTap: () => agoraService.toggleSpeaker(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isEndCall = false,
  }) {
    final backgroundColor = isEndCall
        ? Colors.red
        : isActive
            ? Colors.white
            : Colors.white.withOpacity(0.3);
    
    final iconColor = isEndCall
        ? Colors.white
        : isActive
            ? AppTheme.primaryColor
            : Colors.white;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
