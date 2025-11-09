import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Notification Service
/// Verwaltet Firebase Cloud Messaging und lokale Benachrichtigungen
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  /// Initialisiere Notifications
  Future<void> initialize() async {
    // Request Permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        debugPrint('✅ Notification Permission granted');
      }
      
      // Configure Local Notifications
      await _configureLocalNotifications();
      
      // Get FCM Token
      final token = await _messaging.getToken();
      if (kDebugMode) {
        debugPrint('📱 FCM Token: $token');
      }
      
      // Listen to Foreground Messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Listen to Background Messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      
    } else {
      if (kDebugMode) {
        debugPrint('⚠️ Notification Permission denied');
      }
    }
  }
  
  /// Configure Local Notifications
  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }
  
  /// Handle Foreground Message
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('📥 Foreground Message: ${message.notification?.title}');
    }
    
    // Show Local Notification
    _showLocalNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'Neue Nachricht',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }
  
  /// Handle Background Message
  void _handleBackgroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('📥 Background Message: ${message.notification?.title}');
    }
    
    // Handle navigation or other actions
  }
  
  /// Show Local Notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'weltenbibliothek_channel',
      'Weltenbibliothek',
      channelDescription: 'Benachrichtigungen für neue Inhalte',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  /// Notification Tap Handler
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('🔔 Notification Tapped: ${response.payload}');
    }
    
    // Handle navigation based on payload
  }
  
  /// Subscribe to Topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        debugPrint('✅ Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Topic subscription failed: $e');
      }
    }
  }
  
  /// Unsubscribe from Topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        debugPrint('✅ Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Topic unsubscription failed: $e');
      }
    }
  }
  
  /// Get FCM Token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}

/// Background Message Handler (Top-Level Function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('📥 Background Message Handler: ${message.notification?.title}');
  }
}
