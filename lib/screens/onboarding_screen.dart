import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      emoji: '📚',
      title: 'Willkommen in der\nWeltenbibliothek',
      description: 'Entdecke verborgenes Wissen, Mysterien und '
          'alternative Geschichte aus aller Welt.',
      color: AppTheme.primaryPurple,
    ),
    OnboardingPage(
      emoji: '🌍',
      title: 'Live-Daten\nin Echtzeit',
      description: 'Verfolge Erdbeben (USGS), ISS-Position (NASA) '
          'und Schumann-Resonanz in Echtzeit.',
      color: AppTheme.alienContact,
    ),
    OnboardingPage(
      emoji: '💬',
      title: 'Telegram\nIntegration',
      description: 'Synchronisiere Nachrichten bidirektional mit '
          'Telegram und teile deine Entdeckungen.',
      color: AppTheme.secondaryGold,
    ),
    OnboardingPage(
      emoji: '🗺️',
      title: 'Interaktive\nKarten',
      description: 'Erkunde Ley-Linien, Kraftorte und mystische '
          'Phänomene auf interaktiven Weltkarten.',
      color: AppTheme.dimensionalAnomalies,
    ),
    OnboardingPage(
      emoji: '🔮',
      title: 'Bereit für die\nReise?',
      description: 'Tauche ein in die Chroniken der verborgenen Pfade '
          'und entdecke die Wahrheit.',
      color: AppTheme.occultEvents,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Animierter Hintergrund
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.backgroundDark,
                      AppTheme.surfaceDark,
                      _pages[_currentPage].color.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ).animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              ).shimmer(
                duration: 3000.ms,
                color: _pages[_currentPage].color.withValues(alpha: 0.1),
              ),
            ),
            
            // PageView
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildPageContent(_pages[index]);
              },
            ),
            
            // Top Bar mit Skip Button
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: _skipOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.secondaryGold,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Überspringen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate()
                .fadeIn(delay: 300.ms),
            ),
            
            // Bottom Navigation
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildPageIndicator(index),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Next/Start Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pages[_currentPage].color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: _pages[_currentPage].color
                              .withValues(alpha: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1
                                  ? 'Jetzt starten'
                                  : 'Weiter',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == _pages.length - 1
                                  ? Icons.check_circle
                                  : Icons.arrow_forward,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          
          // Emoji mit Animation
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  page.color.withValues(alpha: 0.3),
                  page.color.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: const TextStyle(fontSize: 80),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              duration: 2000.ms,
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.1, 1.1),
            ),
          
          const SizedBox(height: 48),
          
          // Titel
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: page.color,
              height: 1.2,
              shadows: [
                Shadow(
                  color: page.color.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
          ).animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0, delay: 200.ms),
          
          const SizedBox(height: 24),
          
          // Beschreibung
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textWhite.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ).animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0, delay: 400.ms),
          
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    final color = _pages[_currentPage].color;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? color
            : color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

class OnboardingPage {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  const OnboardingPage({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });
}
