import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import 'unified_media_viewer_screen.dart';

/// Unified Media Library Screen v1.0
/// 
/// Zeigt ALLE Medien aus Telegram-Kanälen:
/// - Videos, PDFs, Bilder, Podcasts, Hörbücher
/// - Automatisch aus Firestore geladen
/// - Direkte Wiedergabe beim Antippen
class UnifiedMediaLibraryScreen extends StatefulWidget {
  const UnifiedMediaLibraryScreen({super.key});

  @override
  State<UnifiedMediaLibraryScreen> createState() => _UnifiedMediaLibraryScreenState();
}

class _UnifiedMediaLibraryScreenState extends State<UnifiedMediaLibraryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _selectedCategory = 'alle';
  String _searchQuery = '';
  
  final List<Map<String, dynamic>> _categories = [
    {'id': 'alle', 'label': 'Alle', 'icon': Icons.grid_view, 'color': AppTheme.primaryPurple},
    {'id': 'videos', 'label': 'Videos', 'icon': Icons.video_library, 'color': Colors.red},
    {'id': 'pdfs', 'label': 'PDFs', 'icon': Icons.picture_as_pdf, 'color': Colors.blue},
    {'id': 'bilder', 'label': 'Bilder', 'icon': Icons.image, 'color': Colors.green},
    {'id': 'podcasts', 'label': 'Podcasts', 'icon': Icons.mic, 'color': Colors.orange},
    {'id': 'hoerbuecher', 'label': 'Hörbücher', 'icon': Icons.headphones, 'color': Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCategoryTabs(),
            _buildSearchBar(),
            Expanded(child: _buildMediaGrid()),
          ],
        ),
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
            AppTheme.primaryPurple.withValues(alpha: 0.2),
            AppTheme.backgroundDark,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.secondaryGold],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.collections, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medien-Bibliothek',
                  style: AppTheme.headlineLarge.copyWith(fontSize: 24),
                ),
                Text(
                  'Telegram-Inhalte direkt abspielen',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.secondaryGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['id'];
          
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['id'] as String),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [cat['color'] as Color, (cat['color'] as Color).withValues(alpha: 0.6)],
                      )
                    : null,
                color: isSelected ? null : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? (cat['color'] as Color)
                      : AppTheme.textSecondary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        style: AppTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Suche nach Titel...',
          hintStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          prefixIcon: Icon(Icons.search, color: AppTheme.primaryPurple),
          filled: true,
          fillColor: AppTheme.cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildMediaGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getMediaStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Fehler: ${snapshot.error}', style: AppTheme.bodyMedium),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryPurple),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                Text('Keine Medien gefunden', style: AppTheme.bodyLarge),
                const SizedBox(height: 8),
                Text(
                  'Bitte Telegram-Sync ausführen',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildMediaCard(data);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getMediaStream() {
    Query query = _firestore.collection('telegram_media');

    // Filter by category
    if (_selectedCategory != 'alle') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    // Order by date
    query = query.orderBy('created_at', descending: true);

    return query.snapshots();
  }

  Widget _buildMediaCard(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Unbekannt';
    final type = data['type'] ?? 'unknown';
    final downloadUrl = data['download_url'];
    
    // Filter by search
    if (_searchQuery.isNotEmpty && !title.toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _openMedia(data),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail/Icon
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getTypeColor(type),
                      _getTypeColor(type).withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: downloadUrl != null && type == 'image'
                      ? CachedNetworkImage(
                          imageUrl: downloadUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(
                            _getTypeIcon(type),
                            size: 48,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _getTypeIcon(type),
                          size: 48,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(_getTypeIcon(type), size: 14, color: _getTypeColor(type)),
                      const SizedBox(width: 4),
                      Text(
                        _getTypeLabel(type),
                        style: AppTheme.bodySmall.copyWith(
                          color: _getTypeColor(type),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMedia(Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedMediaViewerScreen(mediaData: data),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'video': return Icons.play_circle_filled;
      case 'pdf': return Icons.picture_as_pdf;
      case 'image': return Icons.image;
      case 'audio': return Icons.audiotrack;
      default: return Icons.file_present;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'video': return Colors.red;
      case 'pdf': return Colors.blue;
      case 'image': return Colors.green;
      case 'audio': return Colors.orange;
      default: return AppTheme.primaryPurple;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'video': return 'Video';
      case 'pdf': return 'PDF';
      case 'image': return 'Bild';
      case 'audio': return 'Audio';
      default: return 'Datei';
    }
  }
}
