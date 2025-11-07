import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_theme.dart';
import '../services/telegram_channel_loader.dart';
import '../models/channel_content.dart';
import '../widgets/glass_card.dart';

/// Analytics Dashboard für Content-Statistiken
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('📊 Content Analytics'),
        backgroundColor: AppTheme.surfaceDark,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('channel_content').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryGold),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Keine Daten verfügbar'),
            );
          }
          
          final contents = snapshot.data!.docs
              .map((doc) => ChannelContent.fromFirestore(doc.data() as Map<String, dynamic>))
              .toList();
          
          return _buildDashboard(contents);
        },
      ),
    );
  }
  
  Widget _buildDashboard(List<ChannelContent> contents) {
    final stats = _calculateStats(contents);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Cards
          _buildOverviewCards(stats),
          
          const SizedBox(height: 24),
          
          // Category Distribution Chart
          _buildCategoryChart(stats),
          
          const SizedBox(height: 24),
          
          // Content Type Chart
          _buildContentTypeChart(stats),
          
          const SizedBox(height: 24),
          
          // Timeline Chart
          _buildTimelineChart(contents),
        ],
      ),
    );
  }
  
  Widget _buildOverviewCards(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '📝',
            'Gesamt',
            stats['total'].toString(),
            AppTheme.primaryPurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '🎬',
            'Videos',
            stats['videos'].toString(),
            AppTheme.errorRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '📸',
            'Fotos',
            stats['photos'].toString(),
            AppTheme.alienContact,
          ),
        ),
      ],
    ).animate()
      .fadeIn(duration: 400.ms);
  }
  
  Widget _buildStatCard(String emoji, String label, String value, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      opacity: 0.1,
      border: Border.all(
        color: color.withValues(alpha: 0.3),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textWhite.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryChart(Map<String, dynamic> stats) {
    final categoryData = stats['categories'] as Map<String, int>;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nach Kategorie',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryGold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _buildPieSections(categoryData),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._buildCategoryLegend(categoryData),
        ],
      ),
    ).animate()
      .fadeIn(delay: 200.ms, duration: 400.ms);
  }
  
  Widget _buildContentTypeChart(Map<String, dynamic> stats) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content-Typen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryGold,
            ),
          ),
          const SizedBox(height: 20),
          _buildTypeBar('Videos', stats['videos'], stats['total'], Colors.red),
          _buildTypeBar('Fotos', stats['photos'], stats['total'], Colors.green),
          _buildTypeBar('Text', stats['texts'], stats['total'], Colors.blue),
        ],
      ),
    ).animate()
      .fadeIn(delay: 400.ms, duration: 400.ms);
  }
  
  Widget _buildTypeBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.textWhite),
              ),
              Text(
                '$count (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: AppTheme.textWhite.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppTheme.surfaceDark,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimelineChart(List<ChannelContent> contents) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      opacity: 0.1,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zeitverlauf',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryGold,
            ),
          ),
          SizedBox(height: 80),
          Center(
            child: Text(
              '📈 Kommend: Timeline-Chart',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 600.ms, duration: 400.ms);
  }
  
  List<PieChartSectionData> _buildPieSections(Map<String, int> data) {
    final colors = [
      AppTheme.lostCivilizations,
      AppTheme.alienContact,
      AppTheme.techMysteries,
      AppTheme.occultEvents,
      AppTheme.globalConspiracies,
    ];
    
    int colorIndex = 0;
    return data.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: entry.value.toString(),
        color: color,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
  
  List<Widget> _buildCategoryLegend(Map<String, int> data) {
    return data.entries.map((entry) {
      final config = TelegramChannelLoader.getCategoryConfig(entry.key);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(config?.icon ?? '📝', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                config?.name ?? entry.key,
                style: const TextStyle(color: AppTheme.textWhite),
              ),
            ),
            Text(
              '${entry.value}',
              style: TextStyle(
                color: AppTheme.textWhite.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
  
  Map<String, dynamic> _calculateStats(List<ChannelContent> contents) {
    final Map<String, int> categories = {};
    int videos = 0;
    int photos = 0;
    int texts = 0;
    
    for (final content in contents) {
      // Count by category
      categories[content.category] = (categories[content.category] ?? 0) + 1;
      
      // Count by type
      switch (content.contentType) {
        case ContentType.video:
          videos++;
          break;
        case ContentType.photo:
          photos++;
          break;
        case ContentType.text:
          texts++;
          break;
        default:
          break;
      }
    }
    
    return {
      'total': contents.length,
      'videos': videos,
      'photos': photos,
      'texts': texts,
      'categories': categories,
    };
  }
}
