import 'package:flutter/material.dart';
import 'dart:math';
import '../models/enhanced_schumann_data.dart';

/// Spektrogramm-Widget für Schumann-Resonanz Harmonische
/// 
/// Zeigt die 5 primären Schumann-Resonanz Modes:
/// - 7.83 Hz (Fundamental)
/// - 14.1 Hz (2. Harmonische)
/// - 20.3 Hz (3. Harmonische)
/// - 26.4 Hz (4. Harmonische)
/// - 32.5 Hz (5. Harmonische)
class SchumannSpectrogramWidget extends StatelessWidget {
  final EnhancedSchumannData data;
  final bool showLabels;
  final double height;

  const SchumannSpectrogramWidget({
    super.key,
    required this.data,
    this.showLabels = true,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: const Color(0xFF1a1a1a),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.graphic_eq, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Schumann-Resonanz Spektrum',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                _buildAnomalyBadge(context),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Erdmagnetfeld-Frequenzen (Harmonische)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            
            // Spektrogramm
            SizedBox(
              height: height,
              child: CustomPaint(
                painter: _SpectrogramPainter(
                  harmonics: data.harmonics,
                  currentFrequency: data.currentFrequency,
                  amplitude: data.currentAmplitude,
                  anomalyLevel: data.anomalyLevel,
                  showLabels: showLabels,
                ),
                child: Container(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Aktuelle Werte
            _buildCurrentValues(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyBadge(BuildContext context) {
    final color = _getAnomalyColor(data.anomalyLevel);
    final text = _getAnomalyText(data.anomalyLevel);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getAnomalyIcon(data.anomalyLevel),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem(
          'Fundamental (7.83 Hz)',
          Colors.deepPurple,
        ),
        _buildLegendItem(
          '2. Mode (14.1 Hz)',
          Colors.blue,
        ),
        _buildLegendItem(
          '3. Mode (20.3 Hz)',
          Colors.cyan,
        ),
        _buildLegendItem(
          '4. Mode (26.4 Hz)',
          Colors.green,
        ),
        _buildLegendItem(
          '5. Mode (32.5 Hz)',
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCurrentValues(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildValueItem(
            'Frequenz',
            '${data.currentFrequency.toStringAsFixed(2)} Hz',
            Icons.waves,
            Colors.amber,
          ),
          _buildValueItem(
            'Amplitude',
            data.currentAmplitude.toStringAsFixed(2),
            Icons.show_chart,
            Colors.blue,
          ),
          _buildValueItem(
            'Trend',
            _getTrendText(data.trend),
            _getTrendIcon(data.trend),
            _getTrendColor(data.trend),
          ),
        ],
      ),
    );
  }

  Widget _buildValueItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getTrendColor(SchumannTrend trend) {
    switch (trend) {
      case SchumannTrend.rising:
        return Colors.green;
      case SchumannTrend.falling:
        return Colors.red;
      case SchumannTrend.stable:
        return Colors.blue;
      case SchumannTrend.volatile:
        return Colors.orange;
    }
  }

  Color _getAnomalyColor(AnomalyLevel level) {
    switch (level) {
      case AnomalyLevel.normal:
        return Colors.green;
      case AnomalyLevel.low:
        return Colors.lightGreen;
      case AnomalyLevel.moderate:
        return Colors.orange;
      case AnomalyLevel.high:
        return Colors.deepOrange;
      case AnomalyLevel.extreme:
        return Colors.red;
    }
  }

  String _getAnomalyText(AnomalyLevel level) {
    switch (level) {
      case AnomalyLevel.normal:
        return 'Normal';
      case AnomalyLevel.low:
        return 'Leicht erhöht';
      case AnomalyLevel.moderate:
        return 'Moderat';
      case AnomalyLevel.high:
        return 'Hoch';
      case AnomalyLevel.extreme:
        return 'Extrem';
    }
  }

  IconData _getAnomalyIcon(AnomalyLevel level) {
    switch (level) {
      case AnomalyLevel.normal:
        return Icons.check_circle;
      case AnomalyLevel.low:
        return Icons.info;
      case AnomalyLevel.moderate:
        return Icons.warning_amber;
      case AnomalyLevel.high:
        return Icons.warning;
      case AnomalyLevel.extreme:
        return Icons.emergency;
    }
  }

  String _getTrendText(SchumannTrend trend) {
    switch (trend) {
      case SchumannTrend.rising:
        return 'Steigend';
      case SchumannTrend.falling:
        return 'Fallend';
      case SchumannTrend.stable:
        return 'Stabil';
      case SchumannTrend.volatile:
        return 'Volatil';
    }
  }

  IconData _getTrendIcon(SchumannTrend trend) {
    switch (trend) {
      case SchumannTrend.rising:
        return Icons.trending_up;
      case SchumannTrend.falling:
        return Icons.trending_down;
      case SchumannTrend.stable:
        return Icons.trending_flat;
      case SchumannTrend.volatile:
        return Icons.swap_vert;
    }
  }
}

/// Custom Painter für Spektrogramm
class _SpectrogramPainter extends CustomPainter {
  final List<double> harmonics;
  final double currentFrequency;
  final double amplitude;
  final AnomalyLevel anomalyLevel;
  final bool showLabels;

  _SpectrogramPainter({
    required this.harmonics,
    required this.currentFrequency,
    required this.amplitude,
    required this.anomalyLevel,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Hintergrund
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Gitterlinien
    _drawGrid(canvas, size);

    // Harmonische als Balken
    _drawHarmonics(canvas, size);

    // Aktuelle Frequenz-Markierung
    _drawCurrentFrequencyMarker(canvas, size);

    // Frequenz-Achse Labels
    if (showLabels) {
      _drawFrequencyLabels(canvas, size);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Horizontale Linien (Amplitude)
    for (int i = 0; i <= 5; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Vertikale Linien (Frequenz)
    for (int i = 0; i <= 10; i++) {
      final x = size.width * (i / 10);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }

  void _drawHarmonics(Canvas canvas, Size size) {
    final maxFrequency = 40.0; // Hz (Anzeigebereich)
    final barWidth = size.width / 10; // Breitere Balken
    
    final colors = [
      Colors.amber,      // Fundamental - Gold
      Colors.blue,       // 2. Harmonische
      Colors.cyan,       // 3. Harmonische
      Colors.green,      // 4. Harmonische
      Colors.orange,     // 5. Harmonische
    ];

    for (int i = 0; i < harmonics.length && i < 5; i++) {
      final harmonic = harmonics[i];
      final color = colors[i];
      
      // Berechne Position
      final x = size.width * (harmonic / maxFrequency);
      
      // REALISTISCHE Höhe: Erste Harmonische am höchsten, dann abnehmend
      final heightFactors = [1.0, 0.7, 0.5, 0.35, 0.25];
      final baseHeight = size.height * 0.8; // 80% der Höhe max
      final barHeight = baseHeight * heightFactors[i] * amplitude;
      
      // Zeichne Balken mit Glow-Effekt
      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.9),
            color.withOpacity(0.4),
          ],
        ).createShader(Rect.fromLTWH(
          x - barWidth / 2,
          size.height - barHeight,
          barWidth,
          barHeight,
        ))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - barWidth / 2,
            size.height - barHeight,
            barWidth,
            barHeight,
          ),
          const Radius.circular(8),
        ),
        barPaint,
      );

      // Zeichne Leucht-Rahmen
      final borderPaint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - barWidth / 2,
            size.height - barHeight,
            barWidth,
            barHeight,
          ),
          const Radius.circular(8),
        ),
        borderPaint,
      );

      // Zeichne Label UNTER dem Balken
      if (showLabels) {
        final labels = ['7.8 Hz\nFundamental', '14 Hz', '20 Hz', '26 Hz', '33 Hz'];
        final textPainter = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            x - textPainter.width / 2,
            size.height + 5,
          ),
        );
      }
    }
  }

  void _drawCurrentFrequencyMarker(Canvas canvas, Size size) {
    final maxFrequency = 40.0;
    final x = size.width * (currentFrequency / maxFrequency);

    // Vertikale Linie
    final linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      linePaint,
    );

    // Pfeil oben
    final arrowPath = Path();
    arrowPath.moveTo(x, 0);
    arrowPath.lineTo(x - 6, 10);
    arrowPath.lineTo(x + 6, 10);
    arrowPath.close();

    final arrowPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawPath(arrowPath, arrowPaint);

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Aktuell\n${currentFrequency.toStringAsFixed(2)} Hz',
        style: const TextStyle(
          color: Colors.red,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Position: rechts oder links je nach verfügbarem Platz
    final labelX = x + 10 < size.width - textPainter.width 
        ? x + 10 
        : x - textPainter.width - 10;
    
    textPainter.paint(canvas, Offset(labelX, 15));
  }

  void _drawFrequencyLabels(Canvas canvas, Size size) {
    final maxFrequency = 40.0;
    final intervals = [0, 10, 20, 30, 40];

    for (final freq in intervals) {
      final x = size.width * (freq / maxFrequency);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$freq Hz',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 15),
      );
    }
  }

  @override
  bool shouldRepaint(_SpectrogramPainter oldDelegate) {
    return oldDelegate.currentFrequency != currentFrequency ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.anomalyLevel != anomalyLevel;
  }
}
