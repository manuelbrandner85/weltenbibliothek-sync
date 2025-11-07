import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_theme.dart';
import '../services/live_data_service.dart';
import '../services/enhanced_schumann_service.dart';
import '../services/kiruna_magnetometer_service.dart';
// ❌ ENTFERNT: Simulations-Services
// import '../services/enhanced_population_service.dart';
// import '../services/correlation_service.dart';
// import '../models/enhanced_population_data.dart';
// import '../widgets/population_heatmap_widget.dart';
// import '../widgets/correlation_dashboard_widget.dart';
import '../models/enhanced_schumann_data.dart';
import '../widgets/schumann_spectrogram_widget.dart';
import 'package:intl/intl.dart';

/// Live-Daten Dashboard mit Echtzeit-Visualisierungen
/// - Schumann-Resonanz (Live-Grafik, SEKÜNDLICH aktualisiert)
/// - Geburten/Sterberaten (Live-Counter, SEKÜNDLICH)
/// - Vulkane (Aktive Vulkane weltweit, SEKÜNDLICH)
/// - Erdbeben (Echtzeit USGS-Daten, SEKÜNDLICH)
/// 
/// ALLE 4 BEREICHE KLAR GETRENNT MIT EIGENEM DESIGN
class LiveDashboardScreen extends StatefulWidget {
  const LiveDashboardScreen({super.key});

  @override
  State<LiveDashboardScreen> createState() => _LiveDashboardScreenState();
}

class _LiveDashboardScreenState extends State<LiveDashboardScreen> {
  final LiveDataService _liveService = LiveDataService();
  final EnhancedSchumannService _enhancedSchumannService = EnhancedSchumannService();
  final KirunaMagnetometerService _kirunaService = KirunaMagnetometerService();
  // ❌ ENTFERNT: Simulations-Services
  // final EnhancedPopulationService _enhancedPopulationService = EnhancedPopulationService();
  // final CorrelationService _correlationService = CorrelationService();
  
  // Live-Daten (getrennt für jeden Bereich)
  SchumannResonance? _schumannData;
  List<EarthquakeData> _earthquakes = [];
  List<VolcanoData> _volcanoes = [];
  PopulationStats? _populationStats;
  
  // Enhanced Daten
  EnhancedSchumannData? _enhancedSchumann;
  KirunaMagnetometerData? _kirunaData;
  // ❌ ENTFERNT: Simulations-Daten
  // EnhancedPopulationData? _enhancedPopulation;
  // CorrelationAnalysis? _correlationAnalysis;
  
  // Schumann-Resonanz History (letzte 60 Sekunden)
  final List<SchumannDataPoint> _schumannHistory = [];
  
  // Separate Update-Timer
  Timer? _schumannTimer;
  Timer? _populationTimer;
  Timer? _volcanoTimer;
  Timer? _earthquakeTimer;
  Timer? _enhancedTimer;
  
  // Letzte Updates (pro Bereich)
  DateTime? _lastSchumannUpdate;
  DateTime? _lastPopulationUpdate;
  DateTime? _lastVolcanoUpdate;
  DateTime? _lastEarthquakeUpdate;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startLiveUpdates();
    
