/// Video Call Screen
/// Full-screen video calling interface with controls
///
/// Features:
/// - Local and remote video rendering
/// - Call controls (mute, video, camera switch, speaker)
/// - Call timer
/// - Network quality indicator
/// - Picture-in-Picture support

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/agora_rtc_service.dart';
import '../config/app_theme.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String channelId;
  final String otherPartyName;
  final String otherPartyId;
  final bool isOutgoing;
  
  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.channelId,
    required this.otherPartyName,
    required this.otherPartyId,
    this.isOutgoing = false,
  });
  
  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  Timer? _callTimer;
  int _callDuration = 0;
  bool _showControls = true;
  Timer? _controlsTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeCall();
    _startControlsTimer();
  }
  
  Future<void> _initializeCall() async {
    final agoraService = context.read<AgoraRtcService>();
    
    // Join the channel
    // TODO: Get token from backend
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
  
  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }
  
  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
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
    _controlsTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AgoraRtcService>(
        builder: (context, agoraService, child) {
          return GestureDetector(
            onTap: _toggleControlsVisibility,
            child: Stack(
              children: [
                // Remote video (full screen)
                _buildRemoteVideo(agoraService),
                
                // Local video (small preview)
                Positioned(
                  top: 60,
                  right: 20,
                  child: _buildLocalVideoPreview(agoraService),
                ),
                
                // Top info bar
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: _showControls ? 0 : -100,
                  left: 0,
                  right: 0,
                  child: _buildTopBar(),
                ),
                
                // Bottom controls
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  bottom: _showControls ? 0 : -200,
                  left: 0,
                  right: 0,
                  child: _buildControls(agoraService),
                ),
                
                // Connection status
                if (!agoraService.isInCall)
                  Center(
                    child: _buildConnectingIndicator(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildRemoteVideo(AgoraRtcService agoraService) {
    if (agoraService.remoteUsers.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  widget.otherPartyName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.otherPartyName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.isOutgoing ? 'Rufe an...' : 'Verbinde...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // TODO: Render remote video view
    // return AgoraVideoView(
    //   controller: VideoViewController.remote(
    //     rtcEngine: agoraService.engine,
    //     canvas: VideoCanvas(uid: agoraService.remoteUsers.first),
    //     connection: RtcConnection(channelId: widget.channelId),
    //   ),
    // );
    
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Text(
          'Remote Video',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
  
  Widget _buildLocalVideoPreview(AgoraRtcService agoraService) {
    if (agoraService.isVideoDisabled) {
      return Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Center(
          child: Icon(
            Icons.videocam_off,
            color: Colors.white,
            size: 40,
          ),
        ),
      );
    }
    
    // TODO: Render local video view
    // return ClipRRect(
    //   borderRadius: BorderRadius.circular(12),
    //   child: Container(
    //     width: 120,
    //     height: 160,
    //     decoration: BoxDecoration(
    //       border: Border.all(color: Colors.white, width: 2),
    //     ),
    //     child: AgoraVideoView(
    //       controller: VideoViewController(
    //         rtcEngine: agoraService.engine,
    //         canvas: const VideoCanvas(uid: 0),
    //       ),
    //     ),
    //   ),
    // );
    
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Center(
        child: Text(
          'Local Video',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
  
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherPartyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDuration(_callDuration),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          // Network quality indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
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
  
  Widget _buildControls(AgoraRtcService agoraService) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: agoraService.isMuted ? Icons.mic_off : Icons.mic,
            label: agoraService.isMuted ? 'Unmute' : 'Mute',
            color: agoraService.isMuted ? Colors.red : Colors.white,
            onTap: () => agoraService.toggleMute(),
          ),
          _buildControlButton(
            icon: agoraService.isVideoDisabled
                ? Icons.videocam_off
                : Icons.videocam,
            label: agoraService.isVideoDisabled ? 'Video Ein' : 'Video Aus',
            color: agoraService.isVideoDisabled ? Colors.red : Colors.white,
            onTap: () => agoraService.toggleVideo(),
          ),
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Kamera',
            color: Colors.white,
            onTap: () => agoraService.switchCamera(),
          ),
          _buildControlButton(
            icon: agoraService.isSpeakerOn
                ? Icons.volume_up
                : Icons.volume_off,
            label: agoraService.isSpeakerOn ? 'Lautsprecher' : 'Hörmuschel',
            color: Colors.white,
            onTap: () => agoraService.toggleSpeaker(),
          ),
          _buildControlButton(
            icon: Icons.call_end,
            label: 'Auflegen',
            color: Colors.red,
            onTap: _endCall,
            isLarge: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final size = isLarge ? 70.0 : 56.0;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                icon,
                color: color,
                size: isLarge ? 36 : 28,
              ),
            ),
          ),
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
    );
  }
  
  Widget _buildConnectingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            'Verbinde...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
