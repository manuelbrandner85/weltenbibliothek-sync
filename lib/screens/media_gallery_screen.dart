import 'package:flutter/material.dart';
import '../services/media_service.dart';
import '../models/media_item.dart';
import '../widgets/media_player_widget.dart';
import '../config/app_theme.dart';

/// Media Gallery Screen - Zeigt alle Telegram-Medien vom FTP Server
/// Kategorien: Alle, Videos, Audio, Bilder, PDFs
class MediaGalleryScreen extends StatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> 
    with SingleTickerProviderStateMixin {
  
  final MediaService _mediaService = MediaService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              '📚',
              style: TextStyle(fontSize: 24, color: AppTheme.secondaryGold),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weltenbibliothek Medien', style: TextStyle(fontSize: 16)),
                  Text(
                    'Telegram → FTP Server',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? AppTheme.backgroundDark : Colors.deepPurple,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.secondaryGold,
          labelColor: AppTheme.secondaryGold,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.all_inclusive), text: 'Alle'),
            Tab(icon: Icon(Icons.video_library), text: 'Videos'),
            Tab(icon: Icon(Icons.audiotrack), text: 'Audio'),
            Tab(icon: Icon(Icons.image), text: 'Bilder'),
            Tab(icon: Icon(Icons.picture_as_pdf), text: 'PDFs'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Suchfeld
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Suche nach Titel, Beschreibung oder Dateiname...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Statistik-Card
          _buildStatisticsCard(),
          
          // Tab-Inhalt
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMediaList(null), // Alle
                _buildMediaList('video'),
                _buildMediaList('audio'),
                _buildMediaList('image'),
                _buildMediaList('pdf'),
              ],
            ),
          ),
        ],
      ),
      
      // Floating Action Button - Sync Info
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSyncInfo,
        icon: const Icon(Icons.sync),
        label: const Text('Sync Status'),
        backgroundColor: AppTheme.accentBlue,
      ),
    );
  }
  
  /// Statistik-Card mit Medien-Zählern
  Widget _buildStatisticsCard() {
    return FutureBuilder<Map<String, int>>(
      future: _mediaService.getMediaStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final stats = snapshot.data!;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Gesamt', stats['total'] ?? 0, Icons.folder, Colors.blue),
                _buildStatItem('Videos', stats['videos'] ?? 0, Icons.video_library, Colors.blue),
                _buildStatItem('Audio', stats['audios'] ?? 0, Icons.audiotrack, Colors.purple),
                _buildStatItem('Bilder', stats['images'] ?? 0, Icons.image, Colors.green),
                _buildStatItem('PDFs', stats['pdfs'] ?? 0, Icons.picture_as_pdf, Colors.red),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  /// Media-Liste mit Suche und Filter
  Widget _buildMediaList(String? mediaType) {
    return FutureBuilder<List<MediaItem>>(
      future: _searchQuery.isNotEmpty
          ? _mediaService.searchMedia(_searchQuery)
          : (mediaType == null 
              ? _mediaService.getAllMedia()
              : _mediaService.getMediaByType(mediaType)),
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
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Fehler: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          );
        }
        
        final mediaList = snapshot.data ?? [];
        
        if (mediaList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Keine Ergebnisse für "$_searchQuery"'
                      : mediaType != null
                          ? 'Keine ${_getMediaTypeName(mediaType)} gefunden'
                          : 'Keine Medien gefunden',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Medien werden automatisch vom Python-Script synchronisiert',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: mediaList.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            return _buildMediaCard(mediaList[index]);
          },
        );
      },
    );
  }
  
  /// Media-Card mit Thumbnail und Infos
  Widget _buildMediaCard(MediaItem media) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      child: InkWell(
        onTap: () => _openMedia(media),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon/Thumbnail
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _getMediaColor(media.mediaType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getMediaColor(media.mediaType).withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    media.iconEmoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Inhalt
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titel
                    Text(
                      media.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Beschreibung
                    if (media.description.isNotEmpty)
                      Text(
                        media.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Typ-Badge und Dateiname
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getMediaColor(media.mediaType),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getMediaTypeName(media.mediaType),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            media.fileName,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Play/Open Icon
              Icon(
                _getActionIcon(media.mediaType),
                color: _getMediaColor(media.mediaType),
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Öffne Media-Player
  void _openMedia(MediaItem media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaPlayerWidget(media: media),
      ),
    );
  }
  
  /// Zeige Sync-Info Dialog
  void _showSyncInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.sync, color: AppTheme.accentBlue),
            const SizedBox(width: 8),
            const Text('Telegram Sync Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Automatische Synchronisation:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSyncInfoRow('📡', 'Telegram', 'Medien herunterladen'),
            _buildSyncInfoRow('📤', 'FTP Server', 'Upload zu Weltenbibliothek.ddns.net'),
            _buildSyncInfoRow('☁️', 'Firestore', 'Metadaten speichern'),
            const Divider(height: 24),
            const Text(
              'Server-Details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Host: Weltenbibliothek.ddns.net\nPort: 21 (FTP) / 8080 (HTTP)\nBenutzer: Weltenbibliothek',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              setState(() {}); // Refresh
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Aktualisieren'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSyncInfoRow(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }
  
  /// Hilfsfunktionen
  Color _getMediaColor(String mediaType) {
    switch (mediaType) {
      case 'video':
        return Colors.blue;
      case 'audio':
        return Colors.purple;
      case 'image':
        return Colors.green;
      case 'pdf':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getMediaTypeName(String mediaType) {
    switch (mediaType) {
      case 'video':
        return 'VIDEO';
      case 'audio':
        return 'AUDIO';
      case 'image':
        return 'BILD';
      case 'pdf':
        return 'PDF';
      default:
        return 'DATEI';
    }
  }
  
  IconData _getActionIcon(String mediaType) {
    switch (mediaType) {
      case 'video':
      case 'audio':
        return Icons.play_circle_filled;
      case 'image':
        return Icons.image_outlined;
      case 'pdf':
        return Icons.open_in_new;
      default:
        return Icons.arrow_forward_ios;
    }
  }
}
