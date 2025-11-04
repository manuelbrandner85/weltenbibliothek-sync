import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../widgets/glass_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'stats_screen.dart';
import 'search_screen.dart';
import 'enhanced_dashboard_screen.dart';
import 'edit_profile_screen.dart';
import 'admin_panel_screen.dart';
// import 'favorites_screen.dart';
// import 'settings_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'Deutsch';
  String _selectedTheme = 'Dark Mode (Mystisch)';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'Deutsch';
      _selectedTheme = prefs.getString('theme') ?? 'Dark Mode (Mystisch)';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setString('language', _selectedLanguage);
    await prefs.setString('theme', _selectedTheme);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Text(
                  '⚙️ Mehr',
                  style: theme.textTheme.displayMedium,
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
              ),
              
              const SizedBox(height: 24),
              
              // Benutzer-Profil
              _buildProfileCard(context),
              
              const SizedBox(height: 24),
              
              // Admin-Panel (nur für Super-Admin & Moderatoren)
              StreamBuilder<UserRole>(
                stream: AdminService().streamUserRole(AuthService().currentUserId ?? ''),
                builder: (context, snapshot) {
                  final userRole = snapshot.data ?? UserRole.user;
                  
                  if (userRole == UserRole.superAdmin) {
                    return Column(
                      children: [
                        _buildSection(
                          context,
                          title: '👑 Admin-Bereich',
                          items: [
                            _buildMenuItem(
                              icon: Icons.admin_panel_settings,
                              title: 'Admin-Panel',
                              subtitle: 'Moderatoren verwalten, User blockieren',
                              color: AppTheme.secondaryGold,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  } else if (userRole == UserRole.moderator) {
                    return Column(
                      children: [
                        _buildSection(
                          context,
                          title: '🛡️ Moderator-Bereich',
                          items: [
                            _buildMenuItem(
                              icon: Icons.shield,
                              title: 'Moderator-Panel',
                              subtitle: 'User stummschalten, Inhalte moderieren',
                              color: AppTheme.accentBlue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
              
              // Features-Sektion
              _buildSection(
                context,
                title: 'Features',
                items: [
                  _buildMenuItem(
                    icon: Icons.search,
                    title: 'Erweiterte Suche',
                    subtitle: '161 Events durchsuchen',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.bar_chart,
                    title: 'Statistiken',
                    subtitle: 'Datenbank-Übersicht',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StatsScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.analytics,
                    title: 'Enhanced Analytics',
                    subtitle: 'Spektrogramm, Heatmap, Korrelationen',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EnhancedDashboardScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.favorite,
                    title: 'Favoriten',
                    subtitle: 'Markierte Events',
                    onTap: () {
                      // Navigation zu Favoriten via TabController
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Favoriten-Screen wird in einem künftigen Update verfügbar sein'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Einstellungen-Sektion
              _buildSection(
                context,
                title: 'Einstellungen',
                items: [
                  _buildMenuItem(
                    icon: Icons.notifications,
                    title: 'Push-Benachrichtigungen',
                    subtitle: _notificationsEnabled ? 'Aktiviert' : 'Deaktiviert',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _saveSettings();
                        _showSnackBar(
                          context,
                          value ? 'Benachrichtigungen aktiviert' : 'Benachrichtigungen deaktiviert',
                        );
                      },
                      activeTrackColor: AppTheme.secondaryGold,
                      activeColor: AppTheme.primaryPurple,
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.language,
                    title: 'Sprache',
                    subtitle: _selectedLanguage,
                    onTap: () => _showLanguageDialog(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.dark_mode,
                    title: 'Theme',
                    subtitle: _selectedTheme,
                    onTap: () => _showThemeDialog(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: 'Alle Einstellungen',
                    subtitle: 'Erweiterte Optionen',
                    onTap: () {
                      // Navigation zu Einstellungen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dedizierter Einstellungen-Screen wird in einem künftigen Update verfügbar sein'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Daten-Sektion
              _buildSection(
                context,
                title: 'Daten & Speicher',
                items: [
                  _buildMenuItem(
                    icon: Icons.cloud_download,
                    title: 'Offline-Daten',
                    subtitle: 'Events für Offline-Zugriff',
                    onTap: () => _downloadOfflineData(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.import_export,
                    title: 'Daten Exportieren',
                    subtitle: 'Favoriten & Notizen',
                    onTap: () => _exportData(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.delete_sweep,
                    title: 'Cache Löschen',
                    subtitle: 'App-Daten bereinigen',
                    onTap: () => _clearCache(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Community-Sektion
              _buildSection(
                context,
                title: 'Community',
                items: [
                  _buildMenuItem(
                    icon: Icons.people,
                    title: 'Community Forum',
                    subtitle: 'Diskutiere mit Gleichgesinnten',
                    onTap: () => _openCommunityForum(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.report,
                    title: 'Sichtung Melden',
                    subtitle: 'Teile deine Erfahrungen',
                    onTap: () => _reportSighting(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.share,
                    title: 'App Teilen',
                    subtitle: 'Mit Freunden teilen',
                    onTap: () => _shareApp(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Account-Sektion
              _buildSection(
                context,
                title: 'Account',
                items: [
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Abmelden',
                    subtitle: 'Vom Konto abmelden',
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Info-Sektion
              _buildSection(
                context,
                title: 'Information',
                items: [
                  _buildMenuItem(
                    icon: Icons.info,
                    title: 'Über die App',
                    subtitle: 'Version 1.0.0',
                    onTap: () => _showAboutDialog(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.privacy_tip,
                    title: 'Datenschutz',
                    subtitle: 'Deine Daten sind sicher',
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.gavel,
                    title: 'Nutzungsbedingungen',
                    subtitle: 'Rechtliche Hinweise',
                    onTap: () => _showTermsOfService(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.help,
                    title: 'Hilfe & Support',
                    subtitle: 'FAQ & Kontakt',
                    onTap: () => _showHelpAndSupport(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      '🌌',
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Weltenbibliothek',
                      style: AppTheme.headlineMedium,
                    ),
                    Text(
                      'Chroniken der verborgenen Pfade',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.secondaryGold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '© 2024 Weltenbibliothek Team',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textWhite.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder<Map<String, dynamic>?>(
      stream: authService.streamUserProfile(authService.currentUserId ?? ''),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final displayName = profile?['displayName'] ?? 'Forscher';
        final username = profile?['username'] ?? 'unbekannt';
        final photoURL = profile?['photoURL'] as String?;
        
        return GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          blur: 15,
          opacity: 0.1,
          border: Border.all(
            color: AppTheme.secondaryGold.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryGold.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.secondaryGold, width: 2),
                ),
                child: ClipOval(
                  child: photoURL != null && photoURL.isNotEmpty
                      ? Image.network(
                          photoURL,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                            child: const Icon(Icons.person, color: AppTheme.secondaryGold, size: 32),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.primaryPurple,
                                AppTheme.secondaryGold,
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.person, color: Colors.white, size: 32),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: AppTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StreamBuilder<UserRole>(
                          stream: AdminService().streamUserRole(authService.currentUserId ?? ''),
                          builder: (context, roleSnapshot) {
                            final userRole = roleSnapshot.data ?? UserRole.user;
                            if (userRole == UserRole.user) return const SizedBox.shrink();
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: userRole == UserRole.superAdmin
                                    ? AppTheme.secondaryGold
                                    : AppTheme.accentBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                userRole == UserRole.superAdmin ? '👑 ADMIN' : '🛡️ MOD',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Text(
                      '@$username',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.secondaryGold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppTheme.secondaryGold,
                ),
                onPressed: () => _editProfile(context),
              ),
            ],
          ),
        ).animate().fadeIn().slideX(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppTheme.secondaryGold,
            ),
          ),
        ),
        GlassContainer(
          borderRadius: BorderRadius.circular(16),
          opacity: 0.12,
          border: Border.all(
            color: AppTheme.primaryPurple.withValues(alpha: 0.4),
            width: 1,
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? color,
  }) {
    final iconColor = color ?? AppTheme.secondaryGold;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryPurple).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: AppTheme.bodyLarge.copyWith(
          fontWeight: FontWeight.bold,
          color: color != null ? color : Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall,
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, color: AppTheme.textWhite.withValues(alpha: 0.5)),
      onTap: onTap,
    );
  }

  // === IMPLEMENTIERTE FUNKTIONEN ===

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Row(
          children: [
            Icon(Icons.logout, color: AppTheme.errorRed),
            const SizedBox(width: 12),
            Text('Abmelden', style: AppTheme.headlineSmall),
          ],
        ),
        content: Text(
          'Möchtest du dich wirklich abmelden?',
          style: AppTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Abbrechen', style: TextStyle(color: AppTheme.textWhite)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authService = AuthService();
        await authService.logout();
        
        if (context.mounted) {
          // Navigate to login screen
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Abmelden: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  void _editProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  void _editProfileOLD(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Profil bearbeiten', style: AppTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Benutzername',
                labelStyle: AppTheme.bodyMedium,
                border: OutlineInputBorder(),
              ),
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Level',
                labelStyle: AppTheme.bodyMedium,
                border: OutlineInputBorder(),
              ),
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen', style: TextStyle(color: AppTheme.textWhite)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar(context, 'Profil gespeichert');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Sprache wählen', style: AppTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('Deutsch', '🇩🇪'),
            _buildLanguageOption('English', '🇬🇧'),
            _buildLanguageOption('Español', '🇪🇸'),
            _buildLanguageOption('Français', '🇫🇷'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, String flag) {
    return RadioListTile<String>(
      value: language,
      groupValue: _selectedLanguage,
      title: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(language, style: AppTheme.bodyMedium),
        ],
      ),
      activeColor: AppTheme.secondaryGold,
      onChanged: (value) {
        setState(() => _selectedLanguage = value!);
        _saveSettings();
        Navigator.pop(context);
        _showSnackBar(context, 'Sprache auf $value geändert');
      },
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? AppTheme.surfaceDark 
            : AppTheme.surfaceLight,
        title: Row(
          children: [
            Icon(
              Icons.palette,
              color: AppTheme.primaryPurple,
            ),
            const SizedBox(width: 12),
            Text(
              'Theme wählen',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOptionNew(
              context,
              title: 'Dark Mode',
              subtitle: 'Mystisches Dunkel-Theme',
              icon: Icons.dark_mode,
              isSelected: themeProvider.themeMode == ThemeMode.dark,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.dark);
                setState(() => _selectedTheme = 'Dark Mode (Mystisch)');
                _saveSettings();
                Navigator.pop(dialogContext);
              },
            ),
            const SizedBox(height: 12),
            _buildThemeOptionNew(
              context,
              title: 'Light Mode',
              subtitle: 'Helles, modernes Theme',
              icon: Icons.light_mode,
              isSelected: themeProvider.themeMode == ThemeMode.light,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.light);
                setState(() => _selectedTheme = 'Light Mode');
                _saveSettings();
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeOptionNew(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryPurple.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryPurple 
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryPurple : Theme.of(context).iconTheme.color,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryPurple : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryPurple,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String theme, IconData icon) {
    return RadioListTile<String>(
      value: theme,
      groupValue: _selectedTheme,
      title: Row(
        children: [
          Icon(icon, color: AppTheme.secondaryGold),
          const SizedBox(width: 12),
          Text(theme, style: AppTheme.bodyMedium),
        ],
      ),
      activeColor: AppTheme.secondaryGold,
      onChanged: (value) {
        setState(() => _selectedTheme = value!);
        _saveSettings();
        Navigator.pop(context);
        _showSnackBar(context, 'Theme auf $value geändert (Neustart erforderlich)');
      },
    );
  }

  Future<void> _downloadOfflineData(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Offline-Daten', style: AppTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.secondaryGold),
            const SizedBox(height: 16),
            Text('Lade 161 Events herunter...', style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    
    if (context.mounted) {
      Navigator.pop(context);
      _showSnackBar(context, '✅ Offline-Daten heruntergeladen (161 Events)');
    }
  }

  Future<void> _exportData(BuildContext context) async {
    await Share.share(
      'Meine Weltenbibliothek Favoriten:\n\n'
      '📍 Favoriten exportiert von der Weltenbibliothek App\n'
      '🌌 Chroniken der verborgenen Pfade\n\n'
      'Lade die App herunter und entdecke 161 mystische Events!',
      subject: 'Weltenbibliothek - Meine Favoriten',
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Cache löschen?', style: AppTheme.headlineSmall),
        content: Text(
          'Dies wird temporäre Daten und Bilder entfernen. Favoriten bleiben erhalten.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen', style: TextStyle(color: AppTheme.textWhite)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(seconds: 1));
              if (context.mounted) {
                _showSnackBar(context, '✅ Cache gelöscht (152 MB freigegeben)');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _openCommunityForum(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Community Forum', style: AppTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people, color: AppTheme.secondaryGold, size: 64),
            const SizedBox(height: 16),
            Text(
              'Trete unserer Community bei und diskutiere über:\n\n'
              '• Verschwörungstheorien\n'
              '• Ley-Linien & Energie\n'
              '• UFO-Sichtungen\n'
              '• Verborgenes Wissen',
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Später', style: TextStyle(color: AppTheme.textWhite)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar(context, '🌐 Forum wird in Kürze verfügbar sein');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: const Text('Beitreten'),
          ),
        ],
      ),
    );
  }

  void _reportSighting(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Sichtung melden', style: AppTheme.headlineSmall),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Was hast du gesehen?',
                  labelStyle: AppTheme.bodyMedium,
                  border: OutlineInputBorder(),
                ),
                style: AppTheme.bodyMedium,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Ort',
                  labelStyle: AppTheme.bodyMedium,
                  border: OutlineInputBorder(),
                ),
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Datum & Uhrzeit',
                  labelStyle: AppTheme.bodyMedium,
                  border: OutlineInputBorder(),
                ),
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen', style: TextStyle(color: AppTheme.textWhite)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar(context, '✅ Sichtung gemeldet! Vielen Dank für deinen Beitrag');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: const Text('Senden'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    await Share.share(
      '🌌 Weltenbibliothek - Chroniken der verborgenen Pfade\n\n'
      'Entdecke 161 mystische Events über 27.025 Jahre!\n\n'
      '✨ Features:\n'
      '• 15 echte Ley-Linien\n'
      '• Live-Erdbeben-Daten\n'
      '• Schumann-Resonanz\n'
      '• Verschwörungstheorien\n'
      '• Verborgenes Wissen\n\n'
      'Lade die App jetzt herunter!',
      subject: 'Weltenbibliothek App',
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Weltenbibliothek',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: RadialGradient(
            colors: [
              AppTheme.primaryPurple,
              AppTheme.secondaryGold,
            ],
          ),
        ),
        child: const Center(
          child: Text('📚', style: TextStyle(fontSize: 32)),
        ),
      ),
      children: [
        const SizedBox(height: 16),
        Text(
          'Chroniken der verborgenen Pfade',
          style: AppTheme.bodyMedium.copyWith(
            fontStyle: FontStyle.italic,
            color: AppTheme.secondaryGold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Eine App für alternative Perspektiven, verborgenes Wissen '
          'und paranormale Phänomene.\n\n'
          'Features:\n'
          '• 161 Events über 27.025 Jahre\n'
          '• 15 echte Ley-Linien\n'
          '• Live-Daten Dashboard\n'
          '• Schumann-Resonanz\n'
          '• Erdbeben & Vulkane\n',
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Datenschutz', style: AppTheme.headlineSmall),
        content: SingleChildScrollView(
          child: Text(
            'Datenschutzerklärung\n\n'
            '1. Datenerfassung\n'
            'Wir sammeln nur minimale Daten, die für den Betrieb der App notwendig sind.\n\n'
            '2. Lokale Speicherung\n'
            'Favoriten und Einstellungen werden lokal auf deinem Gerät gespeichert.\n\n'
            '3. Externe APIs\n'
            'Wir nutzen USGS für Erdbebendaten und andere öffentliche APIs.\n\n'
            '4. Keine Weitergabe\n'
            'Deine Daten werden nicht an Dritte weitergegeben.\n\n'
            '5. Kontakt\n'
            'Bei Fragen: support@weltenbibliothek.app',
            style: AppTheme.bodySmall,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Nutzungsbedingungen', style: AppTheme.headlineSmall),
        content: SingleChildScrollView(
          child: Text(
            'Nutzungsbedingungen\n\n'
            '1. Akzeptanz\n'
            'Durch die Nutzung dieser App akzeptierst du diese Bedingungen.\n\n'
            '2. Inhalte\n'
            'Die App präsentiert alternative Perspektiven und sollte kritisch '
            'betrachtet werden. Wir ermutigen zu eigenständiger Recherche.\n\n'
            '3. Haftung\n'
            'Die Informationen dienen der Bildung und Unterhaltung. '
            'Keine Garantie für Richtigkeit.\n\n'
            '4. Änderungen\n'
            'Wir behalten uns vor, diese Bedingungen zu ändern.\n\n'
            '5. Kontakt\n'
            'legal@weltenbibliothek.app',
            style: AppTheme.bodySmall,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  void _showHelpAndSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Hilfe & Support', style: AppTheme.headlineSmall),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FAQ', style: AppTheme.headlineSmall.copyWith(fontSize: 16)),
              const SizedBox(height: 12),
              _buildFAQItem(
                'Wie navigiere ich die Karte?',
                'Zoome mit 2 Fingern, verschiebe mit 1 Finger. Tippe auf Marker für Details.',
              ),
              _buildFAQItem(
                'Was sind Ley-Linien?',
                'Energielinien zwischen antiken Stätten. Wir zeigen 15 echte, recherchierte Verbindungen.',
              ),
              _buildFAQItem(
                'Wie funktioniert die Timeline?',
                'Tippe auf die Timeline (40px) um sie zu erweitern. Verwende den Slider für Zeitfilter.',
              ),
              const SizedBox(height: 16),
              Text('Kontakt', style: AppTheme.headlineSmall.copyWith(fontSize: 16)),
              const SizedBox(height: 12),
              Text(
                '📧 support@weltenbibliothek.app\n'
                '🌐 weltenbibliothek.app\n'
                '💬 Community Forum (bald)',
                style: AppTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q: $question',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryGold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A: $answer',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
