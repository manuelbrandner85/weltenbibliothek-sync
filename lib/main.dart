import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/intro_screen.dart';
import 'screens/onboarding_screen.dart'; // NEU: Interaktiver Onboarding
import 'screens/login_screen.dart';
import 'screens/modern_home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/live_dashboard_screen.dart';
import 'screens/more_screen.dart';
// Chat List Screen entfernt - Chat ist jetzt im Telegram Tab integriert
// import 'screens/chat_list_screen.dart';
import 'screens/unified_telegram_screen.dart'; // v3.1.0 - Benutzerfreundlicher Telegram Screen mit Chat
import 'widgets/modern_bottom_nav.dart'; // v3.0.0 - Moderne Bottom Navigation
import 'package:shared_preferences/shared_preferences.dart';
import 'services/fcm_service.dart';
import 'services/presence_service.dart';
import 'services/chat_service.dart';
import 'services/auth_service.dart';
import 'services/offline_storage_service.dart';
import 'services/telegram_service.dart'; // v2.13.0 - Telegram Integration
import 'services/telegram_background_service.dart'; // v2.14.5 - Background Service (Phase 2.2)
import 'services/telegram_bot_service.dart'; // v2.21.0 - Bot API Integration (Phase 6.2)
import 'services/audio_player_service.dart'; // Phase 4 - Background Audio
// ✅ NEU: Live-Data Services
import 'services/telegram_channel_loader.dart'; // NEU: Automatischer Channel Content Loader
import 'services/chat_sync_service.dart'; // v3.0.0+86 - Bidirektionale Telegram Chat Sync

// NEU: Background Message Handler (Phase 3)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📨 Background message: ${message.notification?.title}');
}

void main() async {
  // Flutter Engine initialisieren
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase initialisieren (mit Fehlerbehandlung)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase erfolgreich initialisiert');
    
    // ✅ VERBESSERUNG: Firestore Offline-Persistenz aktivieren
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint('✅ Firestore Offline-Persistenz aktiviert');
    
    // ✅ NEU: Hive Offline Storage initialisieren
    await OfflineStorageService.initialize();
    debugPrint('✅ Hive Offline Storage initialisiert');
    
    // NEU: FCM Background Handler registrieren (Phase 3)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // NEU: Services initialisieren (Phase 3)
    await FCMService().initialize();
    await PresenceService().initialize();
    
    // Live-Data Services entfernt - nicht für Telegram relevant
    
    // v2.13.0: Telegram Service initialisieren
    try {
      final telegramService = TelegramService();
      await telegramService.initialize();
      debugPrint('✅ Telegram Service initialisiert');
      
      // ✅ NEU: Starte Telegram Bot Polling für Echtzeit-Sync
      telegramService.startPolling();
      debugPrint('✅ Telegram Bot Polling gestartet (Echtzeit-Sync aktiv)');
    } catch (e) {
      debugPrint('⚠️ Telegram Service Fehler: $e');
    }
    
    // v2.14.5: Telegram Background Service initialisieren (Phase 2.2)
    try {
      await TelegramBackgroundService.initialize();
      debugPrint('✅ Telegram Background Service initialisiert');
    } catch (e) {
      debugPrint('⚠️ Telegram Background Service Fehler: $e');
    }
    
    // v3.0.0+86: Telegram Chat Sync Service initialisieren (Bidirektionale Synchronisation)
    try {
      await ChatSyncService().initialize();
      debugPrint('✅ Chat Sync Service initialisiert (bidirektionale Telegram Synchronisation)');
    } catch (e) {
      debugPrint('⚠️ Chat Sync Service Fehler: $e');
    }
    
    // ✅ NEU: Telegram Channel Content Loader (Automatisch beim Start)
    try {
      final channelLoader = TelegramChannelLoader();
      await channelLoader.initialize();
      debugPrint('✅ Channel Content Loader gestartet');
    } catch (e) {
      debugPrint('⚠️ Channel Content Loader Fehler: $e');
    }
    
  } catch (e) {
    debugPrint('⚠️ Firebase Initialisierung übersprungen: $e');
    debugPrint('💡 Tipp: Konfiguriere firebase_options.dart für Firebase-Features');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TelegramBotService()), // Phase 6.2 - Bot API
        ChangeNotifierProvider(create: (_) => AudioPlayerService()), // Phase 4 - Audio
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Weltenbibliothek',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthGate(),
          routes: {
            '/home': (context) => const IntroWrapper(),
            '/login': (context) => const LoginScreen(),
          },
        );
      },
    );
  }
}

/// Auth Gate - Entscheidet zwischen Login und App
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _loadUserNameForTelegram();
  }

  /// ✅ Lade Benutzername beim App-Start für Telegram-Integration
  Future<void> _loadUserNameForTelegram() async {
    final user = AuthService().currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final displayName = userDoc.data()?['displayName'] ?? 
                             user.displayName ?? 
                             'Unbekannt';
          
          // Setze Benutzername für Telegram-Integration
          final telegramService = TelegramBotService();
          await telegramService.setCurrentUserName(displayName);
          debugPrint('✅ Telegram Benutzername gesetzt: $displayName');
        }
      } catch (e) {
        debugPrint('⚠️ Fehler beim Laden des Benutzernamens: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundDark,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryGold),
            ),
          );
        }

        // User logged in
        if (snapshot.hasData) {
          // ✅ Lade Benutzername wenn User sich einloggt
          _loadUserNameForTelegram();
          return const IntroWrapper();
        }

        // User not logged in
        return const LoginScreen();
      },
    );
  }
}

class IntroWrapper extends StatefulWidget {
  const IntroWrapper({super.key});

  @override
  State<IntroWrapper> createState() => _IntroWrapperState();
}

class _IntroWrapperState extends State<IntroWrapper> {
  bool _showIntro = true;
  bool _showOnboarding = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('onboarding_completed') ?? false;
    
    setState(() {
      _showOnboarding = !hasSeenOnboarding;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.secondaryGold),
        ),
      );
    }
    
    // Zeige Onboarding beim ersten Start
    if (_showOnboarding) {
      return const OnboardingScreen();
    }
    
    // Zeige normale Intro-Animation
    if (_showIntro) {
      return IntroScreen(
        onComplete: () {
          setState(() {
            _showIntro = false;
          });
        },
      );
    }
    
    return const MainNavigationScreen();
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final ChatService _chatService = ChatService();
  
  final List<Widget> _screens = const [
    ModernHomeScreen(), // 🎨 Moderner Home Screen (stabil)
    MapScreen(),
    UnifiedTelegramScreen(), // v3.1.0 - Benutzerfreundlicher Telegram Screen mit Chat (inkl. weltenbibliothek_chat)
    LiveDashboardScreen(),
    TimelineScreen(),
    // ChatListScreen() entfernt - Chat ist jetzt im Telegram Tab integriert
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: StreamBuilder<int>(
        stream: _chatService.getUnreadMessagesCount(),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;
          
          return ModernBottomNav(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            unreadCount: unreadCount,
            isDark: isDark,
          );
        },
      ),
    );
  }
}
