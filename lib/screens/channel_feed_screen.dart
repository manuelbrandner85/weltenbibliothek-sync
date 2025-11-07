import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../config/app_theme.dart';
import '../services/telegram_channel_loader.dart';
import '../models/channel_content.dart';
import '../widgets/glass_card.dart';

/// Channel Feed Screen - Zeigt automatisch geladene Inhalte
class ChannelFeedScreen extends StatefulWidget {
  const ChannelFeedScreen({super.key});

  @override
  State<ChannelFeedScreen> createState() => _ChannelFeedScreenState();
}

class _ChannelFeedScreenState extends State<ChannelFeedScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TelegramChannelLoader _loader = TelegramChannelLoader();
  
  String? _selectedCategory;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    final categories = TelegramChannelLoader.categories;
    _tabController = TabController(
      length: categories.length + 1, // +1 für "Alle"
      vsync: this,
    );
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 0) {
            _selectedCategory = null;
          } else {
            _selectedCategory = categories.keys.elementAt(_tabController.index - 1);
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
  
  Future<void> _refreshContent() async {
    setState(() => _isLoading = true);
    await _loader.loadChannelContent();
    setState(() => _isLoading = false);
  }
  
  @override
  Widget build(BuildContext context) {
    final categories = TelegramChannelLoader.categories;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Kategorie-Tabs
            _buildCategoryTabs(categories),
            
            // Content Feed
            Expanded(
              child: _buildContentFeed(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshContent,
        backgroundColor: AppTheme.primaryPurple,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.refresh),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceDark,
            AppTheme.primaryPurple.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.secondaryGold.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.library_books,
              color: AppTheme.secondaryGold,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Channel Feed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryGold,
                  ),
                ),
                Text(
                  'Automatisch kategorisiert',
                  style: TextStyle(
                    fontSize: 13,
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
      .slideY(begin: -0.2, end: 0);
  }
  
  Widget _buildCategoryTabs(Map<String, CategoryConfig> categories) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.secondaryGold,
        labelColor: AppTheme.secondaryGold,
        unselectedLabelColor: AppTheme.textWhite.withValues(alpha: 0.6),
        indicatorWeight: 3,
        tabs: [
          const Tab(
            child: Row(
              children: [
                Text('🌟', style: TextStyle(fontSize: 18)),
                SizedBox(width: 6),
                Text('Alle'),
              ],
            ),
          ),
          ...categories.entries.map((entry) {
            final config = entry.value;
            return Tab(
              child: Row(
                children: [
                  Text(config.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(config.name),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildContentFeed() {
    return StreamBuilder<List<ChannelContent>>(
      stream: _selectedCategory == null
          ? _loader.getAllContent()
          : _loader.getContentByCategory(_selectedCategory!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.secondaryGold),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'Fehler beim Laden',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textWhite.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textWhite.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final contents = snapshot.data ?? [];
        
        if (contents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inbox,
                  size: 64,
                  color: AppTheme.textGrey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine Inhalte gefunden',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textWhite.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ziehe nach unten zum Aktualisieren',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textWhite.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: _refreshContent,
          color: AppTheme.secondaryGold,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contents.length,
            itemBuilder: (context, index) {
              return _buildContentCard(contents[index], index);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildContentCard(ChannelContent content, int index) {
    final categoryConfig = TelegramChannelLoader.getCategoryConfig(content.category);
    final categoryColor = _getCategoryColor(content.category);
    
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      blur: 15,
      opacity: 0.1,
      border: Border.all(
        color: categoryColor.withValues(alpha: 0.4),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: categoryColor.withValues(alpha: 0.2),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Kategorie
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      categoryConfig?.icon ?? '📝',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      categoryConfig?.name ?? 'Allgemein',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(content.date),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textWhite.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Medien (wenn vorhanden)
          if (content.hasMedia) ...[
            _buildMedia(content),
            const SizedBox(height: 12),
          ],
          
          // Text
          if (content.text.isNotEmpty) ...[
            Text(
              content.text,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textWhite.withValues(alpha: 0.9),
                height: 1.5,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          
          // Footer mit Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Content-Typ Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getContentTypeIcon(content.contentType),
                      size: 14,
                      color: categoryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getContentTypeName(content.contentType),
                      style: TextStyle(
                        fontSize: 11,
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (content.formattedDuration != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        content.formattedDuration!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textWhite.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Telegram Link Button
              TextButton.icon(
                onPressed: () => _openTelegramLink(content.telegramLink),
                icon: const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: AppTheme.secondaryGold,
                ),
                label: const Text(
                  'Im Channel öffnen',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.secondaryGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 100).ms)
      .fadeIn(duration: 400.ms)
      .slideX(begin: -0.2, end: 0);
  }
  
  Widget _buildMedia(ChannelContent content) {
    if (content.isVideo) {
      return _buildVideoPreview(content);
    } else if (content.isPhoto) {
      return _buildPhotoPreview(content);
    } else if (content.contentType == ContentType.document) {
      return _buildDocumentPreview(content);
    }
    return const SizedBox.shrink();
  }
  
  Widget _buildVideoPreview(ChannelContent content) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Thumbnail
          if (content.thumbnailUrl != null)
            Image.network(
              content.thumbnailUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: AppTheme.surfaceDark,
                  child: const Icon(
                    Icons.videocam,
                    size: 64,
                    color: AppTheme.textGrey,
                  ),
                );
              },
            )
          else
            Container(
              height: 200,
              color: AppTheme.surfaceDark,
              child: const Icon(
                Icons.videocam,
                size: 64,
                color: AppTheme.textGrey,
              ),
            ),
          
          // Play Button Overlay
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // Duration Badge
          if (content.formattedDuration != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  content.formattedDuration!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPhotoPreview(ChannelContent content) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        content.mediaUrl!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: AppTheme.surfaceDark,
            child: const Icon(
              Icons.image,
              size: 64,
              color: AppTheme.textGrey,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDocumentPreview(ChannelContent content) {
    return Container(
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
          const Icon(
            Icons.description,
            size: 40,
            color: AppTheme.primaryPurple,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dokument',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
                if (content.formattedFileSize != null)
                  Text(
                    content.formattedFileSize!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textWhite.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'lostCivilizations':
        return AppTheme.lostCivilizations;
      case 'alienTheories':
        return AppTheme.alienContact;
      case 'ancientTechnology':
        return AppTheme.techMysteries;
      case 'esoterik':
        return AppTheme.occultEvents;
      case 'conspiracies':
        return AppTheme.globalConspiracies;
      case 'archaeology':
        return AppTheme.lostCivilizations;
      case 'mysticism':
        return AppTheme.occultEvents;
      case 'cosmos':
        return AppTheme.dimensionalAnomalies;
      case 'forbidden':
        return AppTheme.forbiddenKnowledge;
      case 'paranormal':
        return AppTheme.dimensionalAnomalies;
      default:
        return AppTheme.primaryPurple;
    }
  }
  
  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.video:
        return Icons.videocam;
      case ContentType.photo:
        return Icons.image;
      case ContentType.document:
        return Icons.description;
      case ContentType.audio:
        return Icons.audiotrack;
      case ContentType.voice:
        return Icons.mic;
      default:
        return Icons.text_fields;
    }
  }
  
  String _getContentTypeName(ContentType type) {
    switch (type) {
      case ContentType.video:
        return 'Video';
      case ContentType.photo:
        return 'Foto';
      case ContentType.document:
        return 'Dokument';
      case ContentType.audio:
        return 'Audio';
      case ContentType.voice:
        return 'Sprachnachricht';
      default:
        return 'Text';
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes} Min';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours} Std';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays} Tag${difference.inDays > 1 ? 'en' : ''}';
    } else {
      return DateFormat('dd.MM.yyyy').format(date);
    }
  }
  
  Future<void> _openTelegramLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
