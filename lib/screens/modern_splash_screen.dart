// 💫 WELTENBIBLIOTHEK - MODERNE SPLASH SCREEN
// Professioneller Ladebildschirm mit Animationen

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/modern_design_system.dart';

class ModernSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const ModernSplashScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<ModernSplashScreen> createState() => _ModernSplashScreenState();
}

class _ModernSplashScreenState extends State<ModernSplashScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-Finish nach 3 Sekunden
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: ModernGradients.cosmicGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo mit Animation
                Container(
                  padding: const EdgeInsets.all(ModernSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: ModernShadows.glow(Colors.white),
                  ),
                  child: const Text(
                    '📚',
                    style: TextStyle(fontSize: 80),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(begin: const Offset(0.5, 0.5), duration: 800.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: ModernSpacing.xl),
                
                // App Name
                Text(
                  'Weltenbibliothek',
                  style: ModernTypography.h1.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                
                const SizedBox(height: ModernSpacing.sm),
                
                // Tagline
                Text(
                  'Chroniken der verborgenen Pfade',
                  style: ModernTypography.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                
                const SizedBox(height: ModernSpacing.xxxl),
                
                // Loading Indicator
                SizedBox(
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ModernRadius.pill),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ModernColors.goldenHoney,
                      ),
                    ),
                  ),
                )
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
                
                const SizedBox(height: ModernSpacing.lg),
                
                // Loading Text
                Text(
                  'Lade verborgenes Wissen...',
                  style: ModernTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                )
                    .animate(delay: 1000.ms)
                    .fadeIn(duration: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
