import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/earthquake_service.dart';
import '../services/schumann_resonance_service.dart';
import '../services/nasa_data_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EarthquakeService _earthquakeService = EarthquakeService();
  final SchumannResonanceService _schumannService = SchumannResonanceService();
  final NASADataService _nasaService = NASADataService();

  List<Earthquake> _recentEarthquakes = [];
  SchumannData? _schumannData;
  ISSData? _issData;
  SolarData? _solarData;

  @override
  void initState() {
    super.initState();
    // Asynchrone Initialisierung nach dem ersten Frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    try {
      // Starte Services im Hintergrund
      _earthquakeService.startMonitoring();
      _schumannService.startMonitoring();
      _nasaService.startISSMonitoring();
      _nasaService.startSolarMonitoring();

      // Lausche auf Updates
      _earthquakeService.earthquakesStream.listen((earthquakes) {
        if (mounted) {
          setState(() {
            _recentEarthquakes = earthquakes.take(5).toList();
          });
        }
      });

      _schumannService.dataStream.listen((data) {
        if (mounted) {
          setState(() {
            _schumannData = data;
          });
        }
      });

      _nasaService.issStream.listen((data) {
        if (mounted) {
          setState(() {
            _issData = data;
          });
        }
      });

      _nasaService.solarStream.listen((data) {
        if (mounted) {
          setState(() {
            _solarData = data;
          });
        }
      });
    } catch (e) {
      debugPrint('❌ Fehler bei Service-Initialisierung: $e');
    }
  }

  @override
  void dispose() {
    _earthquakeService.dispose();
    _schumannService.dispose();
    _nasaService.dispose();
    super.dispose();
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
              // Header mit mystischem Titel
              Center(
                child: Text(
                  'Weltenbibliothek',
                  style: theme.textTheme.displayLarge,
                ).animate()
                  .fadeIn(duration: 600.ms)
                  .shimmer(duration: 2000.ms, color: AppTheme.secondaryGold),
              ),
              
              Center(
                child: Text(
                  'Chroniken der verborgenen Pfade',
                  style: theme.textTheme.bodyMedium,
                ).animate().fadeIn(delay: 300.ms),
              ),
              
              const SizedBox(height: 24),

              // Kosmisches Dashboard
              _buildCosmicDashboard(),
              
              const SizedBox(height: 24),

              // Live-Daten Grid
              _buildLiveDataGrid(),
              
              const SizedBox(height: 24),

              // Schnellzugriff-Buttons
              _buildQuickAccessButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCosmicDashboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cosmicGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.public,
                size: 48,
                color: AppTheme.secondaryGold,
              ),
              const SizedBox(width: 12),
              Text(
                '🌍 Globaler Status',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryGold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),

          // Status-Indikatoren
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusIndicator(
                '⚡',
                'Schumann',
                _schumannData?.frequencyStatus ?? 'Laden...',
                AppTheme.energyPhenomena,
              ),
              _buildStatusIndicator(
                '🌋',
                'Erdbeben',
                '${_recentEarthquakes.length}',
                AppTheme.errorRed,
              ),
              _buildStatusIndicator(
                '☀️',
                'Solar',
                _solarData?.activityLevel ?? 'Laden...',
                AppTheme.secondaryGold,
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 400.ms)
      .scale(delay: 400.ms);
  }

  Widget _buildStatusIndicator(String emoji, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textWhite.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveDataGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildLiveDataCard(
          '🌊',
          'Schumann-Resonanz',
          _schumannData != null 
            ? '${_schumannData!.frequency.toStringAsFixed(2)} Hz'
            : 'Lade...',
          AppTheme.energyPhenomena,
        ),
        _buildLiveDataCard(
          '🌍',
          'Erdbeben (24h)',
          '${_recentEarthquakes.length}',
          AppTheme.errorRed,
        ),
        _buildLiveDataCard(
          '🛰️',
          'ISS Position',
          _issData != null 
            ? '${_issData!.latitude.toStringAsFixed(1)}°'
            : 'Lade...',
          AppTheme.alienContact,
        ),
        _buildLiveDataCard(
          '☀️',
          'K-Index',
          _solarData != null 
            ? '${_solarData!.kIndex}'
            : 'Lade...',
          AppTheme.secondaryGold,
        ),
      ],
    );
  }

  Widget _buildLiveDataCard(String emoji, String title, String value, Color accentColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.surfaceDark,
              accentColor.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textWhite.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: 600.ms)
      .slideY(begin: 0.2, end: 0, delay: 600.ms);
  }

  Widget _buildQuickAccessButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schnellzugriff',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        
        _buildQuickAccessButton(
          icon: Icons.timeline,
          title: 'Historische Timeline',
          description: 'Entdecke verborgene Ereignisse',
          gradient: LinearGradient(
            colors: [AppTheme.lostCivilizations, AppTheme.forbiddenKnowledge],
          ),
          onTap: () {
            // Navigation zur Timeline
          },
        ),
        
        const SizedBox(height: 12),
        
        _buildQuickAccessButton(
          icon: Icons.map,
          title: 'Interaktive Karte',
          description: 'Ley-Linien & Kraftorte',
          gradient: LinearGradient(
            colors: [AppTheme.dimensionalAnomalies, AppTheme.primaryPurple],
          ),
          onTap: () {
            // Navigation zur Karte
          },
        ),
        
        const SizedBox(height: 12),
        
        _buildQuickAccessButton(
          icon: Icons.auto_awesome,
          title: 'AI-Assistent',
          description: 'Gemini 2.0 Analyse',
          gradient: LinearGradient(
            colors: [AppTheme.techMysteries, AppTheme.alienContact],
          ),
          onTap: () {
            // Navigation zum AI-Chat
          },
        ),
      ],
    );
  }

  Widget _buildQuickAccessButton({
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.textWhite.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.textWhite, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textWhite.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textWhite.withValues(alpha: 0.7),
              size: 18,
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: 800.ms)
      .slideX(begin: -0.1, end: 0, delay: 800.ms);
  }
}