    // Starte Kiruna Auto-Update (alle 5 Minuten) mit Alarm-Check
    _kirunaService.startAutoUpdate();
    _kirunaService.dataStream.listen((data) {
      if (mounted) {
        setState(() => _kirunaData = data);
        
        // Prüfe auf ungewöhnliche Werte und zeige Alarme
        _checkMagnetometerAlerts(data);
      }
    });
  }

  @override
  void dispose() {
    _schumannTimer?.cancel();
    _populationTimer?.cancel();
    _volcanoTimer?.cancel();
    _earthquakeTimer?.cancel();
    _enhancedTimer?.cancel();
    _kirunaService.stopAutoUpdate();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    final schumann = await _liveService.getSchumannResonance();
    final earthquakes = await _liveService.getEarthquakes();
    final volcanoes = await _liveService.getActiveVolcanoes();
    final populationStats = _liveService.getPopulationStats();
    
    // Lade Enhanced Daten
    final enhancedSchumann = await _enhancedSchumannService.getEnhancedSchumannData();
    // ❌ ENTFERNT: Population & Correlation Simulations
    
    if (mounted) {
      setState(() {
        _schumannData = schumann;
        _earthquakes = earthquakes;
        _volcanoes = volcanoes;
        _populationStats = populationStats;
        _enhancedSchumann = enhancedSchumann;
        // ❌ ENTFERNT: _enhancedPopulation, _correlationAnalysis
        _lastSchumannUpdate = DateTime.now();
        _lastPopulationUpdate = DateTime.now();
        _lastVolcanoUpdate = DateTime.now();
        _lastEarthquakeUpdate = DateTime.now();
        _isLoading = false;
        
        // Initialisiere Schumann-History
        _schumannHistory.add(SchumannDataPoint(
          timestamp: DateTime.now(),
          frequency: schumann.frequency,
        ));
      });
    }
  }

  void _startLiveUpdates() {
    // 1. SCHUMANN-RESONANZ: Sekündlich aktualisieren
    _schumannTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final schumann = await _liveService.getSchumannResonance();
      
      if (mounted) {
        setState(() {
          _schumannData = schumann;
          _lastSchumannUpdate = DateTime.now();
          
          // Füge neuen Datenpunkt hinzu
          _schumannHistory.add(SchumannDataPoint(
            timestamp: DateTime.now(),
            frequency: schumann.frequency,
          ));
          
          // Behalte nur letzte 60 Sekunden
          if (_schumannHistory.length > 60) {
            _schumannHistory.removeAt(0);
          }
        });
      }
    });
    
    // 2. GEBURTEN/STERBERATEN: Sekündlich aktualisieren
    _populationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _populationStats = _liveService.getPopulationStats();
          _lastPopulationUpdate = DateTime.now();
        });
      }
    });
    
    // 3. VULKANE: Sekündlich aktualisieren (zeigt auch Zeitstempel-Updates)
    _volcanoTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      // Vulkan-Daten bleiben gleich, aber Timestamp wird aktualisiert
      if (mounted) {
        setState(() {
          _lastVolcanoUpdate = DateTime.now();
        });
      }
    });
    
    // 4. ERDBEBEN: Alle 5 Sekunden neue Daten vom USGS holen
    _earthquakeTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final earthquakes = await _liveService.getEarthquakes();
      
      if (mounted) {
        setState(() {
          _earthquakes = earthquakes;
          _lastEarthquakeUpdate = DateTime.now();
        });
      }
    });
    
    // 5. ENHANCED DATEN: Alle 30 Sekunden aktualisieren
    _enhancedTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final enhancedSchumann = await _enhancedSchumannService.getEnhancedSchumannData();
      // ❌ ENTFERNT: Population & Correlation Simulations
      
      if (mounted) {
        setState(() {
          _enhancedSchumann = enhancedSchumann;
          // ❌ ENTFERNT: _enhancedPopulation, _correlationAnalysis
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.secondaryGold),
              const SizedBox(height: 16),
              Text(
                'Lade Live-Daten...',
                style: AppTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header mit Gesamt-Info
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            
            // Trennlinie
            SliverToBoxAdapter(
              child: _buildDivider('Erdmagnetfeld'),
            ),
            
            // 1. SCHUMANN-RESONANZ (Eigene Sektion)
            SliverToBoxAdapter(
              child: _buildSchumannCard(),
            ),
            
            // Trennlinie
            SliverToBoxAdapter(
              child: _buildDivider('Weltbevölkerung'),
            ),
            
            // 2. GEBURTEN/STERBERATEN (Eigene Sektion)
            SliverToBoxAdapter(
              child: _buildPopulationCard(),
            ),
            
            // Trennlinie
            SliverToBoxAdapter(
              child: _buildDivider('Geologie'),
            ),
            
            // 3. VULKANE (Eigene Sektion)
            SliverToBoxAdapter(
              child: _buildVolcanoCard(),
            ),
            
            // Trennlinie
            SliverToBoxAdapter(
              child: _buildDivider('Seismik'),
            ),
            
            // 4. ERDBEBEN (Eigene Sektion)
            SliverToBoxAdapter(
              child: _buildEarthquakeCard(),
            ),
            
            // ========== ENHANCED FEATURES ==========
            
            // Trennlinie
            SliverToBoxAdapter(
              child: _buildDivider('Schumann Spektrogramm'),
            ),
            
            // 5. SCHUMANN SPEKTROGRAMM (Enhanced)
            SliverToBoxAdapter(
              child: _buildEnhancedSchumannCard(),
            ),
            
            // Trennlinie
            SliverToBoxAdapter(
              child: _buildDivider('Kiruna Magnetometer'),
            ),
            
            // 6. KIRUNA SUSPENDED MAGNETOMETER (Live Data)
            SliverToBoxAdapter(
              child: _buildKirunaCard(),
            ),
            
            // ❌ ENTFERNT: Bevölkerungs-Heatmap & Korrelations-Analyse Sektionen
            
            // Bottom Spacer
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withValues(alpha: 0.2),
            AppTheme.backgroundDark,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple,
                      AppTheme.secondaryGold,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryGold.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.show_chart,
                  color: AppTheme.textWhite,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live-Daten Dashboard',
                      style: AppTheme.headlineLarge.copyWith(fontSize: 24),
                    ),
                    Text(
                      'Echtzeit-Updates sekündlich',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.secondaryGold,
                      ),
                    ),
                  ],
                ),
              ),
              // Live-Indikator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.backgroundDark,
                    AppTheme.primaryPurple.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label.toUpperCase(),
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppTheme.secondaryGold,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryPurple.withValues(alpha: 0.5),
                    AppTheme.backgroundDark,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchumannCard() {
    if (_schumannData == null) return const SizedBox.shrink();
    
    final timeFormat = DateFormat('HH:mm:ss');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _schumannData!.isAnomalous
                ? Colors.red.withValues(alpha: 0.15)
                : AppTheme.primaryPurple.withValues(alpha: 0.15),
            AppTheme.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _schumannData!.isAnomalous
              ? Colors.red.withValues(alpha: 0.6)
              : AppTheme.secondaryGold.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_schumannData!.isAnomalous ? Colors.red : AppTheme.secondaryGold)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Live-Update-Zeit
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.waves,
                  color: AppTheme.secondaryGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schumann-Resonanz',
                      style: AppTheme.headlineMedium.copyWith(fontSize: 18),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppTheme.secondaryGold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Update: ${timeFormat.format(_lastSchumannUpdate!)}',
                          style: AppTheme.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _schumannData!.isAnomalous
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _schumannData!.isAnomalous ? 'ANOMAL' : 'NORMAL',
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Aktuelle Frequenz (groß und prominent)
          Center(
            child: Column(
              children: [
                Text(
                  '${_schumannData!.frequency.toStringAsFixed(2)} Hz',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: _schumannData!.isAnomalous
                        ? Colors.red
                        : AppTheme.secondaryGold,
                    shadows: [
                      Shadow(
                        color: (_schumannData!.isAnomalous ? Colors.red : AppTheme.secondaryGold)
                            .withValues(alpha: 0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _schumannData!.interpretation,
                  style: AppTheme.bodyMedium.copyWith(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Live-Grafik (60 Sekunden History)
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildSchumannChart(),
          ),
          
          const SizedBox(height: 16),
          
          // Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Amplitude',
                _schumannData!.amplitude.toStringAsFixed(2),
                Icons.show_chart,
              ),
              _buildStatItem(
                'Qualität',
                _schumannData!.quality.toStringAsFixed(1),
                Icons.high_quality,
              ),
              _buildStatItem(
                'Samples',
                '${_schumannHistory.length}/60s',
                Icons.timeline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchumannChart() {
    if (_schumannHistory.length < 2) {
      return Center(
        child: Text(
          'Sammle Live-Daten...',
          style: AppTheme.bodyMedium,
        ),
      );
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.primaryPurple.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)}',
                  style: AppTheme.bodySmall.copyWith(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 15 == 0) {
                  return Text(
                    '-${60 - value.toInt()}s',
                    style: AppTheme.bodySmall.copyWith(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppTheme.primaryPurple.withValues(alpha: 0.2),
          ),
        ),
        minX: 0,
        maxX: _schumannHistory.length.toDouble() - 1,
        minY: 7.0,
        maxY: 9.0,
        lineBarsData: [
          LineChartBarData(
            spots: _schumannHistory.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value.frequency,
              );
            }).toList(),
            isCurved: true,
            color: AppTheme.secondaryGold,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondaryGold.withValues(alpha: 0.3),
                  AppTheme.secondaryGold.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Normalbereich-Linie (7.83 Hz)
          LineChartBarData(
            spots: [
              FlSpot(0, 7.83),
              FlSpot(_schumannHistory.length.toDouble() - 1, 7.83),
            ],
            isCurved: false,
            color: Colors.green.withValues(alpha: 0.5),
            barWidth: 1,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildPopulationCard() {
    if (_populationStats == null) return const SizedBox.shrink();
    
    final timeFormat = DateFormat('HH:mm:ss');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            AppTheme.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weltbevölkerung Live',
                      style: AppTheme.headlineMedium.copyWith(fontSize: 18),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Update: ${timeFormat.format(_lastPopulationUpdate!)}',
                          style: AppTheme.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Geburten
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.child_care, color: Colors.green, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Geburten heute',
                        style: AppTheme.bodyMedium.copyWith(fontSize: 14),
                      ),
                      Text(
                        NumberFormat('#,###').format(_populationStats!.birthsToday),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${_populationStats!.birthsPerSecond.toStringAsFixed(2)}/Sek',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Todesfälle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.sentiment_very_dissatisfied, color: Colors.red, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Todesfälle heute',
                        style: AppTheme.bodyMedium.copyWith(fontSize: 14),
                      ),
                      Text(
                        NumberFormat('#,###').format(_populationStats!.deathsToday),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        '${_populationStats!.deathsPerSecond.toStringAsFixed(2)}/Sek',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Netto-Wachstum
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryPurple.withValues(alpha: 0.2),
                  AppTheme.secondaryGold.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.secondaryGold.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Netto-Wachstum heute',
                      style: AppTheme.bodyMedium.copyWith(fontSize: 14),
                    ),
                    Text(
                      '+${NumberFormat('#,###').format(_populationStats!.netGrowthToday)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryGold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.trending_up,
                  color: AppTheme.secondaryGold,
                  size: 56,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolcanoCard() {
    final timeFormat = DateFormat('HH:mm:ss');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepOrange.withValues(alpha: 0.15),
            AppTheme.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.deepOrange.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.whatshot,
                  color: Colors.deepOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktive Vulkane',
                      style: AppTheme.headlineMedium.copyWith(fontSize: 18),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Update: ${timeFormat.format(_lastVolcanoUpdate!)}',
                          style: AppTheme.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_volcanoes.length}',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ..._volcanoes.map((volcano) => _buildVolcanoItem(volcano)),
        ],
      ),
    );
  }

  Widget _buildVolcanoItem(VolcanoData volcano) {
    final activityColor = _getActivityColor(volcano.activityLevel);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: activityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activityColor.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.whatshot,
            color: activityColor,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  volcano.name,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  volcano.country,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.secondaryGold,
                  ),
                ),
                Text(
                  '${volcano.elevation}m • ${volcano.timeSinceEruption}',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: activityColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activityColor.withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              volcano.activityLevel,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarthquakeCard() {
    final timeFormat = DateFormat('HH:mm:ss');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.15),
            AppTheme.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.crisis_alert,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Erdbeben (24h)',
                      style: AppTheme.headlineMedium.copyWith(fontSize: 18),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Update: ${timeFormat.format(_lastEarthquakeUpdate!)}',
                          style: AppTheme.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_earthquakes.length}',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_earthquakes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Keine signifikanten Erdbeben',
                  style: AppTheme.bodyMedium,
                ),
              ),
            )
          else
            ...(_earthquakes.take(5).map((eq) => _buildEarthquakeItem(eq))),
        ],
      ),
    );
  }

  Widget _buildEarthquakeItem(EarthquakeData eq) {
    final color = _getEarthquakeColor(eq.magnitude);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                eq.magnitude.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eq.place,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  eq.magnitudeClass,
                  style: AppTheme.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${eq.depth.toStringAsFixed(0)}km Tiefe • ${_formatTime(eq.time)}',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryPurple,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(fontSize: 10),
        ),
      ],
    );
  }

  Color _getEarthquakeColor(double magnitude) {
    if (magnitude >= 7.0) return Colors.red;
    if (magnitude >= 6.0) return Colors.deepOrange;
    if (magnitude >= 5.0) return Colors.orange;
    if (magnitude >= 4.0) return Colors.yellow;
    return Colors.green;
  }

  Color _getActivityColor(String activityLevel) {
    switch (activityLevel) {
      case 'Hoch':
      case 'Dauerhaft':
        return Colors.red;
      case 'Mittel':
        return Colors.orange;
      default:
        return Colors.yellow;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return 'Vor ${diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      return 'Vor ${diff.inHours}h';
    } else {
      return 'Vor ${diff.inDays}d';
    }
  }

  // ========== ENHANCED SECTIONS ==========

  Widget _buildEnhancedSchumannCard() {
    if (_enhancedSchumann == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryPurple.withValues(alpha: 0.15),
              AppTheme.surfaceDark,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SchumannSpectrogramWidget(
        data: _enhancedSchumann!,
        height: 250,
      ),
    );
  }

  // ❌ KOMPLETT ENTFERNT: Population & Correlation Widgets (nicht mehr verwendet)
  
  // ========== MAGNETOMETER ALERT SYSTEM ==========
  
  void _checkMagnetometerAlerts(KirunaMagnetometerData data) {
    if (data.dataPoints.isEmpty) return;
    
    final lastPoint = data.dataPoints.last;
    final stats = data.statistics;
    
    // Schwellenwerte für Alarme (basierend auf typischen Werten)
    const double extremeThreshold = 50.0; // Extreme Änderung in nT
    const double highThreshold = 30.0;    // Hohe Änderung in nT
    
    // Prüfe X-Komponente
    if ((stats.xMax - stats.xMin).abs() > extremeThreshold) {
      _showMagnetometerAlert(
        'EXTREM',
        'Extreme Schwankungen in X-Komponente (Nord-Süd)',
        '${(stats.xMax - stats.xMin).toStringAsFixed(2)} nT',
        Colors.red.shade700,
      );
    } else if ((stats.xMax - stats.xMin).abs() > highThreshold) {
      _showMagnetometerAlert(
        'WARNUNG',
        'Starke Schwankungen in X-Komponente',
        '${(stats.xMax - stats.xMin).toStringAsFixed(2)} nT',
        Colors.orange,
      );
    }
    
    // Prüfe auf plötzliche Änderungen
    if (data.dataPoints.length > 1) {
      final previousPoint = data.dataPoints[data.dataPoints.length - 2];
      final xChange = (lastPoint.x - previousPoint.x).abs();
      final yChange = (lastPoint.y - previousPoint.y).abs();
      final zChange = (lastPoint.z - previousPoint.z).abs();
      
      if (xChange > 5.0 || yChange > 5.0 || zChange > 5.0) {
        _showMagnetometerAlert(
          'ACHTUNG',
          'Plötzliche Magnetfeldänderung erkannt',
          'Δ: X=${xChange.toStringAsFixed(1)} Y=${yChange.toStringAsFixed(1)} Z=${zChange.toStringAsFixed(1)} nT',
          Colors.yellow.shade700,
        );
      }
    }
  }
  
  void _showMagnetometerAlert(String level, String title, String details, Color color) {
    // Verhindere zu viele Benachrichtigungen
    final now = DateTime.now();
    if (_lastAlertTime != null && now.difference(_lastAlertTime!).inMinutes < 5) {
      return; // Nicht öfter als alle 5 Minuten
    }
    _lastAlertTime = now;
    
    // Zeige SnackBar mit Alert
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: color,
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    level,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                details,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kiruna Magnetometer',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }
  
  DateTime? _lastAlertTime;
  
  // ========== KIRUNA MAGNETOMETER CARD ==========
  
  Widget _buildKirunaCard() {
    if (_kirunaData == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryPurple.withValues(alpha: 0.15),
              AppTheme.backgroundDark,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
          ),
        ),
      );
    }

    final lastDataPoint = _kirunaData!.dataPoints.isNotEmpty 
        ? _kirunaData!.dataPoints.last 
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withValues(alpha: 0.15),
            AppTheme.backgroundDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple,
                      AppTheme.secondaryGold,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryGold.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.explore,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kiruna Magnetometer',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'IRF Schweden • Live-Daten',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.secondaryGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Live Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Aktuelle Messwerte
          if (lastDataPoint != null) ...[
            Text(
              'Aktuelle Messwerte',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryGold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMagnetometerValue(
                    'X (Nord-Süd)',
                    lastDataPoint.x,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMagnetometerValue(
                    'Y (Ost-West)',
                    lastDataPoint.y,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMagnetometerValue(
                    'Z (Vertikal)',
                    lastDataPoint.z,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
          ],
          
          // Line Chart für X/Y/Z Verlauf
          Text(
            'Magnetfeld-Verlauf (letzte 10 Minuten)',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryGold,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: _buildMagnetometerChart(),
          ),
          
          const SizedBox(height: 20),
          
          // K-Index (Geomagnetische Aktivität)
          Text(
            'Geomagnetische Aktivität',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryGold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildKIndexCard(),
          
          const SizedBox(height: 20),
          
          // Live Magnetogram Bild
          Text(
            'Live Magnetogramm',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryGold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildMagnetogramImage(),
          
          const SizedBox(height: 20),
          
          // Statistiken
          Text(
            'Statistik (letzte Stunde)',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryGold,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Datenpunkte:', style: AppTheme.bodyMedium),
                    Text(
                      '${_kirunaData!.dataPoints.length}',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Min X:', style: AppTheme.bodyMedium),
                    Text(
                      '${_kirunaData!.statistics.xMin.toStringAsFixed(2)} nT',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Max X:', style: AppTheme.bodyMedium),
                    Text(
                      '${_kirunaData!.statistics.xMax.toStringAsFixed(2)} nT',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Letztes Update
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Letztes Update: ${_formatKirunaTime(_kirunaData!.lastUpdate)}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                Icons.autorenew,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Aktualisierung alle 5 Minuten',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMagnetometerValue(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            'nT',
            style: AppTheme.bodySmall.copyWith(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatKirunaTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) {
      return 'vor ${diff.inSeconds} Sek';
    } else if (diff.inMinutes < 60) {
      return 'vor ${diff.inMinutes} Min';
    } else {
      return 'vor ${diff.inHours} Std';
    }
  }
  
  // ========== KIRUNA CHART WIDGET ==========
  
  Widget _buildMagnetometerChart() {
    if (_kirunaData == null || _kirunaData!.dataPoints.isEmpty) {
      return const Center(
        child: Text('Keine Daten verfügbar', style: TextStyle(color: Colors.grey)),
      );
    }
    
    // Nehme nur die letzten 10 Minuten (600 Datenpunkte bei 1 Sek Auflösung)
    final last10Min = _kirunaData!.getLastMinutes(10);
    
    if (last10Min.isEmpty) {
      return const Center(
        child: Text('Keine aktuellen Daten', style: TextStyle(color: Colors.grey)),
      );
    }
    
    // Konvertiere zu Chart-Spots
    final xSpots = <FlSpot>[];
    final ySpots = <FlSpot>[];
    final zSpots = <FlSpot>[];
    
    for (int i = 0; i < last10Min.length; i++) {
      final point = last10Min[i];
      final x = i.toDouble();
      xSpots.add(FlSpot(x, point.x));
      ySpots.add(FlSpot(x, point.y));
      zSpots.add(FlSpot(x, point.z));
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.textSecondary.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: last10Min.length / 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= last10Min.length) return const SizedBox();
                final point = last10Min[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${point.timestamp.hour}:${point.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: 10,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()} nT',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        minX: 0,
        maxX: (last10Min.length - 1).toDouble(),
        lineBarsData: [
          // X Komponente (Rot)
          LineChartBarData(
            spots: xSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Y Komponente (Grün)
          LineChartBarData(
            spots: ySpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Z Komponente (Blau)
          LineChartBarData(
            spots: zSpots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final colors = [Colors.red, Colors.green, Colors.blue];
                final labels = ['X', 'Y', 'Z'];
                return LineTooltipItem(
                  '${labels[spot.barIndex]}: ${spot.y.toStringAsFixed(2)} nT',
                  TextStyle(
                    color: colors[spot.barIndex],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
  
  // ========== K-INDEX CARD ==========
  
  Widget _buildKIndexCard() {
    return FutureBuilder<int?>(
      future: _kirunaService.fetchKIndex(),
      builder: (context, snapshot) {
        final kIndex = snapshot.data ?? 0;
        final Color kIndexColor = _getKIndexColor(kIndex);
        final String kIndexLevel = _getKIndexLevel(kIndex);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kIndexColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: kIndexColor.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: kIndexColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kIndexColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'K$kIndex',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kIndexLevel,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kIndexColor,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getKIndexDescription(kIndex),
                      style: AppTheme.bodySmall.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Color _getKIndexColor(int kIndex) {
    if (kIndex >= 7) return Colors.red.shade700;
    if (kIndex >= 5) return Colors.red;
    if (kIndex >= 4) return Colors.orange;
    if (kIndex >= 3) return Colors.yellow.shade700;
    return Colors.green;
  }
  
  String _getKIndexLevel(int kIndex) {
    if (kIndex >= 7) return 'Extremer Sturm';
    if (kIndex >= 5) return 'Geomagnetischer Sturm';
    if (kIndex >= 4) return 'Starke Aktivität';
    if (kIndex >= 3) return 'Moderate Aktivität';
    return 'Ruhig';
  }
  
  String _getKIndexDescription(int kIndex) {
    if (kIndex >= 7) return 'Extreme geomagnetische Störungen';
    if (kIndex >= 5) return 'Mögliche Auswirkungen auf Satelliten und Stromnetze';
    if (kIndex >= 4) return 'Erhöhte magnetische Aktivität';
    if (kIndex >= 3) return 'Leicht erhöhte Aktivität';
    return 'Normale magnetische Bedingungen';
  }
  
  // ========== MAGNETOGRAM IMAGE ==========
  
  Widget _buildMagnetogramImage() {
    final imageUrl = _kirunaService.getMagnetogramImageUrl();
    
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bild konnte nicht geladen werden',
                    style: AppTheme.bodySmall.copyWith(color: Colors.red),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Schumann-Resonanz Datenpunkt für Grafik
class SchumannDataPoint {
  final DateTime timestamp;
  final double frequency;

  SchumannDataPoint({
    required this.timestamp,
    required this.frequency,
  });
}
