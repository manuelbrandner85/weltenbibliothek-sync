import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../services/content_categorizer.dart';
import '../services/telegram_embed_service.dart';
import 'telegram_style_media_viewer.dart';

/// v2.30.0 - Telegram Library Screen
/// 
/// Kategorisierte Telegram-Medienbibliothek mit:
/// - Smart Kategorisierung nach Themen
/// - Episode-Sortierung
/// - Telegram Web Embed Support
/// - Original Telegram-Beschreibungen
/// - Thumbnails wie bei Telegram
class TelegramLibraryScreen extends StatefulWidget {
  const TelegramLibraryScreen({super.key});

  @override
  State<TelegramLibraryScreen> createState() => _TelegramLibraryScreenState();
}

class _TelegramLibraryScreenState extends State<TelegramLibraryScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  final ContentCategorizer _categorizer = ContentCategorizer();
  final TelegramEmbedService _embedService = TelegramEmbedService();
  
  final List<MediaType> _mediaTypes = [
    MediaType(title: 'PDFs', icon: Icons.picture_as_pdf, collection: 'telegram_pdfs', color: Colors.red),
    MediaType(title: 'Bilder', icon: Icons.image, collection: 'telegram_bilder', color: Colors.blue),
    MediaType(title: 'Videos', icon: Icons.play_circle_fill, collection: 'telegram_videos', color: Colors.purple),
    MediaType(title: 'Podcasts', icon: Icons.podcasts, collection: 'telegram_podcasts', color: Colors.orange),
    MediaType(title: 'Hörbücher', icon: Icons.headphones, collection: 'telegram_hoerbuecher', color: Colors.green),
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: _mediaTypes.length, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Telegram Bibliothek',
          style: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryPurple,
        bottom: TabBar(
          controller: _mainTabController,
          isScrollable: true,
          indicatorColor: AppTheme.secondaryGold,
          labelColor: AppTheme.secondaryGold,
          unselectedLabelColor: Colors.white70,
          tabs: _mediaTypes.map((type) => Tab(
            icon: Icon(type.icon),
            text: type.title,
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: _mediaTypes.map((type) => 
          CategorizedMediaView(
            mediaType: type,
            categorizer: _categorizer,
            embedService: _embedService,
          )
        ).toList(),
      ),
    );
  }
}

class CategorizedMediaView extends StatelessWidget {
  final MediaType mediaType;
  final ContentCategorizer categorizer;
  final TelegramEmbedService embedService;

  const CategorizedMediaView({
    super.key,
    required this.mediaType,
    required this.categorizer,
    required this.embedService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(mediaType.collection)
          .orderBy('timestamp', descending: false)
          .limit(500)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: mediaType.color));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Fehler beim Laden', style: TextStyle(color: Colors.red.shade300, fontSize: 18)),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(mediaType.icon, size: 64, color: Colors.white38),
                const SizedBox(height: 16),
                Text('Keine ${mediaType.title} gefunden', 
                     style: const TextStyle(color: Colors.white70, fontSize: 18)),
              ],
            ),
          );
        }

        // Konvertiere Docs zu Maps
        final items = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['_doc_id'] = doc.id;
          return data;
        }).toList();

        // Gruppiere nach Kategorie
        final grouped = categorizer.groupByCategory(items);
        final categories = grouped.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final categoryItems = grouped[category]!;
            final icon = categorizer.getCategoryIcon(category);

            return CategorySection(
              category: category,
              icon: icon,
              items: categoryItems,
              mediaType: mediaType,
              embedService: embedService,
            );
          },
        );
      },
    );
  }
}

class CategorySection extends StatefulWidget {
  final String category;
  final String icon;
  final List<Map<String, dynamic>> items;
  final MediaType mediaType;
  final TelegramEmbedService embedService;

  const CategorySection({
    super.key,
    required this.category,
    required this.icon,
    required this.items,
    required this.mediaType,
    required this.embedService,
  });

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(widget.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.category,
                    style: const TextStyle(
                      color: AppTheme.secondaryGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${widget.items.length}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          ...widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final episodeNumber = item['_episode_number'] as int?;
            
            return TelegramMediaListTile(
              data: item,
              mediaType: widget.mediaType,
              index: index + 1,
              episodeNumber: episodeNumber,
              embedService: widget.embedService,
            );
          }),
      ],
    );
  }
}

class TelegramMediaListTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final MediaType mediaType;
  final int index;
  final int? episodeNumber;
  final TelegramEmbedService embedService;

  const TelegramMediaListTile({
    super.key,
    required this.data,
    required this.mediaType,
    required this.index,
    this.episodeNumber,
    required this.embedService,
  });

  @override
  Widget build(BuildContext context) {
    // Verwende TelegramEmbedService für konsistente Namen
    final displayName = embedService.getDisplayName(data);
    final description = embedService.getDescription(data);
    final thumbnailUrl = embedService.getThumbnailUrl(data);
    final hasTelegramUrl = embedService.hasTelegramUrl(data);
    
    final fileSize = data['file_size'] ?? 0;
    final duration = data['duration'] ?? 0;

    String subtitle = '';
    if (episodeNumber != null) {
      subtitle = 'Folge $episodeNumber';
    }
    if (fileSize > 0) {
      final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      subtitle += subtitle.isEmpty ? '$sizeMB MB' : ' • $sizeMB MB';
    }
    if (duration > 0) {
      final minutes = duration ~/ 60;
      subtitle += subtitle.isEmpty ? '$minutes Min' : ' • $minutes Min';
    }

    // Zeige Telegram-Status
    if (!hasTelegramUrl) {
      subtitle += subtitle.isEmpty ? '⚠️ Kein Telegram-Link' : ' • ⚠️ Kein Link';
    }

    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: _buildLeading(thumbnailUrl),
        title: Text(
          displayName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty)
              Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  description,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: mediaType.color, size: 16),
        onTap: () => _openMedia(context),
      ),
    );
  }

  Widget _buildLeading(String? thumbnailUrl) {
    if (thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: thumbnailUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: mediaType.color.withValues(alpha: 0.2),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(mediaType.color),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackLeading(),
        ),
      );
    }
    
    return _buildFallbackLeading();
  }

  Widget _buildFallbackLeading() {
    return CircleAvatar(
      backgroundColor: mediaType.color.withValues(alpha: 0.2),
      child: episodeNumber != null
          ? Text(
              '$episodeNumber',
              style: TextStyle(color: mediaType.color, fontWeight: FontWeight.bold),
            )
          : Icon(mediaType.icon, color: mediaType.color, size: 20),
    );
  }

  void _openMedia(BuildContext context) {
    String viewerMediaType;
    switch (mediaType.title) {
      case 'PDFs':
        viewerMediaType = 'pdf';
        break;
      case 'Bilder':
        viewerMediaType = 'image';
        break;
      case 'Videos':
        viewerMediaType = 'video';
        break;
      case 'Podcasts':
      case 'Hörbücher':
        viewerMediaType = 'audio';
        break;
      default:
        viewerMediaType = 'unknown';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelegramStyleMediaViewer(
          mediaData: data,
          mediaType: viewerMediaType,
        ),
      ),
    );
  }
}

class MediaType {
  final String title;
  final IconData icon;
  final String collection;
  final Color color;

  MediaType({
    required this.title,
    required this.icon,
    required this.collection,
    required this.color,
  });
}
