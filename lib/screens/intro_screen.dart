import 'package:flutter/material.dart';
import 'modern_splash_screen.dart';

class IntroScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const IntroScreen({super.key, required this.onComplete});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  Widget build(BuildContext context) {
    // Use modern splash screen
    return ModernSplashScreen(onComplete: widget.onComplete);
  }
}
