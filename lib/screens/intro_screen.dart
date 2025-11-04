import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';

class IntroScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const IntroScreen({super.key, required this.onComplete});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showContent = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Hintergrund-Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [
                      AppTheme.primaryPurple.withValues(alpha: 0.15),
                      AppTheme.backgroundDark,
                    ],
                  ),
                ),
              ),
            ),
            
            // Hauptinhalt - KEIN SCROLLING
            if (_showContent)
              Column(
                children: [
                  // Header mit App Icon (20% der Höhe)
                  SizedBox(
                    height: screenHeight * 0.20,
                    child: Center(child: _buildAppIcon()),
                  ),
                  
                  // Titel & Untertitel (10% der Höhe)
                  SizedBox(
                    height: screenHeight * 0.10,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTitle(),
                        const SizedBox(height: 4),
                        _buildSubtitle(),
                      ],
                    ),
                  ),
                  
                  // Quick Guide - 4 Funktionen (48% der Höhe)
                  SizedBox(
                    height: screenHeight * 0.48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildQuickGuide(),
                    ),
                  ),
                  
                  // Start Button (22% der Höhe)
                  SizedBox(
                    height: screenHeight * 0.22,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildStartButton(),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/icons/app_icon.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: AppTheme.secondaryGold.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
    )
      .animate()
      .scale(
        begin: const Offset(0, 0),
        end: const Offset(1, 1),
        duration: 800.ms,
        curve: Curves.elasticOut,
      )
      .fadeIn(duration: 600.ms)
      .then()
      .shimmer(
        duration: 2000.ms,
        color: AppTheme.secondaryGold.withValues(alpha: 0.3),
      );
  }

  Widget _buildTitle() {
    return Text(
      'Weltenbibliothek',
      style: AppTheme.headlineLarge.copyWith(fontSize: 28),
      textAlign: TextAlign.center,
    )
      .animate()
      .fadeIn(delay: 300.ms, duration: 600.ms)
      .slideY(begin: 0.3, end: 0);
  }

  Widget _buildSubtitle() {
    return Text(
      'Chroniken der verborgenen Pfade',
      style: TextStyle(
        fontSize: 14,
        color: AppTheme.secondaryGold,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.8,
      ),
      textAlign: TextAlign.center,
    )
      .animate()
      .fadeIn(delay: 500.ms, duration: 600.ms);
  }

  Widget _buildQuickGuide() {
    return Column(
      children: [
        Text(
          'Wichtigste Funktionen',
          style: AppTheme.headlineSmall.copyWith(fontSize: 16),
        ).animate().fadeIn(delay: 700.ms),
        
        const SizedBox(height: 16),
        
        // Grid mit 4 Features (2x2)
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildFeatureTile('🗺️', 'Weltkarte', '161 Events\n27.025 Jahre', 0),
              _buildFeatureTile('⚡', 'Ley-Linien', '15 echte\nVerbindungen', 1),
              _buildFeatureTile('🌍', 'Live-Daten', 'Erdbeben\nISS Position', 2),
              _buildFeatureTile('📚', 'Kategorien', '10 Themen\nVerschwörungen', 3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureTile(String icon, String title, String desc, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withValues(alpha: 0.1),
            AppTheme.backgroundDark.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: AppTheme.bodySmall.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    )
      .animate()
      .fadeIn(delay: Duration(milliseconds: 900 + (index * 100)))
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }

  // Disclaimer entfernt - mehr Platz für Features und Button

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryPurple,
              AppTheme.primaryPurple.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onComplete,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Jetzt Entdecken',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: AppTheme.textWhite,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
      .animate(onPlay: (controller) => controller.repeat(reverse: true))
      .shimmer(duration: 2000.ms, color: AppTheme.secondaryGold.withValues(alpha: 0.3))
      .animate()
      .fadeIn(delay: 1500.ms, duration: 600.ms)
      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}
