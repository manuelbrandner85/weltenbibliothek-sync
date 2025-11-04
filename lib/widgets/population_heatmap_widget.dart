import 'package:flutter/material.dart';
import '../models/enhanced_population_data.dart';

/// VEREINFACHTE Population Widget
/// 
/// Zeigt einfache, verständliche Bevölkerungsstatistiken:
/// - Kontinente-Verteilung
/// - Top Städte
/// - Live-Zahlen
class PopulationHeatmapWidget extends StatelessWidget {
  final EnhancedPopulationData data;
  final double height;

  const PopulationHeatmapWidget({
    super.key,
    required this.data,
    this.height = 400,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.public, color: Colors.blue, size: 28),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Weltbevölkerung Live',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                _buildLiveIndicator(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Aktuelle Bevölkerungszahlen nach Kontinenten',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            
            // Kontinente-Statistik
            _buildContinentStats(context),
            
            const SizedBox(height: 20),
            
            // Top Städte
            _buildTopCities(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
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
    );
  }

  Widget _buildContinentStats(BuildContext context) {
    final continents = data.byContinent;
    final currentPop = data.getCurrentPopulation();
    
    return Column(
      children: continents.entries.map((entry) {
        final continent = entry.key;
        final population = entry.value;
        final percentage = (population / currentPop * 100);
        
        final color = _getContinentColor(continent);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    continent,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_formatNumber(population)} Menschen',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${percentage.toStringAsFixed(1)}% der Weltbevölkerung',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopCities(BuildContext context) {
    final topCities = data.densityPoints.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top 5 Megastädte',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...topCities.asMap().entries.map((entry) {
          final index = entry.key;
          final city = entry.value;
          final densityColor = _getDensityColor(city.density);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: densityColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: densityColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
                        city.cityName ?? 'Stadt ${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_formatDensity(city.density)} Menschen/km²',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: densityColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getContinentColor(String continent) {
    switch (continent) {
      case 'Asien':
        return Colors.red;
      case 'Afrika':
        return Colors.orange;
      case 'Europa':
        return Colors.blue;
      case 'Nordamerika':
        return Colors.green;
      case 'Südamerika':
        return Colors.purple;
      case 'Ozeanien':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  Color _getDensityColor(double density) {
    if (density > 20000) return Colors.red;
    if (density > 10000) return Colors.orange;
    if (density > 5000) return Colors.yellow;
    return Colors.green;
  }

  String _formatNumber(int number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)} Mrd';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(0)} Mio';
    } else {
      return number.toString();
    }
  }

  String _formatDensity(double density) {
    if (density >= 10000) {
      return '${(density / 1000).toStringAsFixed(1)}k';
    } else {
      return density.toStringAsFixed(0);
    }
  }
}
