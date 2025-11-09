import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/telegram_bot_service.dart';
import '../config/app_theme.dart';
import 'telegram_chat_screen.dart';
import 'telegram_category_screen.dart';
import 'telegram_main_screen.dart';

/// Vereinheitlichter Telegram Screen - Alle Chats an einem Ort
/// 
/// Zeigt:
/// 1. Live Chat (bidirektional)
/// 2. Alle Kategorie-Kanäle als Chat-Liste
/// 3. Lade-Statistiken für jeden Kanal
class TelegramUnifiedScreen extends StatefulWidget {
  const TelegramUnifiedScreen({super.key});

  @override
  State<TelegramUnifiedScreen> createState() => _TelegramUnifiedScreenState();
}

class _TelegramUnifiedScreenState extends State<TelegramUnifiedScreen> {
  bool _isLoading = false;
  bool _isInitialized = false;

  // ✅ KORRIGIERTE TELEGRAM-KANÄLE (v2.24.0)
  // Alle historischen + zukünftigen Nachrichten werden synchronisiert
  // Chat-Nachrichten werden nach 24h automatisch gelöscht
  final List<ChannelInfo> _channels = [
    // 🔴 LIVE CHAT - Bidirektionale Kommunikation
    // https://t.me/Weltenbibliothekchat
    // Auto-Delete: 24 Stunden
    ChannelInfo(
      username: '@Weltenbibliothekchat',
      title: 'Live Chat',
      description: 'Bidirektionaler Community-Chat',
      icon: Icons.chat_bubble,
      color: AppTheme.primaryPurple,
      type: ChannelType.chat,
      autoDelete: true, // 24h Auto-Delete
    ),
    
    // 📄 PDFs - Dokumente & Schriften
    // https://t.me/WeltenbibliothekPDF
    ChannelInfo(
      username: '@WeltenbibliothekPDF',
      title: 'PDFs',
      description: 'Dokumente & Schriften',
      icon: Icons.picture_as_pdf,
      color: Colors.red,
      type: ChannelType.category,
      mediaType: MediaType.pdf,
    ),
    
    // 🖼️ BILDER - Foto-Galerie
    // https://t.me/weltenbibliothekbilder
    ChannelInfo(
      username: '@weltenbibliothekbilder',
      title: 'Bilder',
      description: 'Foto-Galerie',
      icon: Icons.image,
      color: Colors.green,
      type: ChannelType.category,
      mediaType: MediaType.image,
    ),
    
    // 🎙️ PODCASTS - Audio-Vorträge
    // https://t.me/WeltenbibliothekWachauf
    ChannelInfo(
      username: '@WeltenbibliothekWachauf',
      title: 'Podcasts',
      description: 'Audio-Vorträge',
      icon: Icons.podcasts,
      color: Colors.orange,
      type: ChannelType.category,
      mediaType: MediaType.audio,
    ),
    
    // 🎬 VIDEOS - Video-Archive
    // https://t.me/ArchivWeltenBibliothek
    ChannelInfo(
      username: '@ArchivWeltenBibliothek',
      title: 'Videos',
      description: 'Video-Archive',
      icon: Icons.video_library,
      color: Colors.blue,
      type: ChannelType.category,
      mediaType: MediaType.video,
    ),
    
    // 📖 HÖRBÜCHER - Hörbuch-Sammlung
    // https://t.me/WeltenbibliothekHoerbuch
    ChannelInfo(
      username: '@WeltenbibliothekHoerbuch',
      title: 'Hörbücher',
      description: 'Hörbuch-Sammlung',
      icon: Icons.audiotrack,
      color: Colors.purple,
      type: ChannelType.category,
      mediaType: MediaType.audio,
    ),
  ];

  Map<String, int> _messageCounts = {};

  @override
  void initState() {
    super.initState();
    _initializeAndLoadAll();
  }

