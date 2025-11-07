import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/live_data_service.dart';
import '../widgets/glass_card.dart';

/// Detaillierte Erdbeben-Karte mit Animationen
class EarthquakeDetailCard extends StatelessWidget {
  final EarthquakeData earthquake;
  final VoidCallback? onClose;

  const EarthquakeDetailCard({
    super.key,
    required this.earthquake,
    this.onClose,
  });

  Color _getMagnitudeColor(double magnitude) {
    if (magnitude >= 7.0) return Colors.red.shade900;
    if (magnitude >= 6.0) return Colors.red.shade700;
    if (magnitude >= 5.0) return Colors.orange.shade700;
    if (magnitude >= 4.0) return Colors.yellow.shade700;
    return Colors.green.shade700;
  }

  String _getMagnitudeLabel(double magnitude) {
    if (magnitude >= 8.0) return 'Katastrophal';
    if (magnitude >= 7.0) return 'Sehr stark';
    if (magnitude >= 6.0) return 'Stark';
    if (magnitude >= 5.0) return 'Moderat';
    if (magnitude >= 4.0) return 'Leicht';
    return 'Schwach';
  }

  @override
  Widget build(BuildContext context) {
    final magnitudeColor = _getMagnitudeColor(earthquake.magnitude);
    final magnitudeLabel = _getMagnitudeLabel(earthquake.magnitude);
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      blur: 20,
      opacity: 0.12,
      border: Border.all(
        color: magnitudeColor.withValues(alpha: 0.5),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: magnitudeColor.withValues(alpha: 0.4),
          blurRadius: 30,
          spreadRadius: 5,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Close Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: magnitudeColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: magnitudeColor.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: magnitudeColor,
                  size: 32,
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .shake(duration: 500.ms, hz: 2),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Erdbeben',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: magnitudeColor,
                      ),
                    ),
                    Text(
                      magnitudeLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textWhite.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  color: AppTheme.textWhite.withValues(alpha: 0.7),
                ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Magnitude Display
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    magnitudeColor.withValues(alpha: 0.8),
                    magnitudeColor.withValues(alpha: 0.3),
                    magnitudeColor.withValues(alpha: 0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: magnitudeColor.withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      earthquake.magnitude.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: magnitudeColor.withValues(alpha: 0.8),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Magnitude',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: 2000.ms,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
              ),
          ),
          
          const SizedBox(height: 24),
          
          // Details Grid
          _buildDetailRow(
            Icons.location_on,
            'Ort',
            earthquake.location,
            magnitudeColor,
          ),
          
          const SizedBox(height: 12),
          
          _buildDetailRow(
            Icons.schedule,
            'Zeit',
            DateFormat('dd.MM.yyyy HH:mm').format(earthquake.time),
            magnitudeColor,
          ),
          
          const SizedBox(height: 12),
          
          _buildDetailRow(
            Icons.public,
            'Koordinaten',
            '${earthquake.latitude.toStringAsFixed(3)}°, ${earthquake.longitude.toStringAsFixed(3)}°',
            magnitudeColor,
          ),
          
          const SizedBox(height: 12),
          
          _buildDetailRow(
            Icons.layers,
            'Tiefe',
            '${earthquake.depth.toStringAsFixed(1)} km',
            magnitudeColor,
          ),
          
          const SizedBox(height: 24),
          
          // Info Text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: magnitudeColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: magnitudeColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getMagnitudeInfo(earthquake.magnitude),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textWhite.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .scale(begin: const Offset(0.9, 0.9), duration: 400.ms);
  }
  
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color accentColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: accentColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textWhite.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getMagnitudeInfo(double magnitude) {
    if (magnitude >= 8.0) {
      return 'Katastrophale Zerstörung über große Gebiete. Massive Gebäudeschäden und Tsunamigefahr.';
    } else if (magnitude >= 7.0) {
      return 'Schwere Schäden in bewohnten Gebieten. Große strukturelle Zerstörung möglich.';
    } else if (magnitude >= 6.0) {
      return 'Starke Erschütterungen, die zu erheblichen Schäden führen können.';
    } else if (magnitude >= 5.0) {
      return 'Deutlich spürbar. Kann Schäden an Gebäuden verursachen.';
    } else if (magnitude >= 4.0) {
      return 'Oft spürbar, verursacht aber normalerweise keine Schäden.';
    } else {
      return 'Meist nur von Seismographen registriert, selten spürbar.';
    }
  }
}

/// Kompakte Erdbeben-Liste Widget
class EarthquakeListWidget extends StatelessWidget {
  final List<EarthquakeData> earthquakes;
  final Function(EarthquakeData)? onEarthquakeSelected;

  const EarthquakeListWidget({
    super.key,
    required this.earthquakes,
    this.onEarthquakeSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Sortiere nach Magnitude (höchste zuerst)
    final sortedEarthquakes = List<EarthquakeData>.from(earthquakes)
      ..sort((a, b) => b.magnitude.compareTo(a.magnitude));
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedEarthquakes.length > 10 ? 10 : sortedEarthquakes.length,
      itemBuilder: (context, index) {
        final quake = sortedEarthquakes[index];
        final magnitudeColor = _getMagnitudeColor(quake.magnitude);
        
        return GestureDetector(
          onTap: () => onEarthquakeSelected?.call(quake),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: magnitudeColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Magnitude Badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: magnitudeColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: magnitudeColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      quake.magnitude.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: magnitudeColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quake.location,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd.MM HH:mm').format(quake.time),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textWhite.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textWhite.withValues(alpha: 0.4),
                ),
              ],
            ),
          ).animate(delay: (index * 50).ms)
            .fadeIn(duration: 300.ms)
            .slideX(begin: -0.2, end: 0),
        );
      },
    );
  }
  
  Color _getMagnitudeColor(double magnitude) {
    if (magnitude >= 7.0) return Colors.red.shade700;
    if (magnitude >= 6.0) return Colors.orange.shade700;
    if (magnitude >= 5.0) return Colors.yellow.shade700;
    if (magnitude >= 4.0) return Colors.green.shade700;
    return Colors.blue.shade700;
  }
}
