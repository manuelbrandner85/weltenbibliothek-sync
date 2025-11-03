import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

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
              
              // Einstellungen-Sektion
              _buildSection(
                context,
                title: 'Einstellungen',
                items: [
                  _buildMenuItem(
                    icon: Icons.notifications,
                    title: 'Push-Benachrichtigungen',
                    subtitle: 'Erdbeben & Anomalien',
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {},
                      activeTrackColor: AppTheme.secondaryGold,
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.language,
                    title: 'Sprache',
                    subtitle: 'Deutsch',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.dark_mode,
                    title: 'Theme',
                    subtitle: 'Dark Mode (Mystisch)',
                    onTap: () {},
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
                    subtitle: 'Für Offline-Zugriff herunterladen',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.import_export,
                    title: 'Daten Exportieren',
                    subtitle: 'Favoriten & Sichtungen',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.delete_sweep,
                    title: 'Cache Löschen',
                    subtitle: '152 MB',
                    onTap: () {},
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
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.report,
                    title: 'Sichtung Melden',
                    subtitle: 'Teile deine Erfahrungen',
                    onTap: () {},
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
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.gavel,
                    title: 'Nutzungsbedingungen',
                    subtitle: 'Rechtliche Hinweise',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.help,
                    title: 'Hilfe & Support',
                    subtitle: 'FAQ & Kontakt',
                    onTap: () {},
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
                    ).animate()
                      .rotate(duration: 4000.ms)
                      .then()
                      .rotate(duration: 4000.ms, begin: 1, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'Weltenbibliothek',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryGold,
                      ),
                    ),
                    Text(
                      'Chroniken der verborgenen Pfade',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textWhite.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '© 2024 - Alle Rechte vorbehalten',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textWhite.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.purpleGoldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.textWhite.withValues(alpha: 0.2),
              border: Border.all(
                color: AppTheme.textWhite,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 32,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wahrheitssucher',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mitglied seit 2024',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textWhite.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatBadge('⭐', '5'),
                    const SizedBox(width: 12),
                    _buildStatBadge('🔍', '12'),
                    const SizedBox(width: 12),
                    _buildStatBadge('👁️', '87'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 200.ms)
      .scale(delay: 200.ms);
  }

  Widget _buildStatBadge(String emoji, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.textWhite.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            count,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryGold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items,
          ),
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
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.secondaryGold,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.textWhite,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textWhite.withValues(alpha: 0.7),
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textWhite.withValues(alpha: 0.5),
      ),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Text(
              '🌌',
              style: TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            const Text(
              'Über die App',
              style: TextStyle(
                color: AppTheme.secondaryGold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weltenbibliothek',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chroniken der verborgenen Pfade',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textWhite.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Version: 1.0.0',
              style: TextStyle(color: AppTheme.textWhite),
            ),
            const SizedBox(height: 8),
            Text(
              'Eine progressive Web App für alternative Geschichte, verborgenes Wissen und paranormale Phänomene.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textWhite.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Features:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryGold,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('📊', 'Live-Daten (Erdbeben, Schumann, ISS)'),
            _buildFeatureItem('⏱️', 'Historische Timeline'),
            _buildFeatureItem('🗺️', 'Interaktive Ley-Linien Karte'),
            _buildFeatureItem('🤖', 'AI-Assistent (Gemini 2.0)'),
            _buildFeatureItem('👁️', 'Community Sichtungen'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Schließen',
              style: TextStyle(color: AppTheme.secondaryGold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textWhite.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
