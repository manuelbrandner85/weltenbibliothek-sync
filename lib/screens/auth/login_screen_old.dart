import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_card.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // Navigate to main app
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Check if it's a Firebase Auth not enabled error
        if (errorMessage.contains('operation-not-allowed') || 
            errorMessage.contains('auth/operation-not-allowed')) {
          errorMessage = 'Firebase Authentication ist nicht aktiviert!\n\n'
              '📋 So aktivierst du es:\n'
              '1. Gehe zu console.firebase.google.com\n'
              '2. Wähle dein Projekt\n'
              '3. Build → Authentication\n'
              '4. Email/Password aktivieren';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte E-Mail-Adresse eingeben')),
      );
      return;
    }

    try {
      await _authService.resetPassword(email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Passwort-Reset-Link wurde per E-Mail gesendet'),
            backgroundColor: AppTheme.secondaryGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cosmicGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo & Title
                    _buildHeader(),
                    
                    const SizedBox(height: 48),
                    
                    // Login Form
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      borderRadius: BorderRadius.circular(24),
                      blur: 20,
                      opacity: 0.1,
                      border: Border.all(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                      child: Column(
                        children: [
                          // Email Field
                          _buildEmailField(),
                          
                          const SizedBox(height: 16),
                          
                          // Password Field
                          _buildPasswordField(),
                          
                          const SizedBox(height: 8),
                          
                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              child: Text(
                                'Passwort vergessen?',
                                style: TextStyle(
                                  color: AppTheme.secondaryGold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Login Button
                          _buildLoginButton(),
                          
                          const SizedBox(height: 16),
                          
                          // Register Link
                          _buildRegisterLink(),
                        ],
                      ),
                    ).animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.2, end: 0, delay: 200.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          '🌌',
          style: TextStyle(fontSize: 64),
        ).animate()
          .fadeIn()
          .scale(delay: 100.ms),
        
        const SizedBox(height: 16),
        
        Text(
          'Weltenbibliothek',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ).animate()
          .fadeIn(delay: 100.ms)
          .slideX(begin: -0.2, end: 0, delay: 100.ms),
        
        const SizedBox(height: 8),
        
        Text(
          'Chroniken der verborgenen Pfade',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.secondaryGold,
            fontStyle: FontStyle.italic,
          ),
        ).animate()
          .fadeIn(delay: 150.ms),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: AppTheme.textWhite),
      decoration: InputDecoration(
        labelText: 'E-Mail',
        labelStyle: TextStyle(color: AppTheme.textWhite.withValues(alpha: 0.7)),
        prefixIcon: Icon(Icons.email, color: AppTheme.secondaryGold),
        filled: true,
        fillColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryPurple.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bitte E-Mail eingeben';
        }
        if (!value.contains('@')) {
          return 'Ungültige E-Mail-Adresse';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: AppTheme.textWhite),
      decoration: InputDecoration(
        labelText: 'Passwort',
        labelStyle: TextStyle(color: AppTheme.textWhite.withValues(alpha: 0.7)),
        prefixIcon: Icon(Icons.lock, color: AppTheme.secondaryGold),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.textWhite.withValues(alpha: 0.7),
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryPurple.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bitte Passwort eingeben';
        }
        if (value.length < 6) {
          return 'Passwort muss mindestens 6 Zeichen lang sein';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPurple,
          foregroundColor: AppTheme.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: AppTheme.primaryPurple.withValues(alpha: 0.5),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.textWhite,
                ),
              )
            : const Text(
                'Anmelden',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Noch kein Konto? ',
          style: TextStyle(
            color: AppTheme.textWhite.withValues(alpha: 0.7),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            );
          },
          child: Text(
            'Jetzt registrieren',
            style: TextStyle(
              color: AppTheme.secondaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
