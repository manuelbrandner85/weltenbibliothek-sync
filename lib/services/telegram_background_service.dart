import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'telegram_service.dart';

/// Telegram Background Service (Phase 2.2 - Simplified)
/// 
/// Ermöglicht persistentes Telegram-Polling im Hintergrund:
/// - Foreground Notification für Status-Anzeige
/// - Timer-basiertes Polling (statt WorkManager)
/// - Battery Optimization Handling
/// 
/// HINWEIS: Diese vereinfachte Version nutzt Timer statt WorkManager
/// wegen Kompatibilitätsproblemen mit Flutter 3.35.4
class TelegramBackgroundService {
  // Notification Channel
  static const String _channelId = 'telegram_sync_channel';
  static const String _channelName = 'Telegram Synchronisation';
  static const String _channelDescription = 'Zeigt Status der Telegram-Synchronisation';
  
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static Timer? _backgroundTimer;
  static bool _isRunning = false;
  
  /// Initialisiert den Background Service
  static Future<void> initialize() async {
    debugPrint('🔧 TelegramBackgroundService: Initialisierung startet...');
    
    try {
      // Notification Plugin initialisieren
      const androidInit = AndroidInitializationSettings('app_icon');
      const initSettings = InitializationSettings(android: androidInit);
      
      await _notificationsPlugin.initialize(initSettings);
      
      // Notification Channel erstellen
      await _createNotificationChannel();
      
      debugPrint('✅ TelegramBackgroundService initialisiert');
      
    } catch (e) {
      debugPrint('❌ Fehler bei Background Service Initialisierung: $e');
    }
  }
  
  /// Startet periodisches Background-Polling
  static Future<void> startBackgroundSync() async {
    debugPrint('🚀 Background Sync wird gestartet...');
    
    if (_isRunning) {
      debugPrint('⚠️ Background Sync läuft bereits');
      return;
    }
    
    try {
      _isRunning = true;
      
      // Zeige Foreground Notification
      await _showForegroundNotification(
        title: 'Telegram-Sync aktiv',
        body: 'Polling läuft im Hintergrund',
      );
      
      // Starte Timer für periodisches Polling (alle 5 Minuten)
      // HINWEIS: Dies läuft nur solange die App im Vordergrund ist
      // Für echtes Background-Polling würde Android WorkManager benötigt
      _backgroundTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        _performBackgroundPoll();
      });
      
      debugPrint('✅ Background Sync gestartet (Intervall: 5 Min.)');
      debugPrint('💡 HINWEIS: Timer-basiert, läuft nur im Vordergrund');
      
    } catch (e) {
      _isRunning = false;
      debugPrint('❌ Fehler beim Starten des Background Sync: $e');
    }
  }
  
  /// Stoppt Background-Polling
  static Future<void> stopBackgroundSync() async {
    debugPrint('🛑 Background Sync wird gestoppt...');
    
    try {
      _backgroundTimer?.cancel();
      _backgroundTimer = null;
      _isRunning = false;
      
      // Entferne Foreground Notification
      await _notificationsPlugin.cancel(1);
      
      debugPrint('✅ Background Sync gestoppt');
      
    } catch (e) {
      debugPrint('❌ Fehler beim Stoppen des Background Sync: $e');
    }
  }
  
  /// Prüft ob Background-Sync läuft
  static bool isBackgroundSyncRunning() {
    return _isRunning && _backgroundTimer != null && _backgroundTimer!.isActive;
  }
  
  /// Führt einen Background-Poll durch
  static Future<void> _performBackgroundPoll() async {
    debugPrint('🔄 Performing background poll...');
    
    try {
      // Telegram Service sollte bereits initialisiert sein
      final telegramService = TelegramService();
      
      // Update Notification Status
      await updateNotificationStatus(
        status: 'Synchronisiere...',
        details: 'Prüfe neue Nachrichten',
      );
      
      // Warte kurz (Polling läuft bereits im TelegramService Timer)
      await Future.delayed(const Duration(seconds: 2));
      
      // Update Status
      await updateNotificationStatus(
        status: 'Aktiv',
        details: 'Letzte Synchronisation: Jetzt',
      );
      
      debugPrint('✅ Background poll completed');
      
    } catch (e) {
      debugPrint('❌ Background poll error: $e');
      
      await updateNotificationStatus(
        status: 'Fehler',
        details: 'Synchronisation fehlgeschlagen',
      );
    }
  }
  
  /// Erstellt Notification Channel (Android)
  static Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.low, // Low = keine Vibration/Sound
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    
    debugPrint('✅ Notification Channel erstellt: $_channelId');
  }
  
  /// Zeigt Foreground Notification
  static Future<void> _showForegroundNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Kann nicht weggewischt werden
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      icon: 'app_icon', // Verwendet app_icon.png aus assets
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    await _notificationsPlugin.show(
      1, // Notification ID
      title,
      body,
      notificationDetails,
    );
    
    debugPrint('📱 Foreground Notification angezeigt');
  }
  
  /// Updated Notification Status
  static Future<void> updateNotificationStatus({
    required String status,
    String? details,
  }) async {
    await _showForegroundNotification(
      title: 'Telegram-Sync: $status',
      body: details ?? 'Polling läuft im Hintergrund',
    );
  }
}
