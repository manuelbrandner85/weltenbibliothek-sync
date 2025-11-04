import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/intro_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/library_screen.dart';
import 'screens/live_dashboard_screen.dart';
import 'screens/more_screen.dart';
import 'screens/chat_list_screen.dart';
import 'services/fcm_service.dart';
import 'services/presence_service.dart';
import 'services/chat_service.dart';
import 'services/auth_service.dart';

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
    
    // NEU: FCM Background Handler registrieren (Phase 3)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // NEU: Services initialisieren (Phase 3)
    await FCMService().initialize();
    await PresenceService().initialize();
    
  } catch (e) {
    debugPrint('⚠️ Firebase Initialisierung übersprungen: $e');
    debugPrint('💡 Tipp: Konfiguriere firebase_options.dart für Firebase-Features');
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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

  @override
  Widget build(BuildContext context) {
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
    MapScreen(),
    TimelineScreen(),
    LibraryScreen(),
    LiveDashboardScreen(),
    ChatListScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: StreamBuilder<int>(
          stream: _chatService.getUnreadMessagesCount(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: AppTheme.surfaceDark,
              selectedItemColor: AppTheme.secondaryGold,
              unselectedItemColor: AppTheme.textWhite.withValues(alpha: 0.6),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: 'Karte',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.timeline),
                  label: 'Timeline',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.library_books),
                  label: 'Bibliothek',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Live',
                ),
                BottomNavigationBarItem(
                  icon: unreadCount > 0
                      ? Badge(
                          label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          child: const Icon(Icons.chat_bubble),
                        )
                      : const Icon(Icons.chat_bubble),
                  label: 'Chat',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz),
                  label: 'Mehr',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
