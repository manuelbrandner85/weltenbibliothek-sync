import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/enhanced_schumann_service.dart';
import '../services/enhanced_population_service.dart';
import '../services/correlation_service.dart';
import '../widgets/schumann_spectrogram_widget.dart';
import '../widgets/population_heatmap_widget.dart';
import '../widgets/correlation_dashboard_widget.dart';

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
  final EnhancedPopulationService _populationService = EnhancedPopulationService();
  final CorrelationService _correlationService = CorrelationService();
  
  late TabController _tabController;
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(
              icon: Icon(Icons.public),
              text: 'Bevölkerung',
            ),
            Tab(
              icon: Icon(Icons.insights),
              text: 'Korrelationen',
            ),
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
                    _buildPopulationTab(),
                    _buildCorrelationTab(),
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

  Widget _buildPopulationTab() {
    return StreamBuilder(
      stream: _populationService.getPopulationStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.secondaryGold),
                const SizedBox(height: 16),
                Text(
                  'Lade Bevölkerungs-Daten...',
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
        final currentPopulation = data.getCurrentPopulation();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Live Population Counter
              _buildLivePopulationCounter(currentPopulation, data),
              
              const SizedBox(height: 16),
              
              // Heatmap Widget
              PopulationHeatmapWidget(data: data),
              
              const SizedBox(height: 16),
              
              // Continental Breakdown
              _buildContinentalBreakdown(data),
              
              const SizedBox(height: 16),
              
              // Info Card
              _buildInfoCard(
                'Über die Weltbevölkerung',
                'Die Weltbevölkerung wächst kontinuierlich. Jede Sekunde werden etwa '
                '${data.growthPerSecond.toStringAsFixed(2)} Menschen mehr geboren als sterben.',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCorrelationTab() {
    return FutureBuilder(
      future: _correlationService.getCorrelationAnalysis(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.secondaryGold),
                const SizedBox(height: 16),
                Text(
                  'Berechne Korrelationen...',
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

        final analysis = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CorrelationDashboardWidget(analysis: analysis),
              
              const SizedBox(height: 16),
              
              // Refresh Button
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    // Trigger rebuild to recalculate
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Korrelationen neu berechnen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info Card
              _buildInfoCard(
                'Über Korrelationen',
                'Diese Analyse untersucht statistische Zusammenhänge zwischen verschiedenen '
                'Phänomenen wie Schumann-Resonanz, Erdbeben, UFO-Sichtungen und solarer Aktivität. '
                'Ein Korrelationskoeffizient nahe 1 oder -1 deutet auf einen starken Zusammenhang hin.',
              ),
            ],
          ),
        );
      },
    );
  }

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

  Widget _buildLivePopulationCounter(int population, data) {
    return Card(
      color: AppTheme.cardDark,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Weltbevölkerung LIVE',
              style: AppTheme.headlineMedium.copyWith(
                color: AppTheme.secondaryGold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _formatPopulation(population),
              style: AppTheme.headlineLarge.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPopulationStat(
                  'Geburten heute',
                  '${data.birthsToday}',
                  Icons.child_care,
                  Colors.green,
                ),
                _buildPopulationStat(
                  'Todesfälle heute',
                  '${data.deathsToday}',
                  Icons.favorite,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopulationStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildContinentalBreakdown(data) {
    return Card(
      color: AppTheme.cardDark,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kontinentale Verteilung',
              style: AppTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ...data.byContinent.entries.map((entry) {
              final percentage = (entry.value / data.totalPopulation) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: AppTheme.bodyMedium,
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.secondaryGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

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

  String _formatPopulation(int population) {
    if (population >= 1000000000) {
      return '${(population / 1000000000).toStringAsFixed(3)} Mrd';
    } else {
      return population.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
    }
  }
}
