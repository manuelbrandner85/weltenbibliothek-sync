import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/app_theme.dart';
import '../services/live_data_service.dart';
import '../widgets/glass_card.dart';

/// Erdbeben Detail Screen mit Karte und Informationen
class EarthquakeDetailScreen extends StatelessWidget {
  final EarthquakeData earthquake;
  
  const EarthquakeDetailScreen({
    super.key,
    required this.earthquake,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // App Bar mit Hero-Animation
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppTheme.surfaceDark,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Magnitude ${earthquake.magnitude.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Interaktive Mini-Karte
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(earthquake.latitude, earthquake.longitude),
                      initialZoom: 6.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(earthquake.latitude, earthquake.longitude),
                            color: _getMagnitudeColor(earthquake.magnitude)
                                .withValues(alpha: 0.4),
                            borderColor: _getMagnitudeColor(earthquake.magnitude),
                            borderStrokeWidth: 3,
                            radius: earthquake.magnitude * 15,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(earthquake.latitude, earthquake.longitude),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.warning,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.surfaceDark.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Magnitude Card
                  _buildMagnitudeCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Location Card
                  _buildLocationCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Details Card
                  _buildDetailsCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Impact Info
                  _buildImpactInfo(),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMagnitudeCard() {
    final color = _getMagnitudeColor(earthquake.magnitude);
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      blur: 20,
      opacity: 0.1,
      border: Border.all(
        color: color.withValues(alpha: 0.4),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 25,
          spreadRadius: 3,
        ),
      ],
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
            child: Text(
              earthquake.magnitude.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMagnitudeCategory(earthquake.magnitude),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getMagnitudeDescription(earthquake.magnitude),
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
    ).animate()
      .fadeIn(duration: 400.ms)
      .scale(delay: 200.ms);
  }
  
  Widget _buildLocationCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppTheme.errorRed,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Standort',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Ort',
            earthquake.place,
            Icons.place,
          ),
          _buildInfoRow(
            'Koordinaten',
            '${earthquake.latitude.toStringAsFixed(3)}°, ${earthquake.longitude.toStringAsFixed(3)}°',
            Icons.gps_fixed,
          ),
          _buildInfoRow(
            'Tiefe',
            '${earthquake.depth.toStringAsFixed(1)} km',
            Icons.arrow_downward,
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 400.ms, duration: 400.ms)
      .slideY(begin: 0.2, end: 0);
  }
  
  Widget _buildDetailsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primaryPurple,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Zeitpunkt',
            DateFormat('dd.MM.yyyy HH:mm').format(earthquake.time),
            Icons.access_time,
          ),
          _buildInfoRow(
            'Typ',
            earthquake.type,
            Icons.category,
          ),
          if (earthquake.tsunami)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.waves, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tsunami-Warnung aktiv',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 600.ms, duration: 400.ms)
      .slideY(begin: 0.2, end: 0);
  }
  
  Widget _buildImpactInfo() {
    final magnitude = earthquake.magnitude;
    String impactTitle;
    String impactText;
    IconData impactIcon;
    Color impactColor;
    
    if (magnitude < 4.0) {
      impactTitle = 'Geringer Einfluss';
      impactText = 'Meist nur von Instrumenten messbar. Kaum spürbar.';
      impactIcon = Icons.info;
      impactColor = Colors.green;
    } else if (magnitude < 5.0) {
      impactTitle = 'Leichte Erschütterungen';
      impactText = 'Spürbar in bewohnten Gebieten. Geringe Schäden möglich.';
      impactIcon = Icons.warning_amber;
      impactColor = Colors.yellow;
    } else if (magnitude < 6.0) {
      impactTitle = 'Mäßige Schäden';
      impactText = 'Schäden an Gebäuden möglich. Deutlich spürbar.';
      impactIcon = Icons.warning;
      impactColor = Colors.orange;
    } else {
      impactTitle = 'Schwere Schäden';
      impactText = 'Erhebliche Zerstörungen möglich. Gefahr für Menschen.';
      impactIcon = Icons.dangerous;
      impactColor = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            impactColor.withValues(alpha: 0.2),
            impactColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: impactColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: impactColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              impactIcon,
              color: impactColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  impactTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: impactColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  impactText,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textWhite.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 800.ms, duration: 400.ms);
  }
  
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openUSGSLink(),
            icon: const Icon(Icons.open_in_new),
            label: const Text('USGS Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openInMaps(context),
            icon: const Icon(Icons.map),
            label: const Text('In Karte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryGold,
              foregroundColor: AppTheme.backgroundDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ).animate()
      .fadeIn(delay: 1000.ms, duration: 400.ms);
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.secondaryGold.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textWhite.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textWhite,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getMagnitudeColor(double magnitude) {
    if (magnitude < 4.0) {
      return Colors.green;
    } else if (magnitude < 5.0) {
      return Colors.yellow;
    } else if (magnitude < 6.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  String _getMagnitudeCategory(double magnitude) {
    if (magnitude < 4.0) {
      return 'Leichtes Beben';
    } else if (magnitude < 5.0) {
      return 'Mäßiges Beben';
    } else if (magnitude < 6.0) {
      return 'Starkes Beben';
    } else if (magnitude < 7.0) {
      return 'Schweres Beben';
    } else {
      return 'Verheerendes Beben';
    }
  }
  
  String _getMagnitudeDescription(double magnitude) {
    if (magnitude < 4.0) {
      return 'Kaum spürbar, meist nur instrumental messbar';
    } else if (magnitude < 5.0) {
      return 'Deutlich spürbar, geringe Schäden möglich';
    } else if (magnitude < 6.0) {
      return 'Schäden an Gebäuden, deutliche Erschütterungen';
    } else if (magnitude < 7.0) {
      return 'Schwere Schäden in bewohnten Gebieten';
    } else {
      return 'Verheerende Zerstörungen, Lebensgefahr';
    }
  }
  
  void _openUSGSLink() async {
    final url = Uri.parse('https://earthquake.usgs.gov/earthquakes/eventpage/${earthquake.id}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
  
  void _openInMaps(BuildContext context) {
    Navigator.pop(context);
    // Zurück zur Karte, zentriert auf dieses Erdbeben
  }
}
