import 'package:flutter/material.dart';
import '../main.dart';

/// Simple wrapper that shows the main app after auth
class HomeNavigation extends StatelessWidget {
  const HomeNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    // After successful auth, show the main app starting with IntroWrapper
    return const IntroWrapper();
  }
}
