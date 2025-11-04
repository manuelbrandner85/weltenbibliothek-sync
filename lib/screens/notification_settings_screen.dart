import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/live_data_monitor_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final LiveDataMonitorService _monitorService = LiveDataMonitorService();
  
  AppNotificationSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await _notificationService.getSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    setState(() => _isSaving = true);

    try {
      await _notificationService.updateSettings(_settings!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Einstellungen gespeichert'),
            backgroundColor: AppTheme.secondaryGold,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benachrichtigungen'),
        backgroundColor: AppTheme.backgroundDark,
        actions: [
          if (!_isLoading && _settings != null)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveSettings,
              tooltip: 'Speichern',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.secondaryGold))
          : _settings == null
              ? const Center(child: Text('Fehler beim Laden'))
              : Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.cosmicGradient,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMonitoringStatus(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('📱 App-Benachrichtigungen'),
                        _buildSwitch(
                          title: '💬 Kommentare',
                          subtitle: 'Neue Kommentare auf favorisierte Events',
                          value: _settings!.enableComments,
                          onChanged: (val) => setState(() {
                            _settings = AppNotificationSettings(
                              enableComments: val,
                              enableRatings: _settings!.enableRatings,
                              enableNewEvents: _settings!.enableNewEvents,
                              enableEarthquakes: _settings!.enableEarthquakes,
                              enableVolcanos: _settings!.enableVolcanos,
                              enableUfoSightings: _settings!.enableUfoSightings,
                              enableSolarStorms: _settings!.enableSolarStorms,
                              enableSchumannSpikes: _settings!.enableSchumannSpikes,
                              earthquakeMagnitude: _settings!.earthquakeMagnitude,
                              volcanoActivityLevel: _settings!.volcanoActivityLevel,
                              ufoSightingThreshold: _settings!.ufoSightingThreshold,
                              solarStormKpIndex: _settings!.solarStormKpIndex,
                              schumannThreshold: _settings!.schumannThreshold,
                            );
                          }),
                        ),
                        _buildSwitch(
                          title: '⭐ Bewertungen',
                          subtitle: 'Neue Bewertungen auf favorisierte Events',
                          value: _settings!.enableRatings,
                          onChanged: (val) => setState(() {
                            _settings = AppNotificationSettings(
                              enableComments: _settings!.enableComments,
                              enableRatings: val,
                              enableNewEvents: _settings!.enableNewEvents,
                              enableEarthquakes: _settings!.enableEarthquakes,
                              enableVolcanos: _settings!.enableVolcanos,
                              enableUfoSightings: _settings!.enableUfoSightings,
                              enableSolarStorms: _settings!.enableSolarStorms,
                              enableSchumannSpikes: _settings!.enableSchumannSpikes,
                              earthquakeMagnitude: _settings!.earthquakeMagnitude,
                              volcanoActivityLevel: _settings!.volcanoActivityLevel,
                              ufoSightingThreshold: _settings!.ufoSightingThreshold,
                              solarStormKpIndex: _settings!.solarStormKpIndex,
                              schumannThreshold: _settings!.schumannThreshold,
                            );
                          }),
                        ),
                        
                        const SizedBox(height: 24),
                        _buildSectionTitle('🌍 Live-Daten Alarme'),
                        
                        _buildSwitchWithSlider(
                          title: '🌊 Erdbeben',
                          subtitle: 'Magnitude ≥ ${_settings!.earthquakeMagnitude.toStringAsFixed(1)}',
                          value: _settings!.enableEarthquakes,
                          sliderValue: _settings!.earthquakeMagnitude,
                          sliderMin: 3.0,
                          sliderMax: 8.0,
                          sliderDivisions: 50,
                          onSwitchChanged: (val) => setState(() {
                            _settings = AppNotificationSettings(
                              enableComments: _settings!.enableComments,
                              enableRatings: _settings!.enableRatings,
                              enableNewEvents: _settings!.enableNewEvents,
                              enableEarthquakes: val,
                              enableVolcanos: _settings!.enableVolcanos,
                              enableUfoSightings: _settings!.enableUfoSightings,
                              enableSolarStorms: _settings!.enableSolarStorms,
                              enableSchumannSpikes: _settings!.enableSchumannSpikes,
                              earthquakeMagnitude: _settings!.earthquakeMagnitude,
                              volcanoActivityLevel: _settings!.volcanoActivityLevel,
                              ufoSightingThreshold: _settings!.ufoSightingThreshold,
                              solarStormKpIndex: _settings!.solarStormKpIndex,
                              schumannThreshold: _settings!.schumannThreshold,
                            );
                          }),
                          onSliderChanged: (val) => setState(() {
                            _settings = AppNotificationSettings(
                              enableComments: _settings!.enableComments,
                              enableRatings: _settings!.enableRatings,
                              enableNewEvents: _settings!.enableNewEvents,
                              enableEarthquakes: _settings!.enableEarthquakes,
                              enableVolcanos: _settings!.enableVolcanos,
                              enableUfoSightings: _settings!.enableUfoSightings,
                              enableSolarStorms: _settings!.enableSolarStorms,
                              enableSchumannSpikes: _settings!.enableSchumannSpikes,
                              earthquakeMagnitude: val,
                              volcanoActivityLevel: _settings!.volcanoActivityLevel,
                              ufoSightingThreshold: _settings!.ufoSightingThreshold,
                              solarStormKpIndex: _settings!.solarStormKpIndex,
                              schumannThreshold: _settings!.schumannThreshold,
                            );
                          }),
                        ),
                        
                        _buildSwitchWithSlider(
                          title: '⚡ Schumann-Resonanz',
                          subtitle: 'Frequenz ≥ ${_settings!.schumannThreshold.toStringAsFixed(1)} Hz',
                          value: _settings!.enableSchumannSpikes,
                          sliderValue: _settings!.schumannThreshold,
                          sliderMin: 10.0,
                          sliderMax: 30.0,
                          sliderDivisions: 40,
                          onSwitchChanged: (val) => setState(() {
                            _settings = AppNotificationSettings(
                              enableComments: _settings!.enableComments,
                              enableRatings: _settings!.enableRatings,
                              enableNewEvents: _settings!.enableNewEvents,
                              enableEarthquakes: _settings!.enableEarthquakes,
                              enableVolcanos: _settings!.enableVolcanos,
                              enableUfoSightings: _settings!.enableUfoSightings,
                              enableSolarStorms: _settings!.enableSolarStorms,
                              enableSchumannSpikes: val,
                              earthquakeMagnitude: _settings!.earthquakeMagnitude,
                              volcanoActivityLevel: _settings!.volcanoActivityLevel,
                              ufoSightingThreshold: _settings!.ufoSightingThreshold,
                              solarStormKpIndex: _settings!.solarStormKpIndex,
                              schumannThreshold: _settings!.schumannThreshold,
                            );
                          }),
                          onSliderChanged: (val) => setState(() {
                            _settings = AppNotificationSettings(
                              enableComments: _settings!.enableComments,
                              enableRatings: _settings!.enableRatings,
                              enableNewEvents: _settings!.enableNewEvents,
                              enableEarthquakes: _settings!.enableEarthquakes,
                              enableVolcanos: _settings!.enableVolcanos,
                              enableUfoSightings: _settings!.enableUfoSightings,
                              enableSolarStorms: _settings!.enableSolarStorms,
                              enableSchumannSpikes: _settings!.enableSchumannSpikes,
                              earthquakeMagnitude: _settings!.earthquakeMagnitude,
                              volcanoActivityLevel: _settings!.volcanoActivityLevel,
                              ufoSightingThreshold: _settings!.ufoSightingThreshold,
                              solarStormKpIndex: _settings!.solarStormKpIndex,
                              schumannThreshold: val,
                            );
                          }),
                        ),
                        
                        const SizedBox(height: 24),
                        _buildInfoBox(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMonitoringStatus() {
    final isMonitoring = _monitorService.isMonitoring;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMonitoring 
            ? AppTheme.secondaryGold.withValues(alpha: 0.1)
            : AppTheme.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMonitoring ? AppTheme.secondaryGold : AppTheme.errorRed,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isMonitoring ? Icons.sensors : Icons.sensors_off,
            color: isMonitoring ? AppTheme.secondaryGold : AppTheme.errorRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMonitoring ? 'Monitoring Aktiv' : 'Monitoring Inaktiv',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isMonitoring 
                      ? 'Live-Daten werden überwacht (alle 5 Minuten)'
                      : 'Aktiviere Monitoring in den Einstellungen',
                  style: TextStyle(
                    color: AppTheme.textWhite.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (isMonitoring) {
                _monitorService.stopMonitoring();
              } else {
                _monitorService.startMonitoring();
              }
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isMonitoring ? AppTheme.errorRed : AppTheme.secondaryGold,
            ),
            child: Text(isMonitoring ? 'Stop' : 'Start'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.secondaryGold,
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textWhite.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.secondaryGold,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchWithSlider({
    required String title,
    required String subtitle,
    required bool value,
    required double sliderValue,
    required double sliderMin,
    required double sliderMax,
    required int sliderDivisions,
    required ValueChanged<bool> onSwitchChanged,
    required ValueChanged<double> onSliderChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textWhite.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onSwitchChanged,
                activeColor: AppTheme.secondaryGold,
              ),
            ],
          ),
          if (value) ...[
            const SizedBox(height: 12),
            Slider(
              value: sliderValue,
              min: sliderMin,
              max: sliderMax,
              divisions: sliderDivisions,
              activeColor: AppTheme.secondaryGold,
              inactiveColor: AppTheme.primaryPurple.withValues(alpha: 0.3),
              onChanged: onSliderChanged,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.secondaryGold),
              const SizedBox(width: 8),
              Text(
                'Über Live-Daten Alarme',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '🌊 Erdbeben: Daten von USGS (alle 5 Minuten)\n'
            '⚡ Schumann-Resonanz: Elektromagnetische Erdfrequenz\n'
            '☀️ Sonnensturm: Geomagnetische Aktivität (KP-Index)\n\n'
            'Alarme werden maximal einmal pro Stunde gesendet, um Spam zu vermeiden.',
            style: TextStyle(
              color: AppTheme.textWhite.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
