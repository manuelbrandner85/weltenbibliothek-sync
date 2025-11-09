import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/telegram_bot_service.dart';
import '../config/app_theme.dart';
import 'telegram_chat_screen.dart';
import 'telegram_category_screen.dart';

/// Telegram Hauptmenü Screen
/// 
/// Zeigt:
/// 1. Live Chat (@Weltenbibliothekchat)
/// 2. Kategorien: PDFs, Videos, Podcasts, Bilder, Hörbücher
class TelegramMainScreen extends StatefulWidget {
  const TelegramMainScreen({super.key});

  @override
  State<TelegramMainScreen> createState() => _TelegramMainScreenState();
}

class _TelegramMainScreenState extends State<TelegramMainScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeBot();
  }

  Future<void> _initializeBot() async {
    setState(() => _isLoading = true);
    
    final botService = Provider.of<TelegramBotService>(context, listen: false);
    await botService.initialize();
    
    if (botService.isInitialized) {
      botService.startPolling();
      await botService.loadAllChannels();
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
        title: const Text(
          'Weltenbibliothek Telegram',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<TelegramBotService>(
        builder: (context, botService, child) {
          if (_isLoading) {
            return _buildLoadingState();
          }

          if (!botService.isInitialized) {
            return _buildErrorState(botService.errorMessage);
          }

          return _buildMainMenu(botService);
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
            'Verbinde mit Telegram...',
            style: AppTheme.bodyLarge,
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
              onPressed: _initializeBot,
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

  Widget _buildMainMenu(TelegramBotService botService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot Status
          Card(
            color: AppTheme.surfaceDark,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verbunden',
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
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Live Chat
          Text(
            'Live Chat',
            style: AppTheme.headlineMedium.copyWith(color: AppTheme.secondaryGold),
          ),
          const SizedBox(height: 12),
          
          _buildMenuCard(
            icon: Icons.chat_bubble,
            title: 'Weltenbibliothekchat',
            subtitle: 'Live-Chat mit der Community (Bidirektionale Sync)',
            color: AppTheme.primaryPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TelegramChatScreen(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Kategorien
          Text(
            'Kategorien',
            style: AppTheme.headlineMedium.copyWith(color: AppTheme.secondaryGold),
          ),
          const SizedBox(height: 12),
          
          _buildMenuCard(
            icon: Icons.picture_as_pdf,
            title: 'PDFs',
            subtitle: 'Dokumenten-Bibliothek',
            color: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelegramCategoryScreen(
                    channelUsername: '@WeltenbibliothekPDF',
                    channelTitle: 'PDFs',
                    categoryType: MediaType.pdf,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildMenuCard(
            icon: Icons.video_library,
            title: 'Videos',
            subtitle: 'Video-Archiv',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelegramCategoryScreen(
                    channelUsername: '@ArchivWeltenBibliothek',
                    channelTitle: 'Videos',
                    categoryType: MediaType.video,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildMenuCard(
            icon: Icons.podcasts,
            title: 'Podcasts',
            subtitle: 'Podcast-Sammlung',
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelegramCategoryScreen(
                    channelUsername: '@WeltenbibliothekWachauf',
                    channelTitle: 'Podcasts',
                    categoryType: MediaType.audio,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildMenuCard(
            icon: Icons.image,
            title: 'Bilder',
            subtitle: 'Bild-Galerie',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelegramCategoryScreen(
                    channelUsername: '@weltenbibliothekbilder',
                    channelTitle: 'Bilder',
                    categoryType: MediaType.image,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildMenuCard(
            icon: Icons.audiotrack,
            title: 'Hörbücher',
            subtitle: 'Hörbuch-Sammlung',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelegramCategoryScreen(
                    channelUsername: '@WeltenbibliothekHoerbuch',
                    channelTitle: 'Hörbücher',
                    categoryType: MediaType.audio,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppTheme.surfaceDark,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.secondaryGold),
            ],
          ),
        ),
      ),
    );
  }
}

enum MediaType {
  pdf,
  video,
  audio,
  image,
}
