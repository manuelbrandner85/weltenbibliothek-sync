import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../services/telegram_service.dart';
import '../models/telegram_models.dart';

/// Telegram Videos Screen
/// Zeigt Videos vom Telegram-Kanal mit Kategoriefilterung
class TelegramVideosScreen extends StatefulWidget {
  const TelegramVideosScreen({super.key});

  @override
  State<TelegramVideosScreen> createState() => _TelegramVideosScreenState();
}

class _TelegramVideosScreenState extends State<TelegramVideosScreen> 
    with SingleTickerProviderStateMixin {
  
  final TelegramService _telegramService = TelegramService();
  
  late TabController _tabController;
  String? _selectedCategory;
  
  // Kategorien (müssen mit Firestore übereinstimmen)
  final List<Map<String, String>> _categories = [
    {'id': 'lostCivilizations', 'name': 'Verlorene Zivilisationen', 'icon': '🏛️'},
    {'id': 'alienContact', 'name': 'Alien-Kontakt', 'icon': '👽'},
    {'id': 'ancientTechnology', 'name': 'Antike Technologie', 'icon': '⚙️'},
    {'id': 'mysteriousArtifacts', 'name': 'Mysteriöse Artefakte', 'icon': '💎'},
    {'id': 'paranormalPhenomena', 'name': 'Paranormale Phänomene', 'icon': '👻'},
    {'id': 'secretSocieties', 'name': 'Geheimgesellschaften', 'icon': '🔺'},
    {'id': 'dimensionalAnomalies', 'name': 'Dimensionale Anomalien', 'icon': '🌀'},
    {'id': 'techMysteries', 'name': 'Tech-Mysterien', 'icon': '⚡'},
    {'id': 'cosmicEvents', 'name': 'Kosmische Ereignisse', 'icon': '🪐'},
    {'id': 'hiddenKnowledge', 'name': 'Verborgenes Wissen', 'icon': '📚'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categories.length + 1, // +1 für "Alle"
      vsync: this,
    );
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 0) {
            _selectedCategory = null; // Alle
          } else {
            _selectedCategory = _categories[_tabController.index - 1]['id'];
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.smart_display, color: AppTheme.secondaryGold, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Telegram Videos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.secondaryGold,
          labelColor: AppTheme.secondaryGold,
          unselectedLabelColor: Colors.grey,
          tabs: [
            const Tab(text: 'Alle'),
            ..._categories.map((cat) => Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat['icon']!),
                  const SizedBox(width: 4),
                  Text(cat['name']!),
                ],
              ),
            )),
          ],
        ),
      ),
      body: Column(
        children: [
          // Telegram Channel Info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryPurple.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.send,
                    color: AppTheme.secondaryGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Videos aus dem Telegram-Kanal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@ArchivWeltenBibliothek',
                        style: TextStyle(
                          color: AppTheme.secondaryGold.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _openTelegramChannel(),
                  child: const Text(
                    'Kanal öffnen',
                    style: TextStyle(color: AppTheme.secondaryGold),
                  ),
                ),
              ],
            ),
          ),
          
          // Videos Grid
          Expanded(
            child: StreamBuilder<List<TelegramVideo>>(
              stream: _telegramService.getVideosByCategory(_selectedCategory!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.secondaryGold,
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }
                
                final videos = snapshot.data ?? [];
                
                if (videos.isEmpty) {
                  return _buildEmptyState();
                }
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    return _buildVideoCard(videos[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(TelegramVideo video) {
    return GestureDetector(
      onTap: () => _openVideo(video),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                height: 120,
                width: double.infinity,
                color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                child: video.thumbnailUrl != null
                    ? Image.network(
                        video.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildThumbnailPlaceholder(video);
                        },
                      )
                    : _buildThumbnailPlaceholder(video),
              ),
            ),
            
            // Video Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // Stats
                    Row(
                      children: [
                        Icon(
                          Icons.remove_red_eye,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatViews(video.viewCount),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(video.duration),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(TelegramVideo video) {
    // Emoji für Kategorie
    final categoryEmoji = _categories.firstWhere(
      (cat) => cat['id'] == video.category,
      orElse: () => {'icon': '📹'},
    )['icon']!;
    
    return Container(
      color: AppTheme.primaryPurple.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          categoryEmoji,
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 24),
          Text(
            'Noch keine Videos verfügbar',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Videos werden automatisch aus dem\nTelegram-Kanal synchronisiert',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'Fehler beim Laden der Videos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== HELPERS ==========

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _openVideo(TelegramVideo video) async {
    try {
      debugPrint('📹 Öffne Video: ${video.title}');
      debugPrint('🔗 URL: ${video.videoUrl}');
      
      // Erhöhe View-Counter
      await _telegramService.incrementViewCount(video.id);
      
      // Öffne Video in Telegram
      final uri = Uri.parse(video.videoUrl ?? '');
      
      debugPrint('🔍 Prüfe URL-Launcher...');
      final canLaunch = await canLaunchUrl(uri);
      debugPrint('🔍 canLaunchUrl: $canLaunch');
      
      if (canLaunch) {
        debugPrint('🚀 Starte URL-Launcher...');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('✅ Video geöffnet');
      } else {
        debugPrint('❌ canLaunchUrl = false');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video konnte nicht geöffnet werden\nURL: ${video.videoUrl}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Kanal öffnen',
                textColor: Colors.white,
                onPressed: _openTelegramChannel,
              ),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Fehler beim Öffnen: $e');
      debugPrint('Stack: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e\n\nBitte Telegram-App installieren'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Kanal öffnen',
              textColor: Colors.white,
              onPressed: _openTelegramChannel,
            ),
          ),
        );
      }
    }
  }

  Future<void> _openTelegramChannel() async {
    try {
      final uri = Uri.parse('https://t.me/ArchivWeltenBibliothek');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
