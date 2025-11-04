import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// FCM Service - Push Notifications (Phase 3)
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _fcmToken;
  bool _isInitialized = false;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Initialisiere FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _fcm.getToken();
      if (_fcmToken != null && currentUserId != null) {
        await _saveFCMToken(_fcmToken!);
      }

      // Listen to token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (currentUserId != null) {
          _saveFCMToken(newToken);
        }
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('✅ FCM Service initialisiert');
        debugPrint('📱 FCM Token: $_fcmToken');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler bei FCM Init: $e');
      }
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      debugPrint('✅ Notification permissions: ${settings.authorizationStatus}');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'weltenbibliothek_chat', // id
      'Chat Notifications', // name
      description: 'Benachrichtigungen für neue Chat-Nachrichten',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('✅ FCM Token gespeichert');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Token speichern: $e');
      }
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('📨 Foreground message: ${message.notification?.title}');
    }

    // Show local notification
    _showLocalNotification(message);
  }

  /// Handle message opened from background
  void _handleMessageOpened(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('📬 Message opened: ${message.data}');
    }

    // TODO: Navigate to chat
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'weltenbibliothek_chat',
      'Chat Notifications',
      channelDescription: 'Benachrichtigungen für neue Chat-Nachrichten',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('🔔 Notification tapped: ${response.payload}');
    }

    // TODO: Navigate to chat
  }

  /// Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        if (kDebugMode) {
          debugPrint('⚠️ User $userId hat keinen FCM Token');
        }
        return;
      }

      // NOTE: Actual sending requires Cloud Functions or backend server
      // This is just the client-side setup
      if (kDebugMode) {
        debugPrint('📤 Notification würde gesendet werden:');
        debugPrint('   To: $userId');
        debugPrint('   Title: $title');
        debugPrint('   Body: $body');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Notification senden: $e');
      }
    }
  }

  /// Subscribe to chat room topic
  Future<void> subscribeToChat(String chatRoomId) async {
    try {
      await _fcm.subscribeToTopic('chat_$chatRoomId');
      if (kDebugMode) {
        debugPrint('✅ Subscribed to chat_$chatRoomId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Subscribe: $e');
      }
    }
  }

  /// Unsubscribe from chat room topic
  Future<void> unsubscribeFromChat(String chatRoomId) async {
    try {
      await _fcm.unsubscribeFromTopic('chat_$chatRoomId');
      if (kDebugMode) {
        debugPrint('✅ Unsubscribed from chat_$chatRoomId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Unsubscribe: $e');
      }
    }
  }

  /// Get FCM token
  String? get fcmToken => _fcmToken;
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('📨 Background message: ${message.notification?.title}');
  }
}
