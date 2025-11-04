import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registrierung erfolgreich! Willkommen in der Weltenbibliothek.'),
            backgroundColor: AppTheme.secondaryGold,
          ),
        );
        
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrierung'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
                  children: [
                    // Header
                    _buildHeader(),
                    
                    const SizedBox(height: 32),
                    
                    // Register Form
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      borderRadius: BorderRadius.circular(24),
                      blur: 20,
                      opacity: 0.1,
                      border: Border.all(
                        color: AppTheme.secondaryGold.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryGold.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                      child: Column(
                        children: [
                          // Name Field
                          _buildNameField(),
                          
                          const SizedBox(height: 16),
                          
                          // Email Field
                          _buildEmailField(),
                          
                          const SizedBox(height: 16),
                          
                          // Password Field
                          _buildPasswordField(),
                          
                          const SizedBox(height: 16),
                          
                          // Confirm Password Field
                          _buildConfirmPasswordField(),
                          
                          const SizedBox(height: 24),
                          
                          // Register Button
                          _buildRegisterButton(),
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
        // App Icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryGold.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ).animate()
          .fadeIn()
          .scale(delay: 100.ms),
        
        const SizedBox(height: 24),
        
        Text(
          'Konto erstellen',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ).animate()
          .fadeIn(delay: 100.ms)
          .slideX(begin: -0.2, end: 0, delay: 100.ms),
        
        const SizedBox(height: 8),
        
        Text(
          'Tritt der Weltenbibliothek bei',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.secondaryGold,
          ),
        ).animate()
          .fadeIn(delay: 150.ms),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: AppTheme.textWhite),
      decoration: InputDecoration(
        labelText: 'Name',
        labelStyle: TextStyle(color: AppTheme.textWhite.withValues(alpha: 0.7)),
        prefixIcon: Icon(Icons.person, color: AppTheme.secondaryGold),
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
          return 'Bitte Namen eingeben';
        }
        if (value.length < 2) {
          return 'Name muss mindestens 2 Zeichen lang sein';
        }
        return null;
      },
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

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      style: const TextStyle(color: AppTheme.textWhite),
      decoration: InputDecoration(
        labelText: 'Passwort bestätigen',
        labelStyle: TextStyle(color: AppTheme.textWhite.withValues(alpha: 0.7)),
        prefixIcon: Icon(Icons.lock_outline, color: AppTheme.secondaryGold),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.textWhite.withValues(alpha: 0.7),
          ),
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
          return 'Bitte Passwort bestätigen';
        }
        if (value != _passwordController.text) {
          return 'Passwörter stimmen nicht überein';
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryGold,
          foregroundColor: AppTheme.textDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: AppTheme.secondaryGold.withValues(alpha: 0.5),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.textDark,
                ),
              )
            : const Text(
                'Registrieren',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
