import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/earthquake_service.dart';
import '../services/schumann_resonance_service.dart';
import '../services/nasa_data_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/interactive_data_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'schumann_resonance_screen.dart';
import 'stats_screen.dart';
import 'search_screen.dart';
import 'telegram_chat_screen.dart';
import 'unified_telegram_screen.dart';

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
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      blur: 20,
      opacity: 0.08,
      border: Border.all(
        color: AppTheme.primaryPurple.withValues(alpha: 0.4),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
          blurRadius: 30,
          spreadRadius: 5,
        ),
        BoxShadow(
          color: AppTheme.secondaryGold.withValues(alpha: 0.2),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryPurple.withValues(alpha: 0.15),
              AppTheme.secondaryGold.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(4),
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
    return InteractiveDataCard(
      emoji: emoji,
      title: title,
      value: value,
      accentColor: accentColor,
      showPulse: true,
      actionIcon: Icons.arrow_forward,
      onTap: () {
        // Navigation zu Detail-Screen basierend auf Typ
        if (title.contains('Schumann')) {
          // Navigation zu Schumann-Resonanz Live
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SchumannResonanceScreen()),
          );
        } else if (title.contains('Erdbeben')) {
          // Navigation zu Statistiken (enthält Erdbeben-Daten)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatsScreen()),
          );
        } else if (title.contains('ISS')) {
          // Navigation zu Statistiken (NASA-Daten)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatsScreen()),
          );
        } else if (title.contains('K-Index')) {
          // Navigation zu Schumann (enthält Solar Activity)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SchumannResonanceScreen()),
          );
        }
      },
    );
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
            DefaultTabController.of(context).animateTo(1); // Timeline ist Tab 1
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
            DefaultTabController.of(context).animateTo(2); // Karte ist Tab 2
          },
        ),
        
        const SizedBox(height: 12),
        
        _buildQuickAccessButton(
          icon: Icons.search,
          title: 'Erweiterte Suche',
          description: 'Durchsuche alle Events',
          gradient: LinearGradient(
            colors: [AppTheme.primaryTeal, AppTheme.dimensionalAnomalies],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
        ),
        
        const SizedBox(height: 12),
        
        _buildQuickAccessButton(
          icon: Icons.bar_chart,
          title: 'Statistiken',
          description: 'Datenbank-Übersicht',
          gradient: LinearGradient(
            colors: [AppTheme.secondaryGold, AppTheme.primaryPurple],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            );
          },
        ),
        
        const SizedBox(height: 12),
        
        _buildQuickAccessButton(
          icon: Icons.graphic_eq,
          title: 'Schumann Resonanz',
          description: 'Live-Daten aus Tomsk',
          gradient: LinearGradient(
            colors: [AppTheme.energyPhenomena, AppTheme.primaryTeal],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SchumannResonanceScreen()),
            );
          },
        ),
        
        const SizedBox(height: 12),
        
        _buildQuickAccessButton(
          icon: Icons.telegram,
          title: '📱 Telegram Channels',
          description: '6 Live-Channels · Echtzeit-Sync',
          gradient: LinearGradient(
            colors: [AppTheme.alienContact, AppTheme.primaryPurple],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UnifiedTelegramScreen()),
            );
          },
        ),
        
        const SizedBox(height: 12),
        
        _buildQuickAccessButton(
          icon: Icons.chat_bubble,
          title: '💬 Telegram Chat',
          description: 'Bidirektionale Synchronisation',
          gradient: LinearGradient(
            colors: [AppTheme.techMysteries, AppTheme.ufoFleets],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TelegramChatScreen()),
            );
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
