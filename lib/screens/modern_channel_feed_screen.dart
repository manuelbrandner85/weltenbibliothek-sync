// 📰 WELTENBIBLIOTHEK - MODERNE CHANNEL FEED SCREEN
// Komplett neugestaltete Feed-Ansicht mit modernem UX Design

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../config/modern_design_system.dart';
import '../providers/theme_provider.dart';
import '../services/telegram_channel_loader.dart';
import '../models/channel_content.dart';

class ModernChannelFeedScreen extends StatefulWidget {
  const ModernChannelFeedScreen({super.key});

  @override
  State<ModernChannelFeedScreen> createState() => _ModernChannelFeedScreenState();
}

class _ModernChannelFeedScreenState extends State<ModernChannelFeedScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TelegramChannelLoader _loader = TelegramChannelLoader();
  
  String? _selectedCategory;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  
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
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _refreshContent() async {
    setState(() => _isLoading = true);
    await _loader.loadChannelContent();
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Inhalte aktualisiert'),
          backgroundColor: ModernColors.emeraldGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernRadius.md),
          ),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final categories = TelegramChannelLoader.categories;
    
    return Scaffold(
      backgroundColor: isDark ? ModernColors.darkBackground : ModernColors.lightBackground,
      body: SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // === HEADER ===
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: false,
              elevation: 0,
              backgroundColor: isDark ? ModernColors.darkSurface : ModernColors.lightSurface,
              expandedHeight: 140,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(isDark),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: _buildCategoryTabs(categories, isDark),
              ),
            ),
          ],
          body: _buildContentFeed(isDark),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // === HEADER ===
  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: ModernGradients.primaryGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(ModernSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ModernSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(ModernRadius.sm),
                  ),
                  child: const Icon(
                    Icons.library_books,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: ModernSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Channel Feed',
                        style: ModernTypography.h3.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Automatisch kategorisiert',
                        style: ModernTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideY(begin: -0.2, end: 0);
  }

  // === KATEGORIE TABS ===
  Widget _buildCategoryTabs(Map<String, CategoryConfig> categories, bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: ModernSpacing.sm),
      color: isDark ? ModernColors.darkSurface : ModernColors.lightSurface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: ModernColors.goldenHoney,
        labelColor: ModernColors.goldenHoney,
        unselectedLabelColor: isDark ? ModernColors.textGrey : ModernColors.textMedium,
        indicatorWeight: 3,
        labelStyle: ModernTypography.button,
        unselectedLabelStyle: ModernTypography.bodyMedium,
        tabs: [
          _buildTab('🌟', 'Alle'),
          ...categories.entries.map((entry) {
            final config = entry.value;
            return _buildTab(config.icon, config.name);
          }),
        ],
      ),
    );
  }

  Widget _buildTab(String emoji, String label) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ModernSpacing.md,
          vertical: ModernSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: ModernSpacing.sm),
            Text(label),
          ],
        ),
      ),
    );
  }

  // === CONTENT FEED ===
  Widget _buildContentFeed(bool isDark) {
    return StreamBuilder<List<ChannelContent>>(
      stream: _selectedCategory == null
          ? _loader.getAllContent()
          : _loader.getContentByCategory(_selectedCategory!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: ModernColors.deepPurple,
                  strokeWidth: 3,
                ),
                const SizedBox(height: ModernSpacing.md),
                Text(
                  'Lade Inhalte...',
                  style: ModernTypography.bodyMedium.copyWith(
                    color: isDark ? ModernColors.textGrey : ModernColors.textMedium,
                  ),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), isDark);
        }
        
        final contents = snapshot.data ?? [];
        
        if (contents.isEmpty) {
          return _buildEmptyState(isDark);
        }
        
        return RefreshIndicator(
          onRefresh: _refreshContent,
          color: ModernColors.deepPurple,
          backgroundColor: isDark ? ModernColors.darkSurface : ModernColors.lightSurface,
          child: ListView.builder(
            padding: const EdgeInsets.all(ModernSpacing.md),
            itemCount: contents.length,
            itemBuilder: (context, index) {
              return _buildContentCard(contents[index], isDark, index);
            },
          ),
        );
      },
    );
  }

  // === CONTENT CARD ===
  Widget _buildContentCard(ChannelContent content, bool isDark, int index) {
    final categoryConfig = TelegramChannelLoader.getCategoryConfig(content.category);
    final categoryColor = _getCategoryColor(content.category);
    
    return ModernGlassCard(
      margin: const EdgeInsets.only(bottom: ModernSpacing.md),
      padding: const EdgeInsets.all(ModernSpacing.md),
      borderRadius: ModernRadius.xl,
      blur: 15,
      opacity: isDark ? 0.1 : 0.05,
      border: Border.all(
        color: categoryColor.withValues(alpha: 0.4),
        width: 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === HEADER ===
          Row(
            children: [
              // Category Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ModernSpacing.md,
                  vertical: ModernSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: ModernGradients.glassGradient(categoryColor),
                  borderRadius: BorderRadius.circular(ModernRadius.md),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      categoryConfig?.icon ?? '📝',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: ModernSpacing.sm),
                    Text(
                      categoryConfig?.name ?? 'Allgemein',
                      style: ModernTypography.caption.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              
              // Date
              Text(
                _formatDate(content.date),
                style: ModernTypography.caption.copyWith(
                  color: isDark ? ModernColors.textGrey : ModernColors.textMedium,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: ModernSpacing.md),
          
          // === MEDIA ===
          if (content.hasMedia) ...[
            _buildMedia(content, categoryColor),
            const SizedBox(height: ModernSpacing.md),
          ],
          
          // === TEXT CONTENT ===
          if (content.text.isNotEmpty) ...[
            Text(
              content.text,
              style: ModernTypography.bodyMedium.copyWith(
                color: isDark ? ModernColors.textWhite : ModernColors.textDark,
                height: 1.6,
              ),
              maxLines: content.hasMedia ? 3 : 8,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: ModernSpacing.md),
          ],
          
          // === FOOTER ===
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Content Type Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ModernSpacing.sm,
                  vertical: ModernSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isDark ? ModernColors.darkSurfaceLight : ModernColors.lightSurfaceDark,
                  borderRadius: BorderRadius.circular(ModernRadius.sm),
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
                    const SizedBox(width: ModernSpacing.xs),
                    Text(
                      _getContentTypeName(content.contentType),
                      style: ModernTypography.caption.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (content.formattedDuration != null) ...[
                      const SizedBox(width: ModernSpacing.xs),
                      Text(
                        content.formattedDuration!,
                        style: ModernTypography.caption.copyWith(
                          color: isDark ? ModernColors.textGrey : ModernColors.textMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Telegram Link Button
              TextButton.icon(
                onPressed: () => _openTelegramLink(content.telegramLink),
                icon: Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: categoryColor,
                ),
                label: Text(
                  'Im Channel öffnen',
                  style: ModernTypography.caption.copyWith(
                    color: categoryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ModernSpacing.sm,
                    vertical: ModernSpacing.xs,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ModernRadius.sm),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 50).ms)
      .fadeIn(duration: 400.ms)
      .slideX(begin: -0.1, end: 0);
  }

  // === MEDIA PREVIEW ===
  Widget _buildMedia(ChannelContent content, Color categoryColor) {
    if (content.isVideo) {
      return _buildVideoPreview(content, categoryColor);
    } else if (content.isPhoto) {
      return _buildPhotoPreview(content);
    } else if (content.contentType == ContentType.document) {
      return _buildDocumentPreview(content, categoryColor);
    }
    return const SizedBox.shrink();
  }

  Widget _buildVideoPreview(ChannelContent content, Color categoryColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ModernRadius.md),
      child: Stack(
        children: [
          // Thumbnail
          if (content.thumbnailUrl != null)
            Image.network(
              content.thumbnailUrl!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildMediaPlaceholder(Icons.videocam, categoryColor);
              },
            )
          else
            _buildMediaPlaceholder(Icons.videocam, categoryColor),
          
          // Play Button Overlay
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(ModernSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  boxShadow: ModernShadows.glow(categoryColor),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // Duration Badge
          if (content.formattedDuration != null)
            Positioned(
              bottom: ModernSpacing.sm,
              right: ModernSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ModernSpacing.sm,
                  vertical: ModernSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(ModernRadius.sm),
                ),
                child: Text(
                  content.formattedDuration!,
                  style: ModernTypography.caption.copyWith(
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
      borderRadius: BorderRadius.circular(ModernRadius.md),
      child: Image.network(
        content.mediaUrl!,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildMediaPlaceholder(Icons.image, ModernColors.deepPurple);
        },
      ),
    );
  }

  Widget _buildDocumentPreview(ChannelContent content, Color categoryColor) {
    return Container(
      padding: const EdgeInsets.all(ModernSpacing.md),
      decoration: BoxDecoration(
        gradient: ModernGradients.glassGradient(categoryColor),
        borderRadius: BorderRadius.circular(ModernRadius.md),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description,
            size: 40,
            color: categoryColor,
          ),
          const SizedBox(width: ModernSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dokument',
                  style: ModernTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                ),
                if (content.formattedFileSize != null)
                  Text(
                    content.formattedFileSize!,
                    style: ModernTypography.caption.copyWith(
                      color: categoryColor.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPlaceholder(IconData icon, Color color) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: ModernGradients.glassGradient(color),
        borderRadius: BorderRadius.circular(ModernRadius.md),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 64,
          color: color.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  // === EMPTY STATE ===
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 80,
            color: isDark ? ModernColors.textGrey : ModernColors.textMedium,
          ),
          const SizedBox(height: ModernSpacing.lg),
          Text(
            'Keine Inhalte gefunden',
            style: ModernTypography.h4.copyWith(
              color: isDark ? ModernColors.textWhite : ModernColors.textDark,
            ),
          ),
          const SizedBox(height: ModernSpacing.sm),
          Text(
            'Ziehe nach unten zum Aktualisieren',
            style: ModernTypography.bodyMedium.copyWith(
              color: isDark ? ModernColors.textGrey : ModernColors.textMedium,
            ),
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }

  // === ERROR STATE ===
  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: ModernColors.crimsonRed,
          ),
          const SizedBox(height: ModernSpacing.lg),
          Text(
            'Fehler beim Laden',
            style: ModernTypography.h4.copyWith(
              color: isDark ? ModernColors.textWhite : ModernColors.textDark,
            ),
          ),
          const SizedBox(height: ModernSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ModernSpacing.xl),
            child: Text(
              error,
              style: ModernTypography.bodySmall.copyWith(
                color: isDark ? ModernColors.textGrey : ModernColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: ModernSpacing.lg),
          ModernButton(
            text: 'Erneut versuchen',
            icon: Icons.refresh,
            onPressed: _refreshContent,
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }

  // === FLOATING ACTION BUTTON ===
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _refreshContent,
      backgroundColor: ModernColors.deepPurple,
      elevation: 8,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.refresh),
      label: Text(
        'Aktualisieren',
        style: ModernTypography.button.copyWith(color: Colors.white),
      ),
    ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.8, 0.8));
  }

  // === HELPER METHODS ===
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'lostCivilizations':
        return ModernColors.categoryLostCiv;
      case 'alienTheories':
        return ModernColors.categoryUFO;
      case 'ancientTechnology':
        return ModernColors.categoryTesla;
      case 'esoterik':
        return ModernColors.categoryOccult;
      case 'conspiracies':
        return ModernColors.categoryIlluminati;
      case 'archaeology':
        return ModernColors.categoryArchaeology;
      case 'mysticism':
        return ModernColors.categoryMatrix;
      case 'cosmos':
        return ModernColors.categoryCosmos;
      case 'forbidden':
        return ModernColors.categoryMedicine;
      case 'paranormal':
        return ModernColors.categoryHollowEarth;
      default:
        return ModernColors.deepPurple;
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
      return '${date.day}.${date.month}.${date.year}';
    }
  }
  
  Future<void> _openTelegramLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
