import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';

// Convenience alias for Schumann colors
const Color schumannPrimary = AppTheme.techMysteries; // Cyan
const Color schumannAccent = AppTheme.energyPhenomena; // Gelb

class SchumannResonanceScreen extends StatefulWidget {
  const SchumannResonanceScreen({super.key});

  @override
  State<SchumannResonanceScreen> createState() => _SchumannResonanceScreenState();
}

class _SchumannResonanceScreenState extends State<SchumannResonanceScreen> {
  Timer? _refreshTimer;
  DateTime _lastUpdate = DateTime.now();
  bool _isLoading = false;
  int _imageKey = 0; // Force image reload

  final List<Map<String, String>> _diagramData = [
    {
      'title': 'Schumann Resonanz Hauptdiagramm',
      'url': 'schumann-frequenz',
      'description': 'Aktuelle Schumann-Resonanz mit Frequenz und Amplitude',
    },
    {
      'title': 'Qualitätsfaktoren',
      'url': 'qualitaetsfaktoren-der-schumann-frequenz',
      'description': 'Qualität der Schumann-Resonanz Messung',
    },
    {
      'title': 'Amplituden',
      'url': 'amplituden-der-schumann-frequenz',
      'description': 'Amplitudenverlauf der Schumann-Frequenz',
    },
    {
      'title': 'Frequenzen',
      'url': 'frequenzen-der-schumann-frequenz',
      'description': 'Frequenzspektrum der Schumann-Resonanz',
    },
    {
      'title': 'Elektromagnetischer Hintergrundpegel',
      'url': 'elektromagnetischer-hintergrundpegel-schumann-frequenz',
      'description': 'Hintergrund-Rauschen und Störungen',
    },
    {
      'title': 'Letztes Ionogramm',
      'url': 'letztes-ionogramm-schumann-frequenz',
      'description': 'Ionosphäre Messung (Tomsk)',
    },
    {
      'title': 'Kritische Frequenzen',
      'url': 'kritische-frequenzen-schumann-frequenz',
      'description': 'Kritische Frequenzen der Ionosphäre',
    },
    {
      'title': 'Aktive Höhen',
      'url': 'aktive-hoehen-schumann-frequenz',
      'description': 'Höhe der ionosphärischen Schichten',
    },
    {
      'title': 'Kritische Frequenzen (ohne sporadische Schichten)',
      'url': 'kritische-frequenzen-ohne-sporadische-schichten-07-11-2025-23-30',
      'description': 'Bereinigte kritische Frequenzen',
    },
    {
      'title': 'Magnetfeldkomponenten',
      'url': 'magnetfeldkomponenten-schumann-frequenz',
      'description': 'Erdmagnetfeld X, Y, Z Komponenten',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 60 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        setState(() {
          _lastUpdate = DateTime.now();
          _imageKey++; // Force image reload
        });
      }
    });
  }

  void _manualRefresh() {
    setState(() {
      _isLoading = true;
      _lastUpdate = DateTime.now();
      _imageKey++;
    });

    // Show loading feedback
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diagramme aktualisiert'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  String _buildImageUrl(String urlPart) {
    // Get current timestamp rounded to last 15 minutes
    final now = DateTime.now().toUtc();
    final minutes = (now.minute ~/ 15) * 15;
    final roundedTime = DateTime(now.year, now.month, now.day, now.hour, minutes);
    
    final timestamp = DateFormat('dd-MM-yyyy-HH-mm').format(roundedTime);
    
    return 'https://www.schumann-frequenz-resonanz.de/assets/images/$urlPart-$timestamp.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schumann Resonanz Live'),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _manualRefresh,
            tooltip: 'Aktualisieren',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
            tooltip: 'Informationen',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: schumannPrimary.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: schumannPrimary),
                const SizedBox(width: 8),
                Text(
                  'Letzte Aktualisierung: ${DateFormat('HH:mm:ss').format(_lastUpdate)}',
                  style: const TextStyle(fontSize: 12, color: schumannPrimary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Diagram Grid
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _diagramData.length,
              itemBuilder: (context, index) {
                final diagram = _diagramData[index];
                return _buildDiagramCard(diagram);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagramCard(Map<String, String> diagram) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: schumannPrimary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diagram['title']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: schumannPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  diagram['description']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Image with loading indicator
          GestureDetector(
            onTap: () => _showFullscreenImage(diagram),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 200),
              color: Colors.grey[100],
              child: Image.network(
                _buildImageUrl(diagram['url']!),
                key: ValueKey('${diagram['url']}_$_imageKey'), // Force reload
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(50.0),
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          'Diagramm konnte nicht geladen werden',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bilder werden alle 15 Minuten aktualisiert',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Footer with timestamp info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Auto-Update alle 15 Minuten (Quelle: Tomsk Space Observatory)',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, size: 20),
                  onPressed: () => _showFullscreenImage(diagram),
                  tooltip: 'Vollbild',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullscreenImage(Map<String, String> diagram) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(diagram['title']!),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                _buildImageUrl(diagram['url']!),
                key: ValueKey('fullscreen_${diagram['url']}_$_imageKey'),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Über Schumann Resonanz'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Die Schumann-Resonanz ist das elektromagnetische "Herzschlag-Muster" unserer Erde.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Datenquelle:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Tomsk Space Observing System (Russland)'),
              const Text('• Universität Tomsk, Sibirien'),
              const SizedBox(height: 12),
              const Text(
                'Aktualisierung:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Automatisch alle 15 Minuten'),
              const Text('• Live-Daten von Tomsk'),
              const SizedBox(height: 12),
              const Text(
                'Normale Werte:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Grundfrequenz: 7,83 Hz'),
              const Text('• Spitzen: bis 100+ Hz möglich'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: schumannPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💡 Tipp: Klicken Sie auf ein Diagramm für Vollbildansicht mit Zoom-Funktion',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}
