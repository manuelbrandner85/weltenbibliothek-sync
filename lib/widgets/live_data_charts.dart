import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../widgets/glass_card.dart';

/// Animierter Schumann-Resonanz Chart
class SchumannChart extends StatelessWidget {
  final double frequency;
  final double amplitude;
  
  const SchumannChart({
    super.key,
    required this.frequency,
    required this.amplitude,
  });

  @override
  Widget build(BuildContext context) {
    // Generiere Wellendaten für Visualization
    final spots = List.generate(50, (index) {
      final x = index.toDouble();
      final y = amplitude * (0.5 + 0.5 * (index % 10) / 10);
      return FlSpot(x, y);
    });
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      opacity: 0.1,
      border: Border.all(
        color: AppTheme.energyPhenomena.withValues(alpha: 0.4),
        width: 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.waves,
                color: AppTheme.energyPhenomena,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Schumann-Resonanz',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Frequency Display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.energyPhenomena.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequenz',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textWhite.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${frequency.toStringAsFixed(2)} Hz',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.energyPhenomena,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Amplitude',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textWhite.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${amplitude.toStringAsFixed(1)} pT',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.energyPhenomena,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Wave Chart
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textWhite.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 49,
                minY: 0,
                maxY: amplitude * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.energyPhenomena,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.energyPhenomena.withValues(alpha: 0.3),
                          AppTheme.energyPhenomena.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2000.ms, color: AppTheme.energyPhenomena.withValues(alpha: 0.3)),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.2, end: 0);
  }
}

/// Erdbeben-Aktivitäts-Chart
class EarthquakeActivityChart extends StatelessWidget {
  final List<double> magnitudes; // Letzten 24 Stunden
  
  const EarthquakeActivityChart({
    super.key,
    required this.magnitudes,
  });

  @override
  Widget build(BuildContext context) {
    final barGroups = magnitudes.asMap().entries.map((entry) {
      final color = _getMagnitudeColor(entry.value);
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: color,
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      opacity: 0.1,
      border: Border.all(
        color: AppTheme.errorRed.withValues(alpha: 0.4),
        width: 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: AppTheme.errorRed,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Erdbeben-Aktivität (24h)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '${magnitudes.length} Ereignisse',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textWhite.withValues(alpha: 0.6),
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 9,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}h',
                          style: TextStyle(
                            color: AppTheme.textWhite.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        );
                      },
                      interval: 6,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: AppTheme.textWhite.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        );
                      },
                      interval: 2,
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textWhite.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('< 5.0', Colors.green.shade700),
              const SizedBox(width: 16),
              _buildLegendItem('5.0-6.0', Colors.yellow.shade700),
              const SizedBox(width: 16),
              _buildLegendItem('> 6.0', Colors.red.shade700),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 200.ms)
      .slideY(begin: 0.2, end: 0, delay: 200.ms);
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textWhite.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
  
  Color _getMagnitudeColor(double magnitude) {
    if (magnitude >= 6.0) return Colors.red.shade700;
    if (magnitude >= 5.0) return Colors.yellow.shade700;
    return Colors.green.shade700;
  }
}

/// ISS Geschwindigkeits-Chart
class ISSVelocityChart extends StatelessWidget {
  final double velocity; // km/s
  
  const ISSVelocityChart({
    super.key,
    required this.velocity,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (velocity / 8.0).clamp(0.0, 1.0); // Max orbital velocity ~7.7 km/s
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      opacity: 0.1,
      border: Border.all(
        color: AppTheme.alienContact.withValues(alpha: 0.4),
        width: 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed,
                color: AppTheme.alienContact,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'ISS Geschwindigkeit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Circular Progress
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                children: [
                  // Background Circle
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    color: AppTheme.surfaceDark,
                  ),
                  
                  // Progress Circle
                  CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 12,
                    color: AppTheme.alienContact,
                    backgroundColor: Colors.transparent,
                  ).animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 2000.ms, color: AppTheme.alienContact.withValues(alpha: 0.5)),
                  
                  // Center Text
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          velocity.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.alienContact,
                          ),
                        ),
                        Text(
                          'km/s',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textWhite.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Additional Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.alienContact.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn('Umlaufzeit', '~90 min'),
                Container(
                  width: 1,
                  height: 30,
                  color: AppTheme.textWhite.withValues(alpha: 0.2),
                ),
                _buildInfoColumn('Höhe', '~408 km'),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 400.ms)
      .slideY(begin: 0.2, end: 0, delay: 400.ms);
  }
  
  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textWhite.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.alienContact,
          ),
        ),
      ],
    );
  }
}
