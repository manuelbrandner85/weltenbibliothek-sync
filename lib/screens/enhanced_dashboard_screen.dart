import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/enhanced_schumann_service.dart';
// ❌ ENTFERNT: Simulations-Services
// import '../services/enhanced_population_service.dart';
// import '../services/correlation_service.dart';
// import '../widgets/population_heatmap_widget.dart';
// import '../widgets/correlation_dashboard_widget.dart';
import '../widgets/schumann_spectrogram_widget.dart';

/// Enhanced Live Dashboard mit Option C Features
/// 
/// Zeigt:
/// - Schumann-Resonanz Spektrogramm mit Harmonischen
/// - Bevölkerungs-Heatmap mit Live-Events
/// - Korrelations-Dashboard für Muster-Erkennung
class EnhancedDashboardScreen extends StatefulWidget {
  const EnhancedDashboardScreen({super.key});

  @override
  State<EnhancedDashboardScreen> createState() => _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen> 
    with SingleTickerProviderStateMixin {
  final EnhancedSchumannService _schumannService = EnhancedSchumannService();
  // ❌ ENTFERNT: Simulations-Services
  // final EnhancedPopulationService _populationService = EnhancedPopulationService();
  // final CorrelationService _correlationService = CorrelationService();
  
  late TabController _tabController;
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // ❌ Reduziert von 3 auf 1 (nur Schumann)
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler beim Laden: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Enhanced Analytics'),
        backgroundColor: AppTheme.surfaceDark,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.secondaryGold,
          labelColor: AppTheme.secondaryGold,
          unselectedLabelColor: AppTheme.textGrey,
          tabs: const [
            Tab(
              icon: Icon(Icons.graphic_eq),
              text: 'Schumann',
            ),
            // ❌ ENTFERNT: Population & Correlation Tabs
            // Tab(icon: Icon(Icons.public), text: 'Bevölkerung'),
            // Tab(icon: Icon(Icons.insights), text: 'Korrelationen'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSchumannTab(),
                    // ❌ ENTFERNT: Population & Correlation Tabs
                    // _buildPopulationTab(),
                    // _buildCorrelationTab(),
                  ],
                ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.secondaryGold),
          const SizedBox(height: 16),
          Text(
            'Lade Enhanced Analytics...',
            style: AppTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: AppTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  Widget _buildSchumannTab() {
    return StreamBuilder(
      stream: _schumannService.getSchumannStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.secondaryGold),
                const SizedBox(height: 16),
                Text(
                  'Lade Schumann-Resonanz Daten...',
                  style: AppTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Fehler: ${snapshot.error}',
                  style: AppTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: Text(
              'Keine Daten verfügbar',
              style: AppTheme.bodyLarge,
            ),
          );
        }

        final data = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Spektrogramm Widget
              SchumannSpectrogramWidget(data: data),
              
              const SizedBox(height: 16),
              
              // Historical Data Cards
              _buildHistoricalDataCard(
                '24 Stunden Verlauf',
                data.history24h.length,
                Icons.access_time,
                Colors.blue,
              ),
              
              const SizedBox(height: 8),
              
              _buildHistoricalDataCard(
                '7 Tage Verlauf',
                data.history7d.length,
                Icons.calendar_view_week,
                Colors.green,
              ),
              
              const SizedBox(height: 8),
              
              _buildHistoricalDataCard(
                '30 Tage Verlauf',
                data.history30d.length,
                Icons.calendar_month,
                Colors.orange,
              ),
              
              const SizedBox(height: 16),
              
              // Info Card
              _buildInfoCard(
                'Über Schumann-Resonanz',
                'Die Schumann-Resonanz ist eine globale elektromagnetische Resonanz, '
                'die durch Blitzaktivität in der Erdatmosphäre angeregt wird. '
                'Die Grundfrequenz liegt bei etwa 7.83 Hz.',
              ),
            ],
          ),
        );
      },
    );
  }

  // ❌ KOMPLETT ENTFERNT: Population & Correlation Tab Widgets (nicht mehr verwendet)

  Widget _buildHistoricalDataCard(String title, int dataPoints, IconData icon, Color color) {
    return Card(
      color: AppTheme.cardDark,
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Text(
          '$dataPoints Punkte',
          style: AppTheme.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ❌ ENTFERNT: Helper-Methoden für Population-Simulation
  // _buildLivePopulationCounter() - nicht mehr benötigt
  // _buildPopulationStat() - nicht mehr benötigt
  // _buildContinentalBreakdown() - nicht mehr benötigt

  Widget _buildInfoCard(String title, String description) {
    return Card(
      color: AppTheme.primaryPurple.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: AppTheme.secondaryGold),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // ❌ ENTFERNT: _formatPopulation() - nicht mehr benötigt
}
