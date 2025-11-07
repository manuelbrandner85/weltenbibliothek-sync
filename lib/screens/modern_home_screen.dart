// 🏠 WELTENBIBLIOTHEK - MODERNE HOME SCREEN
// Komplett neugestaltete Hauptseite mit modernem Design

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../config/modern_design_system.dart';
import '../providers/theme_provider.dart';
import '../services/telegram_channel_loader.dart';
import '../models/channel_content.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> {
  final TelegramChannelLoader _loader = TelegramChannelLoader();
  int _totalPosts = 0;
  int _categoriesCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  Future<void> _loadStats() async {
    // Lade Statistiken
    final allContent = await _loader.getAllContent().first;
    if (mounted) {
      setState(() {
        _totalPosts = allContent.length;
        _categoriesCount = TelegramChannelLoader.categories.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? ModernColors.darkBackground : ModernColors.lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // === HEADER ===
            _buildHeader(isDark),
            
            // === CONTENT ===
            SliverPadding(
              padding: const EdgeInsets.all(ModernSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Statistik Cards
                  _buildStatsSection(isDark),
                  const SizedBox(height: ModernSpacing.lg),
                  
                  // Kategorien Übersicht
                  _buildCategoriesSection(isDark),
                  const SizedBox(height: ModernSpacing.lg),
                  
                  // Neueste Posts
                  _buildLatestPostsSection(isDark),
                  const SizedBox(height: ModernSpacing.lg),
                  
                  // Quick Actions
                  _buildQuickActionsSection(isDark),
                  const SizedBox(height: ModernSpacing.xl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === HEADER ===
  Widget _buildHeader(bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? ModernColors.darkSurface : ModernColors.lightSurface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: ModernGradients.auroraGradient, // 🌟 NEU: Aurora-Effekt
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(ModernSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // App Logo
                  Container(
                    padding: const EdgeInsets.all(ModernSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(ModernRadius.md),
                    ),
                    child: const Text('📚', style: TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(height: ModernSpacing.md),
                  
                  // Titel
                  Text(
                    'Weltenbibliothek',
                    style: ModernTypography.h1.copyWith(
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
                  
                  const SizedBox(height: ModernSpacing.xs),
                  
                  // Untertitel
                  Text(
                    'Chroniken der verborgenen Pfade',
                    style: ModernTypography.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.2, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // === STATISTIK CARDS ===
  Widget _buildStatsSection(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.library_books,
            label: 'Posts',
            value: _totalPosts.toString(),
            color: ModernColors.deepPurple,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: ModernSpacing.md),
        Expanded(
          child: _buildStatCard(
            icon: Icons.category,
            label: 'Kategorien',
            value: _categoriesCount.toString(),
            color: ModernColors.goldenHoney,
            isDark: isDark,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return ModernGlassCard(
      padding: const EdgeInsets.all(ModernSpacing.md),
      borderRadius: ModernRadius.lg,
      blur: 15,
      opacity: isDark ? 0.1 : 0.05,
      border: Border.all(
        color: color.withValues(alpha: 0.3),
        width: 2,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(ModernSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(ModernRadius.sm),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: ModernSpacing.sm),
          Text(
            value,
            style: ModernTypography.h2.copyWith(
              color: isDark ? ModernColors.textWhite : ModernColors.textDark,
            ),
          ),
          Text(
            label,
            style: ModernTypography.bodySmall.copyWith(
              color: isDark ? ModernColors.textGrey : ModernColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  // === KATEGORIEN ÜBERSICHT ===
  Widget _buildCategoriesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ModernSpacing.sm),
          child: Text(
            'KATEGORIEN',
            style: ModernTypography.overline.copyWith(
              color: isDark ? ModernColors.textGrey : ModernColors.textMedium,
            ),
          ),
        ),
        const SizedBox(height: ModernSpacing.md),
        
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ModernSpacing.sm),
            itemCount: TelegramChannelLoader.categories.length,
            itemBuilder: (context, index) {
              final entry = TelegramChannelLoader.categories.entries.elementAt(index);
              final config = entry.value;
              
              return Padding(
                padding: const EdgeInsets.only(right: ModernSpacing.md),
                child: _buildCategoryCard(
                  icon: config.icon,
                  name: config.name,
                  categoryKey: entry.key,
                  isDark: isDark,
                  index: index,
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildCategoryCard({
    required String icon,
    required String name,
    required String categoryKey,
    required bool isDark,
    required int index,
  }) {
    final color = _getCategoryColor(categoryKey);
    
    return GestureDetector(
      onTap: () {
        // Navigate to Channel Feed with selected category
        // TODO: Implement navigation
      },
      child: ModernGlassCard(
        padding: const EdgeInsets.all(ModernSpacing.md),
        borderRadius: ModernRadius.lg,
        blur: 10,
        opacity: isDark ? 0.1 : 0.05,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        child: SizedBox(
          width: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: ModernSpacing.sm),
              Text(
                name,
                style: ModernTypography.caption.copyWith(
                  color: isDark ? ModernColors.textWhite : ModernColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn().scale(begin: const Offset(0.8, 0.8));
  }

  Color _getCategoryColor(String categoryKey) {
    switch (categoryKey) {
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

  // === NEUESTE POSTS ===
  Widget _buildLatestPostsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ModernSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEUESTE POSTS',
                style: ModernTypography.overline.copyWith(
                  color: isDark ? ModernColors.textGrey : ModernColors.textMedium,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to Channel Feed
                  // TODO: Implement navigation
                },
                child: Text(
                  'Alle anzeigen',
                  style: ModernTypography.caption.copyWith(
                    color: ModernColors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ModernSpacing.md),
        
        StreamBuilder<List<ChannelContent>>(
          stream: _loader.getAllContent(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: ModernColors.deepPurple,
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ModernCard(
                isDark: isDark,
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 48,
                        color: isDark ? ModernColors.textGrey : ModernColors.textMedium,
                      ),
                      const SizedBox(height: ModernSpacing.sm),
                      Text(
                        'Noch keine Posts verfügbar',
                        style: ModernTypography.bodyMedium.copyWith(
                          color: isDark ? ModernColors.textGrey : ModernColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            final latestPosts = snapshot.data!.take(3).toList();
            
            return Column(
              children: latestPosts.asMap().entries.map((entry) {
                final index = entry.key;
                final post = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: ModernSpacing.md),
                  child: _buildPostCard(post, isDark, index),
                );
              }).toList(),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildPostCard(ChannelContent post, bool isDark, int index) {
    final categoryColor = _getCategoryColor(post.category);
    
    return ModernGlassCard(
      padding: const EdgeInsets.all(ModernSpacing.md),
      borderRadius: ModernRadius.lg,
      blur: 10,
      opacity: isDark ? 0.1 : 0.05,
      border: Border.all(
        color: categoryColor.withValues(alpha: 0.3),
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ModernSpacing.sm,
              vertical: ModernSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(ModernRadius.sm),
            ),
            child: Text(
              TelegramChannelLoader.getCategoryConfig(post.category)?.name ?? 'Allgemein',
              style: ModernTypography.caption.copyWith(
                color: categoryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(height: ModernSpacing.sm),
          
          // Post Text
          Text(
            post.text,
            style: ModernTypography.bodyMedium.copyWith(
              color: isDark ? ModernColors.textWhite : ModernColors.textDark,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: ModernSpacing.sm),
          
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(post.date),
                style: ModernTypography.caption.copyWith(
                  color: isDark ? ModernColors.textGrey : ModernColors.textMedium,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: categoryColor,
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: -0.2, end: 0);
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

  // === QUICK ACTIONS ===
  Widget _buildQuickActionsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ModernSpacing.sm),
          child: Text(
            'SCHNELLZUGRIFF',
            style: ModernTypography.overline.copyWith(
              color: isDark ? ModernColors.textGrey : ModernColors.textMedium,
            ),
          ),
        ),
        const SizedBox(height: ModernSpacing.md),
        
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.search,
                label: 'Suchen',
                color: ModernColors.deepPurple,
                isDark: isDark,
                onTap: () {
                  // TODO: Navigate to search
                },
              ),
            ),
            const SizedBox(width: ModernSpacing.md),
            Expanded(
              child: _buildActionButton(
                icon: Icons.analytics,
                label: 'Statistiken',
                color: ModernColors.goldenHoney,
                isDark: isDark,
                onTap: () {
                  // TODO: Navigate to stats
                },
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ModernCard(
        isDark: isDark,
        padding: const EdgeInsets.all(ModernSpacing.md),
        borderRadius: ModernRadius.md,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: ModernSpacing.sm),
            Text(
              label,
              style: ModernTypography.button.copyWith(
                color: isDark ? ModernColors.textWhite : ModernColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
