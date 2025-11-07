import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/telegram_background_service.dart';
import '../config/app_theme.dart';

/// Telegram Service Control Widget (Phase 2.2)
/// 
/// Ermöglicht dem User das Starten/Stoppen des Background-Polling:
/// - Toggle-Button für Background-Sync
/// - Status-Anzeige (läuft/gestoppt)
/// - Info-Dialog mit Battery Optimization Hinweisen
class TelegramServiceControl extends StatefulWidget {
  const TelegramServiceControl({super.key});

  @override
  State<TelegramServiceControl> createState() => _TelegramServiceControlState();
}

class _TelegramServiceControlState extends State<TelegramServiceControl> {
  bool _isBackgroundSyncEnabled = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }
  
  /// Lädt den Sync-Status aus SharedPreferences
  Future<void> _loadSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBackgroundSyncEnabled = prefs.getBool('background_sync_enabled') ?? false;
    });
  }
  
  /// Speichert den Sync-Status in SharedPreferences
  Future<void> _saveSyncStatus(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('background_sync_enabled', enabled);
  }
  
  /// Toggled Background-Sync an/aus
  Future<void> _toggleBackgroundSync(bool enabled) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (enabled) {
        // Starte Background-Sync
        await TelegramBackgroundService.startBackgroundSync();
        
        // Zeige Success-Message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Background-Sync gestartet'),
                ],
              ),
              backgroundColor: AppTheme.surfaceDark,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Stoppe Background-Sync
        await TelegramBackgroundService.stopBackgroundSync();
        
        // Zeige Info-Message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('Background-Sync gestoppt'),
                ],
              ),
              backgroundColor: AppTheme.surfaceDark,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      
      // Speichere Status
      await _saveSyncStatus(enabled);
      
      setState(() {
        _isBackgroundSyncEnabled = enabled;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Zeige Error-Message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text('Fehler: $e')),
              ],
            ),
            backgroundColor: AppTheme.surfaceDark,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isBackgroundSyncEnabled 
              ? Colors.green.withOpacity(0.5) 
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isBackgroundSyncEnabled 
                  ? Colors.green.withOpacity(0.2) 
                  : Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isBackgroundSyncEnabled 
                  ? Icons.cloud_sync 
                  : Icons.cloud_off,
              color: _isBackgroundSyncEnabled 
                  ? Colors.green 
                  : Colors.grey,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Background-Synchronisation',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isBackgroundSyncEnabled
                      ? 'Läuft im Hintergrund (alle 15 Min.)'
                      : 'Gestoppt',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Toggle Switch
          if (_isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accentBlue,
              ),
            )
          else
            Switch(
              value: _isBackgroundSyncEnabled,
              onChanged: _toggleBackgroundSync,
              activeColor: Colors.green,
            ),
          
          // Info Button
          IconButton(
            icon: Icon(Icons.info_outline, color: AppTheme.accentBlue),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
    );
  }
  
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Row(
          children: [
            Icon(Icons.info, color: AppTheme.accentBlue),
            const SizedBox(width: 8),
            Text(
              'Background-Sync',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSection(
                icon: Icons.schedule,
                title: 'Polling-Intervall',
                description: 'Telegram wird alle 15 Minuten im Hintergrund synchronisiert.',
              ),
              const SizedBox(height: 16),
              _buildInfoSection(
                icon: Icons.battery_charging_full,
                title: 'Akku-Optimierung',
                description: 'Für zuverlässiges Background-Polling solltest du die Akku-Optimierung für diese App deaktivieren.',
              ),
              const SizedBox(height: 16),
              _buildInfoSection(
                icon: Icons.notification_important,
                title: 'Foreground Service',
                description: 'Die App zeigt eine persistente Benachrichtigung während der Synchronisation.',
              ),
              const SizedBox(height: 16),
              _buildInfoSection(
                icon: Icons.data_usage,
                title: 'Datenverbrauch',
                description: 'Background-Sync benötigt eine aktive Internetverbindung. Datenverbrauch ist minimal.',
              ),
              const SizedBox(height: 24),
              // Battery Optimization Button
              ElevatedButton.icon(
                onPressed: _openBatteryOptimizationSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Akku-Einstellungen öffnen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen', style: TextStyle(color: AppTheme.accentBlue)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.accentBlue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Öffnet Akku-Optimierungs-Einstellungen (Android)
  void _openBatteryOptimizationSettings() {
    // TODO: Android Intent für Battery Optimization Settings
    // Für jetzt zeigen wir nur eine Anleitung
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(
          'Akku-Optimierung deaktivieren',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'So deaktivierst du die Akku-Optimierung:',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStep('1', 'Öffne die Android-Einstellungen'),
            _buildStep('2', 'Gehe zu "Apps" oder "Anwendungen"'),
            _buildStep('3', 'Wähle "Weltenbibliothek"'),
            _buildStep('4', 'Tippe auf "Akku" oder "Akkuverbrauch"'),
            _buildStep('5', 'Wähle "Nicht optimiert" oder "Unbeschränkt"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Verstanden', style: TextStyle(color: AppTheme.accentBlue)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.accentBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
