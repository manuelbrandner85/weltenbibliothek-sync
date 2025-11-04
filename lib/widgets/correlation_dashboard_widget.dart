import 'package:flutter/material.dart';
import 'dart:math';
import '../services/correlation_service.dart';

/// Correlation Dashboard Widget
/// 
/// Zeigt Korrelations-Analysen zwischen verschiedenen Phänomenen:
/// - Schumann ↔ Erdbeben
/// - Schumann ↔ UFOs
/// - Schumann ↔ Solare Aktivität
/// - Bevölkerung ↔ Umwelt
class CorrelationDashboardWidget extends StatelessWidget {
  final CorrelationAnalysis analysis;

  const CorrelationDashboardWidget({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.insights, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Korrelations-Analyse',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Aktualisiert: ${_formatTime(analysis.timestamp)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Korrelations-Matrix
            _buildCorrelationMatrix(context),

            const SizedBox(height: 24),

            // Erkannte Muster
            if (analysis.detectedPatterns.isNotEmpty) ...[
              const Text(
                'Erkannte Muster',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...analysis.detectedPatterns.map((pattern) => 
                _buildPatternCard(context, pattern)
              ),
            ] else ...[
              _buildNoPatterns(context),
            ],

            const SizedBox(height: 24),

            // Scatter Plots
            const Text(
              'Scatter Plots',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildScatterPlots(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationMatrix(BuildContext context) {
    final correlations = [
      ('Schumann ↔ Erdbeben', analysis.schumannEarthquakeCorrelation),
      ('Schumann ↔ UFOs', analysis.schumannUFOCorrelation),
      ('Schumann ↔ Solar', analysis.schumannSolarCorrelation),
      ('Bevölkerung ↔ Umwelt', analysis.populationEnvironmentCorrelation),
    ];

    return Column(
      children: correlations.map((correlation) {
        final name = correlation.$1;
        final result = correlation.$2;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildCorrelationRow(context, name, result),
        );
      }).toList(),
    );
  }

  Widget _buildCorrelationRow(BuildContext context, String name, CorrelationResult result) {
    final color = _getCorrelationColor(result.coefficient);
    final absCoeff = result.coefficient.abs();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStrengthBadge(result.strength, result.coefficient),
            ],
          ),
          const SizedBox(height: 8),
          // Korrelations-Balken
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: absCoeff,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                result.coefficient.toStringAsFixed(3),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            result.description,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthBadge(CorrelationStrength strength, double coefficient) {
    final isPositive = coefficient > 0;
    final text = _getStrengthText(strength);
    final color = _getCorrelationColor(coefficient);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternCard(BuildContext context, DetectedPattern pattern) {
    final color = _getPatternColor(pattern.confidence);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              _getPatternIcon(pattern.type),
              color: color,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pattern.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pattern.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Text(
                  '${(pattern.confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  'Konfidenz',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPatterns(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Keine signifikanten Muster erkannt',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScatterPlots(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (analysis.schumannEarthquakeCorrelation.dataPoints.isNotEmpty)
            _buildScatterPlot(
              context,
              'Schumann vs Erdbeben',
              analysis.schumannEarthquakeCorrelation,
              'Schumann (Hz)',
              'Erdbeben Magnitude',
            ),
          if (analysis.schumannSolarCorrelation.dataPoints.isNotEmpty)
            _buildScatterPlot(
              context,
              'Schumann vs Solar',
              analysis.schumannSolarCorrelation,
              'Schumann (Hz)',
              'Solar Flux',
            ),
        ],
      ),
    );
  }

  Widget _buildScatterPlot(
    BuildContext context,
    String title,
    CorrelationResult result,
    String xLabel,
    String yLabel,
  ) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: _ScatterPlotPainter(
                dataPoints: result.dataPoints,
                xLabel: xLabel,
                yLabel: yLabel,
                coefficient: result.coefficient,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCorrelationColor(double coefficient) {
    final absCoeff = coefficient.abs();
    if (absCoeff >= 0.7) return Colors.green;
    if (absCoeff >= 0.5) return Colors.blue;
    if (absCoeff >= 0.3) return Colors.orange;
    return Colors.grey;
  }

  Color _getPatternColor(double confidence) {
    if (confidence >= 0.7) return Colors.red;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.blue;
  }

  String _getStrengthText(CorrelationStrength strength) {
    switch (strength) {
      case CorrelationStrength.strong:
        return 'Stark';
      case CorrelationStrength.moderate:
        return 'Moderat';
      case CorrelationStrength.weak:
        return 'Schwach';
      case CorrelationStrength.none:
        return 'Keine';
    }
  }

  IconData _getPatternIcon(PatternType type) {
    switch (type) {
      case PatternType.schumannEarthquake:
        return Icons.public;
      case PatternType.solarSchumann:
        return Icons.wb_sunny;
      case PatternType.schumannUFO:
        return Icons.flight;
      case PatternType.other:
        return Icons.pattern;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'Vor ${diff.inMinutes} Min';
    if (diff.inHours < 24) return 'Vor ${diff.inHours} Std';
    return 'Vor ${diff.inDays} Tagen';
  }
}

/// Scatter Plot Painter
class _ScatterPlotPainter extends CustomPainter {
  final List<CorrelationDataPoint> dataPoints;
  final String xLabel;
  final String yLabel;
  final double coefficient;

  _ScatterPlotPainter({
    required this.dataPoints,
    required this.xLabel,
    required this.yLabel,
    required this.coefficient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // Margins
    const margin = 40.0;
    final plotWidth = size.width - 2 * margin;
    final plotHeight = size.height - 2 * margin;

    // Background
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(margin, margin, plotWidth, plotHeight),
      bgPaint,
    );

    // Grid
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 5; i++) {
      final y = margin + (plotHeight * i / 5);
      canvas.drawLine(
        Offset(margin, y),
        Offset(margin + plotWidth, y),
        gridPaint,
      );
      
      final x = margin + (plotWidth * i / 5);
      canvas.drawLine(
        Offset(x, margin),
        Offset(x, margin + plotHeight),
        gridPaint,
      );
    }

    // Axes
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(margin, margin + plotHeight),
      Offset(margin + plotWidth, margin + plotHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin, margin + plotHeight),
      axisPaint,
    );

    // Find min/max for normalization
    final xValues = dataPoints.map((p) => p.x).toList();
    final yValues = dataPoints.map((p) => p.y).toList();
    
    final xMin = xValues.reduce(min);
    final xMax = xValues.reduce(max);
    final yMin = yValues.reduce(min);
    final yMax = yValues.reduce(max);

    final xRange = xMax - xMin;
    final yRange = yMax - yMin;

    // Draw regression line if correlation exists
    if (coefficient.abs() > 0.3) {
      _drawRegressionLine(
        canvas,
        size,
        margin,
        plotWidth,
        plotHeight,
        xMin,
        xRange,
        yMin,
        yRange,
      );
    }

    // Plot points
    final pointPaint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final point in dataPoints) {
      final x = margin + ((point.x - xMin) / xRange) * plotWidth;
      final y = margin + plotHeight - ((point.y - yMin) / yRange) * plotHeight;

      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      canvas.drawCircle(Offset(x, y), 4, pointBorderPaint);
    }
  }

  void _drawRegressionLine(
    Canvas canvas,
    Size size,
    double margin,
    double plotWidth,
    double plotHeight,
    double xMin,
    double xRange,
    double yMin,
    double yRange,
  ) {
    // Simple linear regression
    final n = dataPoints.length;
    final xMean = dataPoints.map((p) => p.x).reduce((a, b) => a + b) / n;
    final yMean = dataPoints.map((p) => p.y).reduce((a, b) => a + b) / n;

    double numerator = 0.0;
    double denominator = 0.0;

    for (final point in dataPoints) {
      numerator += (point.x - xMean) * (point.y - yMean);
      denominator += (point.x - xMean) * (point.x - xMean);
    }

    if (denominator == 0) return;

    final slope = numerator / denominator;
    final intercept = yMean - slope * xMean;

    // Draw line
    final y1 = slope * xMin + intercept;
    final y2 = slope * (xMin + xRange) + intercept;

    final x1 = margin;
    final x2 = margin + plotWidth;
    final py1 = margin + plotHeight - ((y1 - yMin) / yRange) * plotHeight;
    final py2 = margin + plotHeight - ((y2 - yMin) / yRange) * plotHeight;

    final linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(x1, py1), Offset(x2, py2), linePaint);
  }

  @override
  bool shouldRepaint(_ScatterPlotPainter oldDelegate) {
    return oldDelegate.dataPoints.length != dataPoints.length ||
           oldDelegate.coefficient != coefficient;
  }
}
