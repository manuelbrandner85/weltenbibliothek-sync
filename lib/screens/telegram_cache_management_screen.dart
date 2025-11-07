import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/telegram_service.dart';

/// Telegram Cache Management Screen
/// 
/// Features:
/// - Cache-Größe anzeigen
/// - Cache leeren
/// - Einzelne Dateien verwalten
/// - Cache-Statistiken
/// - Auto-Clean Einstellungen
class TelegramCacheManagementScreen extends StatefulWidget {
  const TelegramCacheManagementScreen({Key? key}) : super(key: key);

  @override
  State<TelegramCacheManagementScreen> createState() => _TelegramCacheManagementScreenState();
}

class _TelegramCacheManagementScreenState extends State<TelegramCacheManagementScreen> {
  bool _isLoading = true;
  int _totalFiles = 0;
  int _totalSize = 0; // in bytes
  Map<String, int> _fileTypeStats = {};
  List<FileInfo> _cacheFiles = [];

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache-Verwaltung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheInfo,
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cache Overview Card
                _buildCacheOverviewCard(),
                
                const SizedBox(height: 16),
                
                // File Type Statistics
                _buildFileTypeStatsCard(),
                
                const SizedBox(height: 16),
                
                // Actions
                _buildActionsCard(),
                
                const SizedBox(height: 16),
                
