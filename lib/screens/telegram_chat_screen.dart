import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/chat_sync_service.dart';
import 'package:intl/intl.dart';

/// 💬 TELEGRAM CHAT SCREEN
/// 
/// Synchronisierter Chat-Screen mit bidirektionaler Telegram-Integration
/// 
/// Features:
/// ✅ Real-time Nachrichtenanzeige
/// ✅ Nachrichten senden (App → Telegram)
/// ✅ Nachrichten bearbeiten (bidirektional)
/// ✅ Nachrichten löschen (bidirektional)
/// ✅ Telegram-Benutzernamen anzeigen
/// ✅ Medien-Vorschau (Bilder, Videos, Audio)
/// ✅ Reply-Funktion

class TelegramChatScreen extends StatefulWidget {
  const TelegramChatScreen({super.key});

  @override
  State<TelegramChatScreen> createState() => _TelegramChatScreenState();
}

class _TelegramChatScreenState extends State<TelegramChatScreen> {
  final ChatSyncService _chatService = ChatSyncService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  ChatMessage? _replyToMessage;
  ChatMessage? _editingMessage;
  
  // Demo-Benutzer (in echter App aus Auth-Service)
  final String _currentUserId = 'app_user_001';
  final String _currentUsername = 'FlutterUser';
  
  @override
  void initState() {
    super.initState();
    _chatService.initialize();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  /// Sendet eine neue Nachricht
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    
    if (text.isEmpty) return;
    
    try {
      if (_editingMessage != null) {
        // Nachricht bearbeiten
        await _chatService.editMessage(
          messageId: _editingMessage!.messageId,
          newText: text,
        );
        
        setState(() {
          _editingMessage = null;
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Nachricht bearbeitet')),
        );
      } else {
        // Neue Nachricht senden
        await _chatService.sendMessage(
          text: text,
          replyToId: _replyToMessage?.messageId,
          currentUserId: _currentUserId,
          currentUsername: _currentUsername,
        );
        
        setState(() {
          _replyToMessage = null;
        });
        
        // Scroll nach unten
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
      
      _messageController.clear();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Senden: $e');
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Fehler: $e')),
      );
    }
  }
  
  /// Löscht eine Nachricht
  Future<void> _deleteMessage(ChatMessage message) async {
    // Bestätigung anfordern
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nachricht löschen?'),
        content: const Text('Diese Nachricht wird auch aus Telegram gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      await _chatService.deleteMessage(messageId: message.messageId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Nachricht gelöscht')),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Löschen: $e');
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Fehler: $e')),
      );
    }
  }
  
  /// Bereitet Nachrichtenbearbeitung vor
  void _startEditingMessage(ChatMessage message) {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.text;
      _replyToMessage = null;
    });
  }
  
  /// Bricht Bearbeitung ab
  void _cancelEditing() {
    setState(() {
      _editingMessage = null;
      _messageController.clear();
    });
  }
  
  /// Zeigt Nachrichtenoptionen
  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.source == 'app') ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Bearbeiten'),
                onTap: () {
                  Navigator.pop(context);
                  _startEditingMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Löschen', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Antworten'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyToMessage = message;
                  _editingMessage = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weltenbibliothek Chat'),
            Text(
              '@Weltenbibliothekchat',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('🔄 Bidirektionale Synchronisation'),
                  content: const Text(
                    'Dieser Chat ist mit Telegram synchronisiert:\n\n'
                    '✅ Nachrichten aus App → Telegram\n'
                    '✅ Nachrichten aus Telegram → App\n'
                    '✅ Bearbeitungen werden synchronisiert\n'
                    '✅ Löschungen werden synchronisiert\n'
                    '🗑️ Auto-Löschung nach 24 Stunden'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Nachrichten-Liste
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Fehler: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
                  );
                }
                
                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Noch keine Nachrichten'),
                        SizedBox(height: 8),
                        Text(
                          'Schreibe die erste Nachricht!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOwnMessage = message.source == 'app' && 
                                        message.appUserId == _currentUserId;
                    
                    return _MessageBubble(
                      message: message,
                      isOwnMessage: isOwnMessage,
                      onLongPress: () => _showMessageOptions(message),
                    );
                  },
                );
              },
            ),
          ),
          
          // Reply-Vorschau
          if (_replyToMessage != null)
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antwort an ${_replyToMessage!.displayName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _replyToMessage!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _replyToMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          
          // Edit-Modus Indikator
          if (_editingMessage != null)
            Container(
              color: Colors.orange[100],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 20, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Nachricht bearbeiten',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: _cancelEditing,
                    child: const Text('Abbrechen'),
                  ),
                ],
              ),
            ),
          
          // Eingabefeld
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _editingMessage != null 
                            ? 'Nachricht bearbeiten...'
                            : 'Nachricht schreiben...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    mini: true,
                    child: Icon(
                      _editingMessage != null ? Icons.check : Icons.send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nachrichtenblase Widget
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isOwnMessage;
  final VoidCallback onLongPress;
  
  const _MessageBubble({
    required this.message,
    required this.isOwnMessage,
    required this.onLongPress,
  });
  
  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    
    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            color: isOwnMessage 
                ? Colors.blue[100] 
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Absender-Name (nur bei fremden Nachrichten)
              if (!isOwnMessage)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              
              // Medien-Vorschau
              if (message.hasMedia)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MediaPreview(message: message),
                ),
              
              // Nachrichtentext
              if (message.text.isNotEmpty)
                Text(message.text),
              
              // Zeitstempel und Status
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.edited)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Text(
                        'bearbeitet',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  Text(
                    message.timestamp != null 
                        ? timeFormat.format(message.timestamp!)
                        : 'Sende...',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  if (isOwnMessage) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.syncedToTelegram == true 
                          ? Icons.done_all 
                          : Icons.done,
                      size: 14,
                      color: message.syncedToTelegram == true 
                          ? Colors.blue 
                          : Colors.grey,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Medien-Vorschau Widget
class _MediaPreview extends StatelessWidget {
  final ChatMessage message;
  
  const _MediaPreview({required this.message});
  
  @override
  Widget build(BuildContext context) {
    if (!message.hasMedia) return const SizedBox.shrink();
    
    final mediaType = message.mediaType ?? 'unknown';
    
    switch (mediaType) {
      case 'photo':
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.mediaUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 150,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 48, color: Colors.grey),
                ),
              );
            },
          ),
        );
      
      case 'video':
        return Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.play_circle_filled, size: 64, color: Colors.white),
          ),
        );
      
      case 'audio':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.audiotrack),
              SizedBox(width: 8),
              Text('Audio-Datei'),
            ],
          ),
        );
      
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.attach_file),
              SizedBox(width: 8),
              Text('Datei'),
            ],
          ),
        );
    }
  }
}