  Future<void> _initializeAndLoadAll() async {
    setState(() => _isLoading = true);
    
    final botService = Provider.of<TelegramBotService>(context, listen: false);
    
    // Initialisiere Bot wenn nötig
    if (!botService.isInitialized) {
      await botService.initialize();
    }
    
    if (botService.isInitialized) {
      // Starte Polling
      if (!botService.isPolling) {
        botService.startPolling();
      }
      
      // Lade alle Kanäle
      await botService.loadAllChannels();
      
      // Lade Message Counts für jeden Kanal
      for (var channel in _channels) {
        final messages = await botService.loadChannelHistory(
          channelUsername: channel.username,
          limit: 200,
        );
        _messageCounts[channel.username] = messages.length;
      }
      
      setState(() => _isInitialized = true);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icon/icon.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.library_books,
                color: AppTheme.secondaryGold,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Telegram Chats',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeAndLoadAll,
            tooltip: 'Neu laden',
          ),
        ],
      ),
      body: Consumer<TelegramBotService>(
        builder: (context, botService, child) {
          if (_isLoading) {
            return _buildLoadingState();
          }

          if (!_isInitialized || !botService.isInitialized) {
            return _buildErrorState(botService.errorMessage);
          }

          return _buildChatList(botService);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.secondaryGold),
          const SizedBox(height: 24),
          Text(
            'Lade Telegram Chats...',
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Verbinde mit Bot & lade Kanäle',
            style: AppTheme.bodySmall.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              'Verbindungsfehler',
              style: AppTheme.headlineMedium.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 12),
            Text(
              error ?? 'Telegram Bot konnte nicht verbunden werden.',
              style: AppTheme.bodyLarge.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _initializeAndLoadAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGold,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(TelegramBotService botService) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status Card
        _buildStatusCard(botService),
        
        const SizedBox(height: 24),
        
        // Chat List Header
        Row(
          children: [
            const Icon(Icons.forum, color: AppTheme.secondaryGold, size: 24),
            const SizedBox(width: 8),
            Text(
              'Alle Chats',
              style: AppTheme.headlineMedium.copyWith(
                color: AppTheme.secondaryGold,
              ),
            ),
            const Spacer(),
            Text(
              '${_channels.length} Kanäle',
              style: AppTheme.bodySmall.copyWith(color: Colors.white54),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Chat Cards
        ..._channels.map((channel) => _buildChatCard(channel, botService)),
      ],
    );
  }

  Widget _buildStatusCard(TelegramBotService botService) {
    final totalMessages = _messageCounts.values.fold<int>(0, (sum, count) => sum + count);
    
    return Card(
      color: AppTheme.surfaceDark,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Telegram Verbunden',
                        style: AppTheme.bodyLarge.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (botService.botInfo != null)
                        Text(
                          '@${botService.botInfo!['username']}',
                          style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                        ),
                    ],
                  ),
                ),
                Icon(
                  botService.isPolling ? Icons.sync : Icons.sync_disabled,
                  color: botService.isPolling ? AppTheme.secondaryGold : Colors.white38,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            
            // Statistiken
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.forum,
                  label: 'Kanäle',
                  value: '${_channels.length}',
                  color: AppTheme.primaryPurple,
                ),
                Container(width: 1, height: 40, color: Colors.white12),
                _buildStatItem(
                  icon: Icons.message,
                  label: 'Nachrichten',
                  value: '$totalMessages',
                  color: AppTheme.secondaryGold,
                ),
                Container(width: 1, height: 40, color: Colors.white12),
                _buildStatItem(
                  icon: Icons.update,
                  label: 'Echtzeit',
                  value: botService.isPolling ? 'Aktiv' : 'Aus',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildChatCard(ChannelInfo channel, TelegramBotService botService) {
    final messageCount = _messageCounts[channel.username] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceDark,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: channel.color.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () {
          if (channel.type == ChannelType.chat) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TelegramChatScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TelegramCategoryScreen(
                  channelUsername: channel.username,
                  channelTitle: channel.title,
                  categoryType: channel.mediaType!,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: channel.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: channel.color.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Icon(channel.icon, color: channel.color, size: 32),
              ),
              
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            channel.title,
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (channel.type == ChannelType.chat)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, color: Colors.green, size: 8),
                                const SizedBox(width: 4),
                                Text(
                                  'Live',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      channel.description,
                      style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.message_outlined, size: 14, color: channel.color),
                        const SizedBox(width: 4),
                        Text(
                          messageCount > 0 
                              ? '$messageCount ${messageCount == 1 ? "Nachricht" : "Nachrichten"}'
                              : 'Noch keine Nachrichten',
                          style: AppTheme.bodySmall.copyWith(
                            color: channel.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Arrow
              Icon(
                Icons.chevron_right,
                color: AppTheme.secondaryGold,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ChannelType {
  chat,
  category,
}

class ChannelInfo {
  final String username;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final ChannelType type;
  final MediaType? mediaType;
  final bool autoDelete; // 24h Auto-Delete für Chat

  ChannelInfo({
    required this.username,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
    this.mediaType,
    this.autoDelete = false, // Default: Keine Auto-Delete
  });
}
