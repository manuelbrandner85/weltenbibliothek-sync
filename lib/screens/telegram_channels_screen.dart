import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../config/app_theme.dart';
import '../services/multi_channel_service.dart';
import '../widgets/glass_card.dart';

/// Telegram 6-Channel Feed Screen
/// Zeigt Inhalte aus allen 6 Telegram-Channels
class TelegramChannelsScreen extends StatefulWidget {
  const TelegramChannelsScreen({super.key});

  @override
  State<TelegramChannelsScreen> createState() => _TelegramChannelsScreenState();
}

class _TelegramChannelsScreenState extends State<TelegramChannelsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MultiChannelService _service = MultiChannelService();
  
  String? _selectedChannel;
  bool _isLoading = false;
  Map<String, int> _channelStats = {};
  
  @override
  void initState() {
    super.initState();
    final channels = MultiChannelService.channels;
    _tabController = TabController(
      length: channels.length + 1, // +1 für "Alle"
      vsync: this,
    );
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 0) {
            _selectedChannel = null;
          } else {
            _selectedChannel = channels.keys.elementAt(_tabController.index - 1);
          }
        });
      }
    });
    
    _loadStatistics();
  }
  
  Future<void> _loadStatistics() async {
    final stats = await _service.getChannelStatistics();
    setState(() {
      _channelStats = stats;
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final channels = MultiChannelService.channels;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Channel-Tabs
            _buildChannelTabs(channels),
            
            // Content Feed
            Expanded(
              child: _buildContentFeed(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadStatistics,
        backgroundColor: AppTheme.primaryPurple,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.refresh),
      ),
    );
  }
  
  Widget _buildHeader() {
    // Berechne Gesamtzahl aller Dokumente
    int totalDocs = 0;
    for (var count in _channelStats.values) {
      totalDocs += count;
    }
    
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
              Icons.telegram,
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
                  'Telegram Channels',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryGold,
                  ),
                ),
                Text(
                  '$totalDocs Nachrichten · 6 Channels',
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
  
  Widget _buildChannelTabs(Map<String, ChannelConfig> channels) {
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
          Tab(
            child: Row(
              children: [
                const Text('🌟', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text('Alle (${_channelStats.values.fold(0, (a, b) => a + b)})'),
              ],
            ),
          ),
          ...channels.entries.map((entry) {
            final config = entry.value;
            final count = _channelStats[entry.key] ?? 0;
            return Tab(
              child: Row(
                children: [
                  Text(config.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text('${config.name} ($count)'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildContentFeed() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _selectedChannel == null
          ? _service.getAllDocuments(limit: 50)
          : _service.getDocuments(_selectedChannel!, limit: 50),
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
        
        final documents = snapshot.data ?? [];
        
        if (documents.isEmpty) {
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
                  'Keine Nachrichten gefunden',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textWhite.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nachrichten werden automatisch synchronisiert',
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
        
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await _loadStatistics();
          },
          color: AppTheme.secondaryGold,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return _buildMessageCard(doc).animate()
                .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                .slideX(begin: 0.1, end: 0);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildMessageCard(Map<String, dynamic> doc) {
    final collectionName = doc['collection'] ?? '';
    final config = MultiChannelService.getChannelConfig(collectionName);
    final message = MultiChannelService.formatMessage(doc);
    final mediaUrl = MultiChannelService.getMediaUrl(doc);
    final timestamp = _formatTimestamp(doc['timestamp']);
    
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(config?.color ?? AppTheme.primaryPurple.value)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  config?.icon ?? '📱',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config?.name ?? 'Unbekannt',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryGold,
                      ),
                    ),
                    Text(
                      config?.channel ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textWhite.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                timestamp,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textWhite.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Message Text (show if exists, even with media)
          if (message.isNotEmpty) ...[
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textWhite.withValues(alpha: 0.9),
                height: 1.4,
              ),
              maxLines: mediaUrl != null ? 3 : 10,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          
          // Media Preview
          if (mediaUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                mediaUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: AppTheme.surfaceDark,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, color: AppTheme.textGrey),
                    ),
                  );
                },
              ),
            ),
          ],
          
          // Action Buttons
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  // Open in Telegram
                  final channel = config?.channel?.replaceAll('@', '');
                  final messageId = doc['message_id'];
                  if (channel != null && messageId != null) {
                    launchUrl(Uri.parse('https://t.me/$channel/$messageId'));
                  }
                },
                icon: const Icon(Icons.telegram, size: 16),
                label: const Text('Telegram öffnen'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.secondaryGold,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp != null) {
        // Firestore Timestamp handling
        dateTime = (timestamp as dynamic).toDate();
      } else {
        dateTime = DateTime.now();
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 60) {
        return 'vor ${difference.inMinutes} Min';
      } else if (difference.inHours < 24) {
        return 'vor ${difference.inHours} Std';
      } else if (difference.inDays < 7) {
        return 'vor ${difference.inDays} Tagen';
      } else {
        return DateFormat('dd.MM.yyyy').format(dateTime);
      }
    } catch (e) {
      return 'Unbekannt';
    }
  }
}
