import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../data/massive_events_data.dart';
import '../models/historical_event.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Map<String, dynamic> _stats;
  late List<HistoricalEvent> _allEvents;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    _stats = MassiveEventsData.getStatistics();
    _allEvents = MassiveEventsData.getAllEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('📊 Statistiken'),
        backgroundColor: AppTheme.surfaceDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gesamt-Übersicht
            _buildOverviewCard(),
            const SizedBox(height: 16),
            
            // Kategorien-Verteilung
            _buildCategoriesCard(),
            const SizedBox(height: 16),
            
            // Zeitraum-Statistik
            _buildTimelineCard(),
            const SizedBox(height: 16),
            
            // Trust Level Verteilung
            _buildTrustLevelCard(),
            const SizedBox(height: 16),
            
            // Top Events
            _buildTopEventsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      color: AppTheme.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryPurple),
                const SizedBox(width: 8),
                Text(
                  'Gesamt-Übersicht',
                  style: AppTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('🔮 Gesamte Events', '${_stats['total_events']}'),
            _buildStatRow('📅 Zeitspanne', '${_stats['timespan_years']} Jahre'),
            _buildStatRow('🏛️ Ältestes Event', _formatYear(_stats['earliest_event'].year)),
            _buildStatRow('🆕 Neuestes Event', _formatYear(_stats['latest_event'].year)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildCategoriesCard() {
    final categories = _stats['categories'] as Map<String, dynamic>;
    
    return Card(
      color: AppTheme.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: AppTheme.accentGold),
                const SizedBox(width: 8),
                Text(
                  'Kategorien-Verteilung',
                  style: AppTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...categories.entries.map((entry) {
              final icon = _getCategoryIcon(entry.key);
              final name = _getCategoryName(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(name, style: AppTheme.bodyLarge),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.bold,
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
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTimelineCard() {
    // Berechne Events pro Jahrhundert
    final centuryGroups = <int, int>{};
    for (var event in _allEvents) {
      final century = (event.date.year / 100).floor() * 100;
      centuryGroups[century] = (centuryGroups[century] ?? 0) + 1;
    }
    
    final sortedCenturies = centuryGroups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      color: AppTheme.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: AppTheme.primaryPurple),
                const SizedBox(width: 8),
                Text(
                  'Top 5 Zeiträume',
                  style: AppTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedCenturies.take(5).map((entry) {
              final century = entry.key;
              final count = entry.value;
              final centuryName = century < 0 
                ? '${-century} v.Chr.'
                : '${century}er';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(centuryName, style: AppTheme.bodyLarge),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count Events',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.bold,
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
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTrustLevelCard() {
    final trustGroups = <int, int>{};
    for (var event in _allEvents) {
      trustGroups[event.trustLevel] = (trustGroups[event.trustLevel] ?? 0) + 1;
    }
    
    return Card(
      color: AppTheme.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: AppTheme.accentGold),
                const SizedBox(width: 8),
                Text(
                  'Vertrauens-Level',
                  style: AppTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...[5, 4, 3, 2, 1].map((level) {
              final count = trustGroups[level] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ...List.generate(level, (_) => Icon(Icons.star, color: AppTheme.accentGold, size: 16)),
                    ...List.generate(5 - level, (_) => const Icon(Icons.star_border, color: Colors.grey, size: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Level $level', style: AppTheme.bodyLarge),
                    ),
                    Text('$count', style: AppTheme.bodyLarge.copyWith(color: AppTheme.accentGold)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTopEventsCard() {
    final topEvents = _allEvents.take(5).toList();
    
    return Card(
      color: AppTheme.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: AppTheme.primaryPurple),
                const SizedBox(width: 8),
                Text(
                  'Älteste 5 Events',
                  style: AppTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topEvents.map((event) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatYear(event.date.year),
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.accentGold),
                        ),
                        const SizedBox(width: 8),
                        Text('•', style: AppTheme.bodySmall),
                        const SizedBox(width: 8),
                        Text(
                          event.locationName ?? 'Unbekannt',
                          style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyLarge),
          Text(
            value,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.accentGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatYear(int year) {
    if (year < 0) {
      return '${-year} v.Chr.';
    }
    return '$year n.Chr.';
  }

  String _getCategoryIcon(String key) {
    switch (key) {
      case 'lost_civilizations': return '🏛️';
      case 'alien_contact': return '👽';
      case 'secret_societies': return '🔺';
      case 'tech_mysteries': return '⚙️';
      case 'dimensional_anomalies': return '🌀';
      case 'occult_events': return '🐐';
      case 'forbidden_knowledge': return '📖';
      case 'ufo_fleets': return '🛸';
      case 'energy_phenomena': return '⚡';
      case 'global_conspiracies': return '👁️';
      default: return '❓';
    }
  }

  String _getCategoryName(String key) {
    switch (key) {
      case 'lost_civilizations': return 'Versunkene Zivilisationen';
      case 'alien_contact': return 'Alien-Kontakte';
      case 'secret_societies': return 'Geheimbünde';
      case 'tech_mysteries': return 'Tech-Mysterien';
      case 'dimensional_anomalies': return 'Dimensionale Anomalien';
      case 'occult_events': return 'Okkulte Ereignisse';
      case 'forbidden_knowledge': return 'Verbotenes Wissen';
      case 'ufo_fleets': return 'UFO-Flotten';
      case 'energy_phenomena': return 'Energie-Phänomene';
      case 'global_conspiracies': return 'Globale Verschwörungen';
      default: return key;
    }
  }
}
