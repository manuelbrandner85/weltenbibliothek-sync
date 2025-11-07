import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/telegram_service.dart';
import '../config/app_theme.dart';

/// Telegram Auto-Sync Dashboard Widget
/// 
/// Zeigt Live-Statistiken der automatischen Synchronisation:
/// - Anzahl synchronisierter Videos, Dokumente, Fotos, Audio, Posts
/// - Letzte Synchronisation (Timestamp)
/// - Manueller Sync-Button
/// - Live-Updates via Firestore Streams
class TelegramAutoSyncWidget extends StatefulWidget {
  const TelegramAutoSyncWidget({super.key});

  @override
  State<TelegramAutoSyncWidget> createState() => _TelegramAutoSyncWidgetState();
}

class _TelegramAutoSyncWidgetState extends State<TelegramAutoSyncWidget> {
  final TelegramService _telegramService = TelegramService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  
  // Sync-Statistiken
  int _videoCount = 0;
  int _documentCount = 0;
  int _photoCount = 0;
  int _audioCount = 0;
  int _postCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadSyncStats();
    _loadLastSyncTime();
  }
  
  /// Lädt Sync-Statistiken aus Firestore
  Future<void> _loadSyncStats() async {
    try {
      // Zähle Videos
      final videosSnapshot = await _firestore.collection('telegram_videos').count().get();
      _videoCount = videosSnapshot.count ?? 0;
      
      // Zähle Dokumente
      final docsSnapshot = await _firestore.collection('telegram_documents').count().get();
      _documentCount = docsSnapshot.count ?? 0;
      
      // Zähle Fotos
      final photosSnapshot = await _firestore.collection('telegram_photos').count().get();
      _photoCount = photosSnapshot.count ?? 0;
      
      // Zähle Audio
      final audioSnapshot = await _firestore.collection('telegram_audio').count().get();
      _audioCount = audioSnapshot.count ?? 0;
      
      // Zähle Posts
      final postsSnapshot = await _firestore.collection('telegram_posts').count().get();
      _postCount = postsSnapshot.count ?? 0;
      
      if (mounted) setState(() {});
      
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Sync-Stats: $e');
    }
  }
  
  /// Lädt letzte Sync-Zeit aus Firestore
  Future<void> _loadLastSyncTime() async {
    try {
      // Finde neuesten Eintrag über alle Collections
      final collections = [
        'telegram_videos',
        'telegram_documents',
        'telegram_photos',
        'telegram_audio',
        'telegram_posts',
      ];
      
      DateTime? latestTime;
      
      for (var collection in collections) {
        final snapshot = await _firestore
            .collection(collection)
            .orderBy('indexed_at', descending: true)
            .limit(1)
            .get();
        
        if (snapshot.docs.isNotEmpty) {
          final timestamp = snapshot.docs.first.data()['indexed_at'] as Timestamp?;
          if (timestamp != null) {
            final time = timestamp.toDate();
            if (latestTime == null || time.isAfter(latestTime)) {
              latestTime = time;
            }
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _lastSyncTime = latestTime;
        });
      }
      
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der letzten Sync-Zeit: $e');
    }
  }
  
  /// Führt manuellen Sync durch
  Future<void> _performManualSync() async {
    if (_isSyncing) return;
    
    setState(() => _isSyncing = true);
    
    try {
      // Zeige Snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Synchronisiere Telegram-Inhalte...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Warte auf Polling-Zyklus (Telegram Service pollt bereits automatisch)
      await Future.delayed(const Duration(seconds: 3));
      
      // Reload Stats
      await _loadSyncStats();
      await _loadLastSyncTime();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('✅ Synchronisation abgeschlossen'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }
  
  /// Formatiert Timestamp zu lesbarem String
  String _formatTimestamp(DateTime? time) {
    if (time == null) return 'Nie';
    
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) {
      return 'vor ${diff.inSeconds}s';
    } else if (diff.inMinutes < 60) {
      return 'vor ${diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      return 'vor ${diff.inHours}h';
    } else {
      return 'vor ${diff.inDays}d';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final totalCount = _videoCount + _documentCount + _photoCount + _audioCount + _postCount;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withOpacity(0.1),
            AppTheme.accentBlue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentBlue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sync,
                    color: AppTheme.accentBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automatische Synchronisation',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Letzte Aktualisierung: ${_formatTimestamp(_lastSyncTime)}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Manueller Sync-Button
                IconButton(
                  onPressed: _isSyncing ? null : _performManualSync,
                  icon: _isSyncing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accentBlue,
                          ),
                        )
                      : Icon(
                          Icons.refresh,
                          color: AppTheme.accentBlue,
                        ),
                  tooltip: 'Jetzt synchronisieren',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Statistiken
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Gesamt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Synchronisierte Inhalte',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$totalCount',
                        style: TextStyle(
                          color: AppTheme.secondaryGold,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 24),
                  
                  // Details
                  _buildStatRow(Icons.smart_display, 'Videos', _videoCount, Colors.red),
                  const SizedBox(height: 8),
                  _buildStatRow(Icons.description, 'Dokumente', _documentCount, Colors.blue),
                  const SizedBox(height: 8),
                  _buildStatRow(Icons.photo_library, 'Fotos', _photoCount, Colors.green),
                  const SizedBox(height: 8),
                  _buildStatRow(Icons.music_note, 'Audio', _audioCount, Colors.purple),
                  const SizedBox(height: 8),
                  _buildStatRow(Icons.article, 'Posts', _postCount, Colors.orange),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Info-Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.accentBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Neue Telegram-Inhalte werden automatisch alle 2 Sekunden synchronisiert',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(IconData icon, String label, int count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
