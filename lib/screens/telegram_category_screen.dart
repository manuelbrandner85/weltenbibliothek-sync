import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/telegram_bot_service.dart';
import '../config/app_theme.dart';
import 'telegram_main_screen.dart';

/// Telegram Category Screen - Historische Inhalte
/// 
/// Zeigt historische Inhalte aus Channels:
/// - PDFs, Videos, Podcasts, Bilder, Hörbücher
/// - Lädt ALLE historischen Nachrichten via MadelineProto
class TelegramCategoryScreen extends StatefulWidget {
  final String channelUsername;
  final String channelTitle;
  final MediaType categoryType;

  const TelegramCategoryScreen({
    super.key,
    required this.channelUsername,
    required this.channelTitle,
    required this.categoryType,
  });

  @override
  State<TelegramCategoryScreen> createState() => _TelegramCategoryScreenState();
}

class _TelegramCategoryScreenState extends State<TelegramCategoryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    final botService = Provider.of<TelegramBotService>(context, listen: false);
    final messages = await botService.loadChannelHistory(
      channelUsername: widget.channelUsername,
      limit: 200,
    );
    
    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            _getCategoryIcon(),
            const SizedBox(width: 12),
            Text(
              widget.channelTitle,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _getCategoryIcon() {
    switch (widget.categoryType) {
      case MediaType.pdf:
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case MediaType.video:
        return const Icon(Icons.video_library, color: Colors.blue);
      case MediaType.audio:
        return const Icon(Icons.audiotrack, color: Colors.orange);
      case MediaType.image:
        return const Icon(Icons.image, color: Colors.green);
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.secondaryGold),
            const SizedBox(height: 24),
            Text(
              'Lade historische Inhalte...',
              style: AppTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 80,
              color: Colors.white38,
            ),
            const SizedBox(height: 24),
            Text(
              'Keine Inhalte gefunden',
              style: AppTheme.headlineSmall.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Text(
              'Bot empfängt neue Inhalte automatisch',
              style: AppTheme.bodySmall.copyWith(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGold,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Neu laden'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildContentCard(message);
      },
    );
  }

  Widget _buildContentCard(Map<String, dynamic> message) {
    final text = message['text'] ?? message['caption'] ?? '';
    final date = message['date'] != null
        ? DateTime.fromMillisecondsSinceEpoch(message['date'] * 1000)
        : DateTime.now();
    final senderName = message['_sender_name'] ?? widget.channelTitle;
    final hasMedia = _hasMedia(message);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: AppTheme.surfaceDark,
      child: InkWell(
        onTap: hasMedia ? () => _showMediaDetails(message) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  _getCategoryIcon(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      senderName,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.secondaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${date.day}.${date.month}.${date.year}',
                    style: AppTheme.bodySmall.copyWith(color: Colors.white54),
                  ),
                ],
              ),
              
              if (text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  text,
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              if (hasMedia) ...[
                const SizedBox(height: 12),
                _buildMediaPreview(message),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _hasMedia(Map<String, dynamic> message) {
    return message['photo'] != null ||
        message['video'] != null ||
        message['document'] != null ||
        message['audio'] != null;
  }

  Widget _buildMediaPreview(Map<String, dynamic> message) {
    IconData icon;
    String label;
    Color color;

    if (message['photo'] != null) {
      icon = Icons.image;
      label = 'Foto';
      color = Colors.green;
    } else if (message['video'] != null) {
      icon = Icons.videocam;
      label = 'Video';
      color = Colors.blue;
    } else if (message['document'] != null) {
      icon = Icons.insert_drive_file;
      label = 'Dokument';
      color = Colors.red;
    } else if (message['audio'] != null) {
      icon = Icons.audiotrack;
      label = 'Audio';
      color = Colors.orange;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.download, color: color, size: 16),
        ],
      ),
    );
  }

  void _showMediaDetails(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medien-Details',
              style: AppTheme.headlineSmall.copyWith(color: AppTheme.secondaryGold),
            ),
            const SizedBox(height: 16),
            
            if (message['text'] != null) ...[
              Text(
                'Beschreibung:',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message['text'],
                style: AppTheme.bodyMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
            ],
            
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Download-Funktion in Entwicklung'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGold,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
              ),
              icon: const Icon(Icons.download),
              label: const Text('In Telegram öffnen'),
            ),
          ],
        ),
      ),
    );
  }
}
