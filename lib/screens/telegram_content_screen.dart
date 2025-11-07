import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/telegram_service.dart';
import '../services/auth_service.dart'; // ✅ NEU: Für User ID
import '../models/telegram_models.dart';
import '../config/app_theme.dart';
import '../widgets/telegram_health_widget.dart';
import '../widgets/telegram_sync_control_widget.dart';
import '../widgets/telegram_auto_sync_widget.dart';
import 'telegram_advanced_search_screen.dart'; // ✅ NEU: Erweiterte Suche

/// Universeller Telegram-Inhalte Screen
/// 
/// Zeigt ALLE Telegram-Inhalte in einer Tab-basierten Ansicht:
/// - Alle (gemischt)
/// - Videos
/// - Dokumente (PDFs, Word, etc.)
/// - Fotos
/// - Audio
/// - Posts (Text)
class TelegramContentScreen extends StatefulWidget {
  const TelegramContentScreen({super.key});

  @override
  State<TelegramContentScreen> createState() => _TelegramContentScreenState();
}

class _TelegramContentScreenState extends State<TelegramContentScreen> 
    with SingleTickerProviderStateMixin {
  
  final TelegramService _telegramService = TelegramService();
  final AuthService _authService = AuthService(); // ✅ NEU: Auth Service
  late TabController _tabController;
  String? _selectedCategory;
  
  // ✅ NEU: Message Composer
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  
  // Kategorie-Namen (Deutsch)
  final Map<String, String> _categoryNames = {
    'lostCivilizations': 'Verlorene Zivilisationen',
    'alienContact': 'Außerirdische Kontakte',
    'ancientTechnology': 'Antike Technologien',
    'mysteriousArtifacts': 'Mysteriöse Artefakte',
    'paranormalPhenomena': 'Paranormale Phänomene',
    'secretSocieties': 'Geheimgesellschaften',
    'dimensionalAnomalies': 'Dimensions-Anomalien',
    'techMysteries': 'Technologie-Mysterien',
    'cosmicEvents': 'Kosmische Ereignisse',
    'hiddenKnowledge': 'Verborgenes Wissen',
  };
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose(); // ✅ NEU: Cleanup controller
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.menu_book, color: AppTheme.secondaryGold, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weltenbibliothek', style: TextStyle(fontSize: 18)),
                  Row(
                    children: [
                      Icon(Icons.sync, size: 12, color: Colors.green[400]),
                      const SizedBox(width: 4),
                      Text(
                        'Mit Telegram synchronisiert',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: 'Erweiterte Suche',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TelegramAdvancedSearchScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.accentBlue,
          labelColor: AppTheme.secondaryGold,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.all_inclusive), text: 'Alle'),
            Tab(icon: Icon(Icons.smart_display), text: 'Videos'),
            Tab(icon: Icon(Icons.description), text: 'Dokumente'),
            Tab(icon: Icon(Icons.photo_library), text: 'Fotos'),
            Tab(icon: Icon(Icons.music_note), text: 'Audio'),
            Tab(icon: Icon(Icons.article), text: 'Posts'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ✅ NEU: Message Composer (oben)
          _buildMessageComposer(),
          
          // Tabs Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllContentTab(),
                _buildVideosTab(),
                _buildDocumentsTab(),
                _buildPhotosTab(),
                _buildAudioTab(),
                _buildPostsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // ========== TAB 1: ALLE INHALTE ==========
  
  Widget _buildAllContentTab() {
    return Column(
      children: [
        // Auto-Sync Dashboard
        const TelegramAutoSyncWidget(),
        
        // Phase 2.2: Background Sync Control
        const TelegramSyncControlWidget(),
        
        // Phase 2.1: Health Status Widget
        const TelegramHealthWidget(),
        
        Expanded(
          child: FutureBuilder<Map<String, List<dynamic>>>(
            future: _telegramService.getAllTelegramContent(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return _buildErrorState('Fehler: ${snapshot.error}');
              }
              
              final content = snapshot.data ?? {};
              final videos = (content['videos'] as List<dynamic>? ?? []).cast<TelegramVideo>();
              final documents = (content['documents'] as List<dynamic>? ?? []).cast<TelegramDocument>();
              final photos = (content['photos'] as List<dynamic>? ?? []).cast<TelegramPhoto>();
              final audio = (content['audio'] as List<dynamic>? ?? []).cast<TelegramAudio>();
              final posts = (content['posts'] as List<dynamic>? ?? []).cast<TelegramPost>();
              
              final totalCount = videos.length + documents.length + photos.length + audio.length + posts.length;
              
              if (totalCount == 0) {
                return _buildEmptyState('Keine Telegram-Inhalte gefunden');
              }
              
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatisticsCard(videos.length, documents.length, photos.length, audio.length, posts.length),
                    
                    if (videos.isNotEmpty) _buildSectionHeader('Videos', videos.length),
                    if (videos.isNotEmpty) _buildVideosList(videos.take(5).toList()),
                    
                    if (documents.isNotEmpty) _buildSectionHeader('Dokumente', documents.length),
                    if (documents.isNotEmpty) _buildDocumentsList(documents.take(5).toList()),
                    
                    if (photos.isNotEmpty) _buildSectionHeader('Fotos', photos.length),
                    if (photos.isNotEmpty) _buildPhotosGrid(photos.take(6).toList()),
                    
                    if (audio.isNotEmpty) _buildSectionHeader('Audio', audio.length),
                    if (audio.isNotEmpty) _buildAudioList(audio.take(5).toList()),
                    
                    if (posts.isNotEmpty) _buildSectionHeader('Posts', posts.length),
                    if (posts.isNotEmpty) _buildPostsList(posts.take(5).toList()),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatisticsCard(int videos, int docs, int photos, int audio, int posts) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: AppTheme.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Telegram-Archiv Statistik',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryGold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.smart_display, 'Videos', videos),
                _buildStatItem(Icons.description, 'Docs', docs),
                _buildStatItem(Icons.photo, 'Fotos', photos),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.music_note, 'Audio', audio),
                _buildStatItem(Icons.article, 'Posts', posts),
                _buildStatItem(Icons.folder, 'Gesamt', videos + docs + photos + audio + posts),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String label, int count) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentBlue, size: 32),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryGold,
            ),
          ),
          Text(
            '$count Einträge',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  // ========== TAB 2: VIDEOS (OPTIMIERT) ==========
  
  Widget _buildVideosTab() {
    return Column(
      children: [
        // Kategorie-Filter
        _buildCategoryFilter(),
        
        // Video-Grid mit RefreshIndicator
        Expanded(
          child: StreamBuilder<List<TelegramVideo>>(
            stream: _selectedCategory == null
                ? _telegramService.getVideos()
                : _telegramService.getVideosByCategory(_selectedCategory!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildSkeletonGrid();
              }
              
              if (snapshot.hasError) {
                return _buildErrorState('Fehler: ${snapshot.error}');
              }
              
              final videos = snapshot.data ?? [];
              
              if (videos.isEmpty) {
                return _buildEmptyState('Keine Videos in dieser Kategorie');
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  // Trigger rebuild
                  setState(() {});
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: _buildVideosGrid(videos),
              );
            },
          ),
        ),
      ],
    );
  }
  
  // NEU: Video-Grid mit Thumbnails und Overlays
  Widget _buildVideosGrid(List<TelegramVideo> videos) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _buildVideoCard(video);
      },
    );
  }
  
  Widget _buildVideoCard(TelegramVideo video) {
    return Hero(
      tag: 'video_${video.id}',
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppTheme.surfaceDark,
        child: InkWell(
          onTap: () => _openTelegramUrl(video.videoUrl ?? ''),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail mit Overlay
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.purple.withOpacity(0.3),
                              Colors.blue.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.play_circle_filled,
                          size: 48,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    // Duration Badge
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(video.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info-Bereich
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titel
                      Text(
                        video.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // Kategorie-Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.accentBlue, width: 1),
                        ),
                        child: Text(
                          _getCategoryShortName(video.category),
                          style: TextStyle(
                            color: AppTheme.accentBlue,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Views
                      Row(
                        children: [
                          Icon(Icons.visibility, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${video.viewCount}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 11),
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
      ),
    );
  }
  
  // Alte Liste als Fallback
  Widget _buildVideosList(List<TelegramVideo> videos) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.surfaceDark,
          child: ListTile(
            leading: const Icon(Icons.smart_display, size: 40, color: Colors.grey),
            title: Text(
              video.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${_formatDuration(video.duration)} • ${_formatFileSize(video.fileSize)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  '${video.viewCount} Aufrufe',
                  style: TextStyle(color: AppTheme.accentBlue, fontSize: 12),
                ),
              ],
            ),
            trailing: Icon(Icons.open_in_new, color: AppTheme.secondaryGold),
            onTap: () => _openTelegramUrl(video.videoUrl ?? ''),
          ),
        );
      },
    );
  }
  
  // ========== TAB 3: DOKUMENTE ==========
  
  Widget _buildDocumentsTab() {
    return StreamBuilder<List<TelegramDocument>>(
      stream: _telegramService.getDocuments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return _buildErrorState('Fehler: ${snapshot.error}');
        }
        
        final documents = snapshot.data ?? [];
        
        if (documents.isEmpty) {
          return _buildEmptyState('Keine Dokumente gefunden');
        }
        
        return _buildDocumentsList(documents);
      },
    );
  }
  
  Widget _buildDocumentsList(List<TelegramDocument> documents) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.surfaceDark,
          child: ListTile(
            leading: Icon(
              _getDocumentIcon(doc.docType),
              size: 40,
              color: _getDocumentColor(doc.docType),
            ),
            title: Text(
              doc.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  doc.fileName,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_formatFileSize(doc.fileSize)} • ${doc.downloadCount} Downloads',
                  style: TextStyle(color: AppTheme.accentBlue, fontSize: 12),
                ),
              ],
            ),
            trailing: Icon(Icons.download, color: AppTheme.secondaryGold),
            onTap: () => _openTelegramUrl(doc.telegramUrl),
          ),
        );
      },
    );
  }
  
  IconData _getDocumentIcon(String docType) {
    switch (docType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'word':
        return Icons.description;
      case 'text':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  Color _getDocumentColor(String docType) {
    switch (docType) {
      case 'pdf':
        return Colors.red;
      case 'word':
        return Colors.blue;
      case 'text':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  // ========== TAB 4: FOTOS ==========
  
  Widget _buildPhotosTab() {
    return StreamBuilder<List<TelegramPhoto>>(
      stream: _telegramService.getPhotos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return _buildErrorState('Fehler: ${snapshot.error}');
        }
        
        final photos = snapshot.data ?? [];
        
        if (photos.isEmpty) {
          return _buildEmptyState('Keine Fotos gefunden');
        }
        
        return _buildPhotosGrid(photos);
      },
    );
  }
  
  Widget _buildPhotosGrid(List<TelegramPhoto> photos) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return Card(
          color: AppTheme.surfaceDark,
          child: InkWell(
            onTap: () => _openTelegramUrl(photo.telegramUrl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: photo.imageUrl != null
                      ? Image.network(
                          photo.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
                        )
                      : const Icon(Icons.photo, size: 60, color: Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${photo.width}x${photo.height} • ${photo.viewCount} Aufrufe',
                        style: TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // ========== TAB 5: AUDIO ==========
  
  Widget _buildAudioTab() {
    return StreamBuilder<List<TelegramAudio>>(
      stream: _telegramService.getAudio(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return _buildErrorState('Fehler: ${snapshot.error}');
        }
        
        final audioFiles = snapshot.data ?? [];
        
        if (audioFiles.isEmpty) {
          return _buildEmptyState('Keine Audio-Dateien gefunden');
        }
        
        return _buildAudioList(audioFiles);
      },
    );
  }
  
  Widget _buildAudioList(List<TelegramAudio> audioFiles) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: audioFiles.length,
      itemBuilder: (context, index) {
        final audio = audioFiles[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.surfaceDark,
          child: ListTile(
            leading: const Icon(Icons.music_note, size: 40, color: Colors.purple),
            title: Text(
              audio.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (audio.performer != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    audio.performer!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${_formatDuration(audio.duration)} • ${_formatFileSize(audio.fileSize)}',
                  style: TextStyle(color: AppTheme.accentBlue, fontSize: 12),
                ),
              ],
            ),
            trailing: Icon(Icons.play_arrow, color: AppTheme.secondaryGold),
            onTap: () => _openTelegramUrl(audio.telegramUrl),
          ),
        );
      },
    );
  }
  
  // ========== TAB 6: POSTS ==========
  
  Widget _buildPostsTab() {
    return StreamBuilder<List<TelegramPost>>(
      stream: _telegramService.getTextPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return _buildErrorState('Fehler: ${snapshot.error}');
        }
        
        final posts = snapshot.data ?? [];
        
        if (posts.isEmpty) {
          return _buildEmptyState('Keine Text-Posts gefunden');
        }
        
        return _buildPostsList(posts);
      },
    );
  }
  
  Widget _buildPostsList(List<TelegramPost> posts) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.surfaceDark,
          child: ListTile(
            leading: const Icon(Icons.article, size: 40, color: Colors.orange),
            title: Text(
              post.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  post.content,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${post.viewCount} Aufrufe',
                  style: TextStyle(color: AppTheme.accentBlue, fontSize: 12),
                ),
              ],
            ),
            trailing: Icon(Icons.open_in_new, color: AppTheme.secondaryGold),
            onTap: () => _openTelegramUrl(post.telegramUrl),
          ),
        );
      },
    );
  }
  
  // ========== HELPER WIDGETS ==========
  
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Telegram-Inhalte werden automatisch synchronisiert',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // ========== NEU: KATEGORIE-FILTER ==========
  
  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          // "Alle" Chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Alle'),
              selected: _selectedCategory == null,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = null;
                });
              },
              selectedColor: AppTheme.accentBlue,
              backgroundColor: AppTheme.surfaceDark,
              labelStyle: TextStyle(
                color: _selectedCategory == null ? Colors.white : Colors.grey,
                fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          // Kategorie-Chips
          ..._categoryNames.entries.map((entry) {
            final isSelected = _selectedCategory == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? entry.key : null;
                  });
                },
                selectedColor: AppTheme.accentBlue,
                backgroundColor: AppTheme.surfaceDark,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  // ========== NEU: SKELETON LOADING ==========
  
  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: AppTheme.surfaceDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  String _getCategoryShortName(String category) {
    final shortNames = {
      'lostCivilizations': 'Zivilisationen',
      'alienContact': 'Aliens',
      'ancientTechnology': 'Technologie',
      'mysteriousArtifacts': 'Artefakte',
      'paranormalPhenomena': 'Paranormal',
      'secretSocieties': 'Geheim',
      'dimensionalAnomalies': 'Dimensionen',
      'techMysteries': 'Tech',
      'cosmicEvents': 'Kosmos',
      'hiddenKnowledge': 'Wissen',
    };
    return shortNames[category] ?? category;
  }
  
  // ========== UTILITY FUNCTIONS ==========
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  Future<void> _openTelegramUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telegram-Link konnte nicht geöffnet werden')),
        );
      }
    }
  }

  // ========== MESSAGE COMPOSER ==========
  
  /// ✅ NEU: Message Composer Widget - Sende Nachrichten an Telegram
  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Icon(
            Icons.send_to_mobile,
            color: AppTheme.secondaryGold,
            size: 24,
          ),
          const SizedBox(width: 8),
          
          // Text Field
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_isSending,
              maxLines: null,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nachricht an Telegram senden...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppTheme.accentBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Send Button
          Material(
            color: _isSending ? Colors.grey[700] : AppTheme.accentBlue,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _isSending ? null : _sendMessage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ NEU: Sende Nachricht an Telegram
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final success = await _telegramService.sendMessageFromApp(
        text: text,
        userId: _authService.currentUser?.uid ?? 'anonymous',
      );

      if (success) {
        _messageController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('✅ Nachricht gesendet!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('❌ Fehler beim Senden'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}
