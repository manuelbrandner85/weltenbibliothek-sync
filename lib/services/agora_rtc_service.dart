/// Agora RTC Service for Video/Audio Calls
/// Provides unified interface for real-time communication
///
/// Features:
/// - 1-to-1 Video Calls
/// - 1-to-1 Audio Calls
/// - Group Calls
/// - Screen Sharing
/// - Call Recording
/// - Network Quality Monitoring

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Note: agora_rtc_engine package needs to be added to pubspec.yaml
// For now, we create the service structure ready for integration

class AgoraRtcService extends ChangeNotifier {
  static final AgoraRtcService _instance = AgoraRtcService._internal();
  factory AgoraRtcService() => _instance;
  AgoraRtcService._internal();

  // Configuration
  static const String appId = 'YOUR_AGORA_APP_ID'; // TODO: Add real App ID
  
  // State
  bool _isInitialized = false;
  bool _isInCall = false;
  String? _currentChannelId;
  String? _currentCallId;
  CallType _currentCallType = CallType.none;
  
  // Settings
  bool _isMuted = false;
  bool _isVideoDisabled = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  
  // Remote users
  final Set<int> _remoteUsers = {};
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isInCall => _isInCall;
  String? get currentChannelId => _currentChannelId;
  String? get currentCallId => _currentCallId;
  CallType get currentCallType => _currentCallType;
  bool get isMuted => _isMuted;
  bool get isVideoDisabled => _isVideoDisabled;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isFrontCamera => _isFrontCamera;
  Set<int> get remoteUsers => _remoteUsers;
  
  /// Initialize Agora RTC Engine
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      if (kDebugMode) {
        print('🎥 Initializing Agora RTC Engine...');
      }
      
      // TODO: Initialize Agora RTC Engine
      // await _engine = await RtcEngine.createWithContext(RtcEngineContext(appId));
      // await _engine.enableVideo();
      // await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
      // await _engine.setClientRole(ClientRole.Broadcaster);
      
      _isInitialized = true;
      notifyListeners();
      