                // Cached Files List
                _buildCachedFilesList(),
              ],
            ),
          ),
    );
  }

  /// Cache Overview Card
  Widget _buildCacheOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cache-Übersicht',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Total Size
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gesamtgröße:'),
                Text(
                  _formatBytes(_totalSize),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Total Files
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Anzahl Dateien:'),
                Text(
                  '$_totalFiles Dateien',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Average File Size
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Durchschnittsgröße:'),
                Text(
                  _totalFiles > 0 
                    ? _formatBytes(_totalSize ~/ _totalFiles)
                    : '0 B',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            // Progress Bar
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _getCacheUsagePercentage(),
              backgroundColor: Colors.grey[300],
              color: _getCacheUsageColor(),
            ),
            const SizedBox(height: 4),
            Text(
              '${(_getCacheUsagePercentage() * 100).toStringAsFixed(1)}% genutzt',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// File Type Statistics Card
  Widget _buildFileTypeStatsCard() {
    if (_fileTypeStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dateitypen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ..._fileTypeStats.entries.map((entry) {
              final percentage = _totalSize > 0 
                ? (entry.value / _totalSize) * 100 
                : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getFileTypeIcon(entry.key),
                              size: 20,
                              color: _getFileTypeColor(entry.key),
                            ),
                            const SizedBox(width: 8),
                            Text(entry.key.toUpperCase()),
                          ],
                        ),
                        Text(
                          _formatBytes(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      color: _getFileTypeColor(entry.key),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Actions Card
  Widget _buildActionsCard() {
    final telegramService = Provider.of<TelegramService>(context, listen: false);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktionen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Clear All Cache Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmClearCache(telegramService),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Gesamten Cache leeren'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Clear Old Files Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _clearOldFiles,
                icon: const Icon(Icons.schedule),
                label: const Text('Alte Dateien löschen (>30 Tage)'),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Optimize Cache Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _optimizeCache,
                icon: const Icon(Icons.tune),
                label: const Text('Cache optimieren'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cached Files List
  Widget _buildCachedFilesList() {
    if (_cacheFiles.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.folder_open,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine gecachten Dateien',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gecachte Dateien',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_cacheFiles.length} Dateien',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cacheFiles.length > 20 ? 20 : _cacheFiles.length,
            itemBuilder: (context, index) {
              final file = _cacheFiles[index];
              return ListTile(
                leading: Icon(
                  _getFileTypeIcon(file.extension),
                  color: _getFileTypeColor(file.extension),
                ),
                title: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${_formatBytes(file.size)} • ${_formatDate(file.modifiedDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _deleteFile(file),
                  tooltip: 'Löschen',
                ),
              );
            },
          ),
          if (_cacheFiles.length > 20)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Weitere ${_cacheFiles.length - 20} Dateien...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ========== DATA LOADING ==========

  Future<void> _loadCacheInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/telegram_cache');
      
      if (!await cacheDir.exists()) {
        setState(() {
          _totalFiles = 0;
          _totalSize = 0;
          _fileTypeStats = {};
          _cacheFiles = [];
          _isLoading = false;
        });
        return;
      }

      int totalSize = 0;
      int fileCount = 0;
      final Map<String, int> typeStats = {};
      final List<FileInfo> files = [];

      await for (var entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          final size = stat.size;
          final extension = entity.path.split('.').last.toLowerCase();
          
          totalSize += size;
          fileCount++;
          
          typeStats[extension] = (typeStats[extension] ?? 0) + size;
          
          files.add(FileInfo(
            path: entity.path,
            name: entity.path.split('/').last,
            size: size,
            extension: extension,
            modifiedDate: stat.modified,
          ));
        }
      }

      // Sort files by modified date (newest first)
      files.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));

      setState(() {
        _totalSize = totalSize;
        _totalFiles = fileCount;
        _fileTypeStats = typeStats;
        _cacheFiles = files;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  // ========== ACTIONS ==========

  Future<void> _confirmClearCache(TelegramService telegramService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache leeren?'),
        content: Text(
          'Dadurch werden alle $_totalFiles Dateien ($_formatBytes(_totalSize)) gelöscht. '
          'Die Dateien werden bei Bedarf erneut heruntergeladen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await telegramService.clearCache();
      await _loadCacheInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Cache geleert')),
        );
      }
    }
  }

  Future<void> _clearOldFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/telegram_cache');
      
      if (!await cacheDir.exists()) return;

      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      int deletedCount = 0;
      int deletedSize = 0;

      await for (var entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            deletedSize += stat.size;
            deletedCount++;
            await entity.delete();
          }
        }
      }

      await _loadCacheInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $deletedCount Dateien gelöscht ($_formatBytes(deletedSize))'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e')),
        );
      }
    }
  }

  Future<void> _optimizeCache() async {
    // TODO: Implement cache optimization
    // - Remove duplicate files
    // - Compress thumbnails
    // - Remove unused files
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔧 Cache-Optimierung in Entwicklung')),
    );
  }

  Future<void> _deleteFile(FileInfo file) async {
    try {
      await File(file.path).delete();
      await _loadCacheInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${file.name} gelöscht')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e')),
        );
      }
    }
  }

  // ========== HELPER METHODS ==========

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Heute';
    if (diff.inDays == 1) return 'Gestern';
    if (diff.inDays < 7) return 'vor ${diff.inDays}d';
    if (diff.inDays < 30) return 'vor ${(diff.inDays / 7).floor()}w';
    return '${date.day}.${date.month}.${date.year}';
  }

  double _getCacheUsagePercentage() {
    const maxCache = 500 * 1024 * 1024; // 500 MB max
    return (_totalSize / maxCache).clamp(0.0, 1.0);
  }

  Color _getCacheUsageColor() {
    final percentage = _getCacheUsagePercentage();
    if (percentage < 0.5) return Colors.green;
    if (percentage < 0.8) return Colors.orange;
    return Colors.red;
  }

  IconData _getFileTypeIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'webm':
      case 'mkv':
        return Icons.videocam;
      case 'mp3':
      case 'ogg':
      case 'wav':
        return Icons.audiotrack;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.blue;
      case 'mp4':
      case 'webm':
      case 'mkv':
        return Colors.purple;
      case 'mp3':
      case 'ogg':
      case 'wav':
        return Colors.orange;
      case 'pdf':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// File Info Data Class
class FileInfo {
  final String path;
  final String name;
  final int size;
  final String extension;
  final DateTime modifiedDate;

  FileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.extension,
    required this.modifiedDate,
  });
}
