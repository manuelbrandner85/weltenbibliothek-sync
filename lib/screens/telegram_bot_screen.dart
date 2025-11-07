import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/telegram_bot_service.dart';
import '../config/app_theme.dart';

/// Telegram Bot Integration Screen
/// 
/// ✅ Funktioniert auf Web + Android
/// ✅ Zeigt alle 6 Kanäle
/// ✅ Lädt Channel-Historie
/// ✅ Bidirektionaler Chat
class TelegramBotScreen extends StatefulWidget {
  const TelegramBotScreen({super.key});

  @override
  State<TelegramBotScreen> createState() => _TelegramBotScreenState();
}

class _TelegramBotScreenState extends State<TelegramBotScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _initializeBot();
  }

  Future<void> _initializeBot() async {
    setState(() => _isLoading = true);
    
    final botService = Provider.of<TelegramBotService>(context, listen: false);
    await botService.initialize();
    
    if (botService.isInitialized) {
      // Start Polling für neue Nachrichten
      botService.startPolling();
      
      // Lade alle Kanäle
      await botService.loadAllChannels();
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Telegram Channels',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.secondaryGold,
          labelColor: AppTheme.secondaryGold,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.picture_as_pdf), text: 'PDFs'),
            Tab(icon: Icon(Icons.video_library), text: 'Videos'),
            Tab(icon: Icon(Icons.podcasts), text: 'Podcasts'),
            Tab(icon: Icon(Icons.image), text: 'Bilder'),
            Tab(icon: Icon(Icons.audiotrack), text: 'Hörbücher'),
            Tab(icon: Icon(Icons.chat), text: 'Chat'),
            Tab(icon: Icon(Icons.info), text: 'Info'),
          ],
        ),
      ),
      body: Consumer<TelegramBotService>(
        builder: (context, botService, child) {
          if (_isLoading) {
            return _buildLoadingState();
          }

          if (!botService.isInitialized) {
            return _buildConnectionError(botService.errorMessage);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildChannelView('@WeltenbibliothekPDF', botService),
              _buildChannelView('@ArchivWeltenBibliothek', botService),
              _buildChannelView('@WeltenbibliothekWachauf', botService),
              _buildChannelView('@weltenbibliothekbilder', botService),
              _buildChannelView('@WeltenbibliothekHoerbuch', botService),
              _buildChatView(botService),
              _buildInfoView(botService),
            ],
          );
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

  Widget _buildConnectionError(String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Verbindungsfehler',
              style: AppTheme.headlineMedium.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 12),
            Text(
              error ?? 'Telegram Bot konnte nicht verbunden werden.\nBitte versuche es später erneut.',
              style: AppTheme.bodyLarge.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _initializeBot,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryPurple),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.secondaryGold, size: 24),
                  const SizedBox(height: 12),
                  Text(
                    'Der Telegram-Bot ist bereits konfiguriert.\nDie App verbindet sich automatisch.',
                    style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: AppTheme.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelView(String channelUsername, TelegramBotService botService) {
    final messages = botService.channelMessages[channelUsername] ?? [];

    if (messages.isEmpty) {
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
              'Noch keine Nachrichten',
              style: AppTheme.headlineSmall.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Text(
              'Bot empfängt neue Nachrichten automatisch',
              style: AppTheme.bodySmall.copyWith(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(height: 8),
                  Text(
                    'WICHTIG: Bot muss Admin im Channel sein\n'
                    'um historische Nachrichten zu sehen',
                    style: AppTheme.bodySmall.copyWith(color: Colors.orange),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageCard(message);
      },
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final text = message['text'] ?? message['caption'] ?? '';
    final date = message['date'] != null
        ? DateTime.fromMillisecondsSinceEpoch(message['date'] * 1000)
        : DateTime.now();
    
    // Extrahiere Absender-Informationen
    final senderName = message['_sender_name'] ?? 'Unbekannt';
    final senderUsername = message['_sender_username'];
    final isFromApp = message['_is_from_app'] == true;
    final messageId = message['message_id'];
    final isEdited = message['edit_date'] != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isFromApp 
          ? AppTheme.primaryPurple.withValues(alpha: 0.2)  // Eigene Nachrichten hervorheben
          : AppTheme.surfaceDark,
      child: InkWell(
        onLongPress: isFromApp ? () => _showMessageOptions(context, message) : null,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isFromApp
                ? AppTheme.secondaryGold.withValues(alpha: 0.3)
                : AppTheme.primaryPurple.withValues(alpha: 0.3),
            child: Icon(
              isFromApp ? Icons.person : Icons.message, 
              color: AppTheme.secondaryGold,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Absender-Name
              Row(
                children: [
                  Icon(
                    Icons.account_circle, 
                    size: 16, 
                    color: AppTheme.secondaryGold,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      senderName,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.secondaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (senderUsername != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      senderUsername,
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (isEdited) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      size: 12,
                      color: Colors.white54,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // Nachrichtentext
              Text(
                text.isNotEmpty ? text : '[Medien-Nachricht]',
                style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                  style: AppTheme.bodySmall.copyWith(color: Colors.white54),
                ),
                if (isFromApp) ...[
                  const Spacer(),
                  Text(
                    'Lange drücken für Optionen',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing: _getMessageTypeIcon(message),
        ),
      ),
    );
  }
  
  void _showMessageOptions(BuildContext context, Map<String, dynamic> message) {
    final messageId = message['message_id'];
    final text = message['text'] ?? '';
    
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
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: AppTheme.secondaryGold),
              title: Text('Bearbeiten', style: AppTheme.bodyLarge.copyWith(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _editMessage(context, message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('Löschen', style: AppTheme.bodyLarge.copyWith(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(context, message);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: Colors.white54),
              title: Text('Abbrechen', style: AppTheme.bodyLarge.copyWith(color: Colors.white54)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _editMessage(BuildContext context, Map<String, dynamic> message) async {
    final messageId = message['message_id'];
    final currentText = message['text'] ?? '';
    final controller = TextEditingController(text: currentText);
    
    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Nachricht bearbeiten', style: AppTheme.headlineSmall),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Neuer Text...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: AppTheme.backgroundDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    
    if (newText != null && newText.trim().isNotEmpty && newText != currentText) {
      final botService = Provider.of<TelegramBotService>(context, listen: false);
      final success = await botService.editMessage(
        chatId: '@Weltenbibliothekchat',
        messageId: messageId,
        newText: newText.trim(),
      );
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Nachricht bearbeitet'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  Future<void> _deleteMessage(BuildContext context, Map<String, dynamic> message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Nachricht löschen?', style: AppTheme.headlineSmall),
        content: Text(
          'Diese Nachricht wird für alle gelöscht.',
          style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Abbrechen', style: TextStyle(color: Colors.white54)),
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
      final botService = Provider.of<TelegramBotService>(context, listen: false);
      final success = await botService.deleteMessage(
        chatId: '@Weltenbibliothekchat',
        messageId: message['message_id'],
      );
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Nachricht gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _getMessageTypeIcon(Map<String, dynamic> message) {
    if (message['photo'] != null) {
      return Icon(Icons.image, color: AppTheme.secondaryGold);
    } else if (message['video'] != null) {
      return Icon(Icons.videocam, color: AppTheme.secondaryGold);
    } else if (message['document'] != null) {
      return Icon(Icons.insert_drive_file, color: AppTheme.secondaryGold);
    } else if (message['audio'] != null) {
      return Icon(Icons.audiotrack, color: AppTheme.secondaryGold);
    }
    return Icon(Icons.textsms, color: AppTheme.secondaryGold);
  }

  Widget _buildChatView(TelegramBotService botService) {
    return Column(
      children: [
        Expanded(
          child: botService.chatMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.white38),
                      const SizedBox(height: 24),
                      Text(
                        'Noch keine Chat-Nachrichten',
                        style: AppTheme.headlineSmall.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  reverse: true,
                  itemCount: botService.chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = botService.chatMessages[index];
                    return _buildMessageCard(message);
                  },
                ),
        ),
        _buildChatInput(botService),
      ],
    );
  }

  Widget _buildChatInput(TelegramBotService botService) {
    final TextEditingController controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nachricht eingeben...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                filled: true,
                fillColor: AppTheme.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            backgroundColor: AppTheme.secondaryGold,
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await botService.sendMessage(
                  chatId: '@Weltenbibliothekchat',
                  text: controller.text,
                );
                controller.clear();
              }
            },
            child: const Icon(Icons.send, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoView(TelegramBotService botService) {
    final botInfo = botService.botInfo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppTheme.surfaceDark,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy, color: AppTheme.secondaryGold, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bot Information',
                              style: AppTheme.headlineSmall.copyWith(
                                color: AppTheme.secondaryGold,
                              ),
                            ),
                            if (botInfo != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '@${botInfo['username']}',
                                style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'ONLINE',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildUserNameSetting(botService),
          const SizedBox(height: 16),
          _buildChannelsList(),
          const SizedBox(height: 16),
          _buildFeaturesList(),
        ],
      ),
    );
  }
  
  Widget _buildUserNameSetting(TelegramBotService botService) {
    final TextEditingController nameController = TextEditingController(
      text: botService.currentUserName ?? '',
    );

    return Card(
      color: AppTheme.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppTheme.secondaryGold, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Dein Telegram-Name',
                  style: AppTheme.headlineSmall.copyWith(
                    color: AppTheme.secondaryGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Dieser Name wird angezeigt, wenn du Nachrichten sendest',
              style: AppTheme.bodySmall.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'z.B. Manuel Brandner',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: AppTheme.backgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.primaryPurple),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.primaryPurple),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
                      ),
                      prefixIcon: Icon(Icons.badge, color: AppTheme.secondaryGold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      botService.setCurrentUserName(name);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Name gespeichert: $name'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ Bitte einen Namen eingeben'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  child: const Text('Speichern'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryPurple),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.secondaryGold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tipp: Verwende deinen echten Telegram-Namen für bessere Erkennbarkeit',
                      style: AppTheme.bodySmall.copyWith(color: Colors.white70),
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

  Widget _buildChannelsList() {
    return Card(
      color: AppTheme.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign, color: AppTheme.secondaryGold, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Verbundene Kanäle',
                  style: AppTheme.headlineSmall.copyWith(
                    color: AppTheme.secondaryGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...TelegramBotService.targetChannels.map((channel) => _buildChannelItem(channel)),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelItem(String channel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.arrow_right, color: AppTheme.secondaryGold, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              channel,
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Card(
      color: AppTheme.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Features',
                  style: AppTheme.headlineSmall.copyWith(color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('✅ Automatisches Polling (alle 3 Sek)'),
            _buildFeatureItem('✅ Empfängt neue Channel-Posts'),
            _buildFeatureItem('✅ Bidirektionaler Chat'),
            _buildFeatureItem('✅ Web + Android kompatibel'),
            _buildFeatureItem('✅ Keine native Bibliotheken'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bot muss als Admin zu den Channels hinzugefügt werden, '
                      'um historische Nachrichten zu sehen',
                      style: AppTheme.bodySmall.copyWith(color: Colors.orange),
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

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
      ),
    );
  }
}
