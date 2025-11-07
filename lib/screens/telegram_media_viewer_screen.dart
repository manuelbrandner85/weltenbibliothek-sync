import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../services/telegram_embed_service.dart';

/// v2.30.0 - Telegram Media Viewer mit Web Embed
/// 
/// Zeigt Telegram-Posts direkt als Web-Embed an - genau wie bei Telegram!
/// Unterstützt: Videos, PDFs, Bilder, Audio (Hörbücher, Podcasts)
class TelegramMediaViewerScreen extends StatefulWidget {
  final Map<String, dynamic> mediaData;
  final String mediaType; // 'video', 'pdf', 'image', 'audio'

  const TelegramMediaViewerScreen({
    super.key,
    required this.mediaData,
    required this.mediaType,
  });

  @override
  State<TelegramMediaViewerScreen> createState() => _TelegramMediaViewerScreenState();
}

class _TelegramMediaViewerScreenState extends State<TelegramMediaViewerScreen> {
  final TelegramEmbedService _embedService = TelegramEmbedService();
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _telegramUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeTelegramEmbed();
  }

  void _initializeTelegramEmbed() {
    try {
      // Konstruiere Telegram URL
      _telegramUrl = _embedService.constructTelegramUrl(widget.mediaData);
      
      if (_telegramUrl == null) {
        setState(() {
          _error = 'Telegram-Link konnte nicht erstellt werden';
          _isLoading = false;
        });
        return;
      }

      // Initialisiere WebView Controller
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (kDebugMode) {
                debugPrint('🔄 Lade Telegram Post: $url');
              }
            },
            onPageFinished: (String url) {
              setState(() => _isLoading = false);
              if (kDebugMode) {
                debugPrint('✅ Telegram Post geladen: $url');
              }
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _error = 'Fehler beim Laden: ${error.description}';
                _isLoading = false;
              });
              if (kDebugMode) {
                debugPrint('❌ WebView Fehler: ${error.description}');
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(_telegramUrl!));

    } catch (e) {
      setState(() {
        _error = 'Fehler bei Initialisierung: $e';
        _isLoading = false;
      });
      if (kDebugMode) {
        debugPrint('❌ Fehler: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _embedService.getDisplayName(widget.mediaData);
    final description = _embedService.getDescription(widget.mediaData);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryPurple,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.mediaData['channel_username'] != null)
              Text(
                widget.mediaData['channel_username'],
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          if (_telegramUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_browser, color: AppTheme.secondaryGold),
              tooltip: 'In Telegram öffnen',
              onPressed: () => _openInTelegram(),
            ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareMedia(),
          ),
        ],
      ),
      body: _buildContent(description),
    );
  }

  Widget _buildContent(String description) {
    if (_error != null) {
      return _buildErrorView();
    }

    return Column(
      children: [
        // Telegram Embed WebView
        Expanded(
          child: Stack(
            children: [
              if (_telegramUrl != null)
                WebViewWidget(controller: _webViewController),
              if (_isLoading)
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.secondaryGold),
                      SizedBox(height: 16),
                      Text(
                        'Lade Telegram-Inhalt...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Beschreibung (Original Telegram Caption)
        if (description.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.description, color: AppTheme.secondaryGold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Beschreibung',
                      style: TextStyle(
                        color: AppTheme.secondaryGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_telegramUrl != null)
              ElevatedButton.icon(
                onPressed: () => _openInTelegram(),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('In Telegram öffnen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInTelegram() async {
    if (_telegramUrl == null) return;
    
    final uri = Uri.parse(_telegramUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telegram konnte nicht geöffnet werden')),
        );
      }
    }
  }

  Future<void> _shareMedia() async {
    if (_telegramUrl == null) return;
    
    // TODO: Implementiere Share-Funktionalität
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link: $_telegramUrl'),
          action: SnackBarAction(
            label: 'Kopieren',
            onPressed: () {
              // TODO: In Zwischenablage kopieren
            },
          ),
        ),
      );
    }
  }
}
