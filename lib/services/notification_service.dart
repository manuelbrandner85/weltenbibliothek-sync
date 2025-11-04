import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

/// Service for managing push notifications and live data alerts
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? get currentUserId => _auth.currentUser?.uid;

  /// Initialize notification service
  Future<void> initialize() async {
    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null && currentUserId != null) {
      await _saveFcmToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveFcmToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('📱 Notification Permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications for Android/iOS
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  /// Save FCM token to Firestore
  Future<void> _saveFcmToken(String token) async {
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).update({
      'fcmToken': token,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    });

    print('📱 FCM Token saved: ${token.substring(0, 20)}...');
  }

  /// Handle foreground message
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Foreground Message: ${message.notification?.title}');

    // Show local notification
    await showLocalNotification(
      title: message.notification?.title ?? 'Weltenbibliothek',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );

    // Save to Firestore
    await _saveNotificationToFirestore(message);
  }

  /// Handle background message tap
  void _handleBackgroundMessage(RemoteMessage message) {
    print('📨 Background Message Opened: ${message.notification?.title}');
    // Navigate to relevant screen based on message.data
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    print('👆 Notification Tapped: ${response.payload}');
    // Navigate based on payload
  }

  /// Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'weltenbibliothek_channel',
      'Weltenbibliothek Notifications',
      channelDescription: 'Benachrichtigungen über Events, Kommentare und Live-Daten',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Save notification to Firestore for history
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    if (currentUserId == null) return;

    await _firestore.collection('notifications').add({
      'userId': currentUserId,
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  /// Get notification settings for current user
  Future<AppNotificationSettings> getSettings() async {
    if (currentUserId == null) {
      return AppNotificationSettings();
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        return AppNotificationSettings.fromMap(doc.data()!);
      }
    } catch (e) {
      print('❌ Error loading notification settings: $e');
    }

    return AppNotificationSettings();
  }

  /// Update notification settings
  Future<void> updateSettings(AppNotificationSettings settings) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('settings')
        .doc('notifications')
        .set(settings.toMap(), SetOptions(merge: true));
  }

  /// Get notification history stream
  Stream<List<AppNotification>> getNotificationHistory() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppNotification(
          id: doc.id,
          type: _parseNotificationType(data['data']?['type']),
          priority: _parseNotificationPriority(data['data']?['priority']),
          title: data['title'] as String? ?? '',
          body: data['body'] as String? ?? '',
          data: data['data'] as Map<String, dynamic>?,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] as bool? ?? false,
        );
      }).toList();
    });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;

    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  /// Parse notification type from string
  NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'comment':
        return NotificationType.comment;
      case 'rating':
        return NotificationType.rating;
      case 'newEvent':
        return NotificationType.newEvent;
      case 'earthquake':
        return NotificationType.earthquake;
      case 'volcano':
        return NotificationType.volcano;
      case 'ufoSighting':
        return NotificationType.ufoSighting;
      case 'solarStorm':
        return NotificationType.solarStorm;
      default:
        return NotificationType.newEvent;
    }
  }

  /// Parse notification priority from string
  NotificationPriority _parseNotificationPriority(String? priority) {
    switch (priority) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }
}