      if (kDebugMode) {
        print('✅ Agora RTC Engine initialized');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Agora: $e');
      }
      return false;
    }
  }
  
  /// Start a video call
  Future<String?> startVideoCall({
    required String recipientUserId,
    required String recipientName,
  }) async {
    return await _startCall(
      recipientUserId: recipientUserId,
      recipientName: recipientName,
      callType: CallType.video,
    );
  }
  
  /// Start an audio call
  Future<String?> startAudioCall({
    required String recipientUserId,
    required String recipientName,
  }) async {
    return await _startCall(
      recipientUserId: recipientUserId,
      recipientName: recipientName,
      callType: CallType.audio,
    );
  }
  
  /// Internal method to start a call
  Future<String?> _startCall({
    required String recipientUserId,
    required String recipientName,
    required CallType callType,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Generate channel name
      final channelId = _generateChannelId(currentUser.uid, recipientUserId);
      
      // Create call document in Firestore
      final callRef = FirebaseFirestore.instance.collection('calls').doc();
      await callRef.set({
        'callId': callRef.id,
        'channelId': channelId,
        'callType': callType.name,
        'callerId': currentUser.uid,
        'callerName': currentUser.displayName ?? 'Unknown',
        'recipientId': recipientUserId,
        'recipientName': recipientName,
        'status': 'ringing',
        'startedAt': FieldValue.serverTimestamp(),
        'participants': [currentUser.uid, recipientUserId],
      });
      
      _currentCallId = callRef.id;
      _currentChannelId = channelId;
      _currentCallType = callType;
      
      if (kDebugMode) {
        print('📞 ${callType.name} call initiated to $recipientName');
      }
      
      return callRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to start call: $e');
      }
      return null;
    }
  }
  
  /// Join a call channel
  Future<bool> joinChannel(String channelId, String token, int uid) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      if (kDebugMode) {
        print('🔗 Joining channel: $channelId');
      }
      
      // TODO: Join Agora channel
      // await _engine.joinChannel(token, channelId, null, uid);
      
      _currentChannelId = channelId;
      _isInCall = true;
      
      // Update call status in Firestore
      if (_currentCallId != null) {
        await FirebaseFirestore.instance
            .collection('calls')
            .doc(_currentCallId)
            .update({
          'status': 'active',
          'connectedAt': FieldValue.serverTimestamp(),
        });
      }
      
      notifyListeners();
      
      if (kDebugMode) {
        print('✅ Joined channel successfully');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to join channel: $e');
      }
      return false;
    }
  }
  
  /// Leave the current call
  Future<void> leaveChannel() async {
    if (!_isInCall) return;
    
    try {
      if (kDebugMode) {
        print('👋 Leaving channel: $_currentChannelId');
      }
      
      // TODO: Leave Agora channel
      // await _engine.leaveChannel();
      
      // Update call status in Firestore
      if (_currentCallId != null) {
        await FirebaseFirestore.instance
            .collection('calls')
            .doc(_currentCallId)
            .update({
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp(),
        });
      }
      
      _isInCall = false;
      _currentChannelId = null;
      _currentCallId = null;
      _currentCallType = CallType.none;
      _remoteUsers.clear();
      
      // Reset settings
      _isMuted = false;
      _isVideoDisabled = false;
      _isSpeakerOn = true;
      
      notifyListeners();
      
      if (kDebugMode) {
        print('✅ Left channel successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to leave channel: $e');
      }
    }
  }
  
  /// Toggle microphone mute
  Future<void> toggleMute() async {
    if (!_isInCall) return;
    
    try {
      // TODO: Toggle audio
      // await _engine.muteLocalAudioStream(!_isMuted);
      
      _isMuted = !_isMuted;
      notifyListeners();
      
      if (kDebugMode) {
        print('🎤 Microphone ${_isMuted ? "muted" : "unmuted"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to toggle mute: $e');
      }
    }
  }
  
  /// Toggle video
  Future<void> toggleVideo() async {
    if (!_isInCall || _currentCallType != CallType.video) return;
    
    try {
      // TODO: Toggle video
      // await _engine.muteLocalVideoStream(!_isVideoDisabled);
      
      _isVideoDisabled = !_isVideoDisabled;
      notifyListeners();
      
      if (kDebugMode) {
        print('📹 Video ${_isVideoDisabled ? "disabled" : "enabled"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to toggle video: $e');
      }
    }
  }
  
  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (!_isInCall || _currentCallType != CallType.video) return;
    
    try {
      // TODO: Switch camera
      // await _engine.switchCamera();
      
      _isFrontCamera = !_isFrontCamera;
      notifyListeners();
      
      if (kDebugMode) {
        print('📷 Switched to ${_isFrontCamera ? "front" : "back"} camera');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to switch camera: $e');
      }
    }
  }
  
  /// Toggle speaker (earpiece/speaker)
  Future<void> toggleSpeaker() async {
    if (!_isInCall) return;
    
    try {
      // TODO: Toggle speaker
      // await _engine.setEnableSpeakerphone(!_isSpeakerOn);
      
      _isSpeakerOn = !_isSpeakerOn;
      notifyListeners();
      
      if (kDebugMode) {
        print('🔊 Speaker ${_isSpeakerOn ? "on" : "off"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to toggle speaker: $e');
      }
    }
  }
  
  /// Generate a unique channel ID for two users
  String _generateChannelId(String userId1, String userId2) {
    final users = [userId1, userId2]..sort();
    return '${users[0]}_${users[1]}_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Listen to incoming calls
  Stream<CallNotification?> listenToIncomingCalls() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value(null);
    }
    
    return FirebaseFirestore.instance
        .collection('calls')
        .where('recipientId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      
      final doc = snapshot.docs.first;
      final data = doc.data();
      
      return CallNotification(
        callId: data['callId'] as String,
        channelId: data['channelId'] as String,
        callType: CallType.values.firstWhere(
          (e) => e.name == data['callType'],
          orElse: () => CallType.audio,
        ),
        callerName: data['callerName'] as String,
        callerId: data['callerId'] as String,
      );
    });
  }
  
  /// Accept an incoming call
  Future<bool> acceptCall(String callId, String channelId) async {
    try {
      // Update call status
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(callId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      
      _currentCallId = callId;
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to accept call: $e');
      }
      return false;
    }
  }
  
  /// Reject an incoming call
  Future<bool> rejectCall(String callId) async {
    try {
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(callId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to reject call: $e');
      }
      return false;
    }
  }
  
  /// Get call history for current user
  Stream<List<CallHistoryItem>> getCallHistory() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }
    
    return FirebaseFirestore.instance
        .collection('calls')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('startedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CallHistoryItem(
          callId: data['callId'] as String,
          callType: CallType.values.firstWhere(
            (e) => e.name == data['callType'],
            orElse: () => CallType.audio,
          ),
          otherPartyName: data['callerId'] == currentUser.uid
              ? data['recipientName'] as String
              : data['callerName'] as String,
          otherPartyId: data['callerId'] == currentUser.uid
              ? data['recipientId'] as String
              : data['callerId'] as String,
          status: data['status'] as String,
          startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
          duration: data['duration'] as int? ?? 0,
          isOutgoing: data['callerId'] == currentUser.uid,
        );
      }).toList();
    });
  }
  
  /// Cleanup and dispose
  @override
  void dispose() {
    leaveChannel();
    // TODO: Destroy Agora engine
    // _engine.destroy();
    super.dispose();
  }
}

/// Call types
enum CallType {
  none,
  audio,
  video,
}

/// Call notification model
class CallNotification {
  final String callId;
  final String channelId;
  final CallType callType;
  final String callerName;
  final String callerId;
  
  CallNotification({
    required this.callId,
    required this.channelId,
    required this.callType,
    required this.callerName,
    required this.callerId,
  });
}

/// Call history item model
class CallHistoryItem {
  final String callId;
  final CallType callType;
  final String otherPartyName;
  final String otherPartyId;
  final String status;
  final DateTime? startedAt;
  final int duration;
  final bool isOutgoing;
  
  CallHistoryItem({
    required this.callId,
    required this.callType,
    required this.otherPartyName,
    required this.otherPartyId,
    required this.status,
    this.startedAt,
    required this.duration,
    required this.isOutgoing,
  });
  
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
