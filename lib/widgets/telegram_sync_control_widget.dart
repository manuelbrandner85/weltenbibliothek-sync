import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/telegram_background_service.dart';
import '../config/app_theme.dart';

/// Telegram Sync Control Widget (Phase 2.2)
/// 
/// Ermöglicht dem User die Kontrolle über Background-Synchronisation:
/// - Start/Stop Background-Sync
/// - Status-Anzeige (Aktiv/Inaktiv)
/// - Battery Optimization Warnung
/// - Einstellungen für Sync-Intervall
class TelegramSyncControlWidget extends StatefulWidget {
  const TelegramSyncControlWidget({super.key});

  @override
  State<TelegramSyncControlWidget> createState() => _TelegramSyncControlWidgetState();
}

class _TelegramSyncControlWidgetState extends State<TelegramSyncControlWidget> {
  bool _isSyncActive = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  /// Lädt aktuellen Sync-Status
  Future<void> _loadSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSyncActive = prefs.getBool('telegram_background_sync_active') ?? false;
    });
  }

  /// Speichert Sync-Status
  Future<void> _saveSyncStatus(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('telegram_background_sync_active', active);
  }

  /// Startet Background-Sync
  Future<void> _startSync() async {
    setState(() => _isLoading = true);
    
    try {
      await TelegramBackgroundService.startBackgroundSync();
      await _saveSyncStatus(true);
      
      setState(() {
        _isSyncActive = true;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Background-Sync aktiviert'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Starten: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Stoppt Background-Sync
  Future<void> _stopSync() async {
    setState(() => _isLoading = true);
    
    try {
      await TelegramBackgroundService.stopBackgroundSync();
      await _saveSyncStatus(false);
      
      setState(() {
        _isSyncActive = false;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛑 Background-Sync deaktiviert'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Stoppen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Zeigt Battery Optimization Dialog
  void _showBatteryOptimizationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Row(
          children: [
            Icon(Icons.battery_alert, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Akku-Optimierung',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Für zuverlässige Background-Synchronisation:',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoStep(
                '1.',
                'Öffne Android-Einstellungen',
              ),
              _buildInfoStep(
                '2.',
                'Apps → Weltenbibliothek',
              ),
              _buildInfoStep(
                '3.',
                'Akku → Akku-Optimierung deaktivieren',
              ),
              _buildInfoStep(
                '4.',
                'Autostart aktivieren (falls verfügbar)',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dies verhindert, dass Android die App stoppt',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  Widget _buildInfoStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              color: AppTheme.secondaryGold,
              fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSyncActive 
              ? Colors.green.withOpacity(0.5) 
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (_isSyncActive ? Colors.green : Colors.grey).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isSyncActive ? Icons.cloud_sync : Icons.cloud_off,
                  color: _isSyncActive ? Colors.green : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                      _isSyncActive 
                          ? 'Aktiv (alle 15 Min.)' 
                          : 'Inaktiv',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Toggle Switch
              Switch(
                value: _isSyncActive,
                onChanged: _isLoading ? null : (value) {
                  if (value) {
                    _startSync();
                  } else {
                    _stopSync();
                  }
                },
                activeColor: Colors.green,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Info-Text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.accentBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isSyncActive
                        ? 'Telegram-Inhalte werden automatisch synchronisiert, auch wenn die App geschlossen ist.'
                        : 'Aktiviere Background-Sync, um neue Telegram-Inhalte automatisch zu empfangen.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Battery Optimization Hinweis
          if (_isSyncActive)
            InkWell(
              onTap: _showBatteryOptimizationInfo,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.battery_alert, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Akku-Optimierung deaktivieren für beste Ergebnisse',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.orange, size: 20),
                  ],
                ),
              ),
            ),
          
          // Loading Indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
