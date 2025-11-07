import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/telegram_bot_service.dart';
import '../config/app_theme.dart';

/// Telegram Chat Screen - Bidirektionaler Chat
/// 
/// Features:
/// - Nachrichten senden
/// - Nachrichten bearbeiten (eigene)
/// - Nachrichten löschen (eigene)
/// - Echtzeit-Synchronisation mit Telegram
class TelegramChatScreen extends StatefulWidget {
  final String channelUsername;
  final String channelTitle;

  const TelegramChatScreen({
    super.key,
    required this.channelUsername,
    required this.channelTitle,
  });

  @override
  State<TelegramChatScreen> createState() => _TelegramChatScreenState();
}

class _TelegramChatScreenState extends State<TelegramChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          widget.channelTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<TelegramBotService>(
        builder: (context, botService, child) {
          final messages = botService.chatMessages;

          return Column(
            children: [
              // Messages List
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessageBubble(message, botService);
                        },
                      ),
              ),
              
              // Input Field
              _buildMessageInput(botService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.white38),
          const SizedBox(height: 24),
          Text(
            'Noch keine Nachrichten',
            style: AppTheme.headlineSmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'Sende die erste Nachricht!',
            style: AppTheme.bodySmall.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, TelegramBotService botService) {
    final text = message['text'] ?? '';
    final senderName = message['_sender_name'] ?? 'Unbekannt';
    final isFromApp = message['_is_from_app'] == true;
    final messageId = message['message_id'];
    final date = message['date'] != null
        ? DateTime.fromMillisecondsSinceEpoch(message['date'] * 1000)
        : DateTime.now();

    return Align(
      alignment: isFromApp ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: InkWell(
          onLongPress: isFromApp ? () => _showMessageOptions(message, botService) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFromApp
                  ? AppTheme.secondaryGold.withValues(alpha: 0.3)
                  : AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFromApp 
                    ? AppTheme.secondaryGold
                    : AppTheme.primaryPurple.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender Name
                Row(
                  children: [
                    Icon(
                      isFromApp ? Icons.person : Icons.account_circle,
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Message Text
                Text(
                  text,
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                ),
                
                const SizedBox(height: 8),
                
                // Time
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                      style: AppTheme.bodySmall.copyWith(color: Colors.white54),
                    ),
                    if (isFromApp) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Lange drücken',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(TelegramBotService botService) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
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
              final text = _messageController.text.trim();
              if (text.isNotEmpty) {
                await botService.sendMessage(
                  chatId: widget.channelUsername,
                  text: text,
                );
                _messageController.clear();
              }
            },
            child: const Icon(Icons.send, color: Colors.black),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> message, TelegramBotService botService) {
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
                _editMessage(message, botService);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('Löschen', style: AppTheme.bodyLarge.copyWith(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message, botService);
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

  Future<void> _editMessage(Map<String, dynamic> message, TelegramBotService botService) async {
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
          autofocus: true,
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
      final success = await botService.editMessage(
        chatId: widget.channelUsername,
        messageId: message['message_id'],
        newText: newText.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ Nachricht bearbeitet' : '❌ Bearbeitung fehlgeschlagen'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(Map<String, dynamic> message, TelegramBotService botService) async {
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
      final success = await botService.deleteMessage(
        chatId: widget.channelUsername,
        messageId: message['message_id'],
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ Nachricht gelöscht' : '❌ Löschen fehlgeschlagen'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
