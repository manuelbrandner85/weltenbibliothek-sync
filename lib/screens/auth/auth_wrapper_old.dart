import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../main.dart';
import 'login_screen.dart';

/// Auth Wrapper - decides whether to show login or main app
/// Listens to Firebase Auth state changes
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is logged in - show main app
        if (snapshot.hasData && snapshot.data != null) {
          return const IntroWrapper();
        }

        // User is not logged in - show login screen
        return const LoginScreen();
      },
    );
  }
}
