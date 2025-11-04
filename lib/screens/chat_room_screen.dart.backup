import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import 'user_profile_screen.dart';

/// Chat Room Screen - zeigt Nachrichten und ermöglicht Senden
class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomScreen({
    super.key,
    required this.chatRoom,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _joinChatRoom();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _joinChatRoom() async {
    try {
      await _chatService.joinChatRoom(widget.chatRoom.id);
    } catch (e) {
      // Fehler ignorieren wenn bereits Mitglied
    }
  }

  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(widget.chatRoom.id);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(
        chatRoomId: widget.chatRoom.id,
        text: text,
      );

      _messageController.clear();
      
      // Scroll nach unten
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Senden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryPurple,
                    AppTheme.secondaryGold,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.chatRoom.name.substring(0, 2).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatRoom.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.chatRoom.participants.length} Teilnehmer',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              _showChatInfo();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.chatRoom.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.secondaryGold),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Fehler beim Laden der Nachrichten',
                      style: AppTheme.bodyMedium.copyWith(color: Colors.red),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Noch keine Nachrichten',
                          style: AppTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Starte die Unterhaltung!',
                          style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _chatService.currentUserId;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () {
                // NEU: Tap auf Avatar öffnet Profil
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(
                      userId: message.senderId,
                      userName: message.senderName,
                      userAvatar: message.senderAvatar,
                    ),
                  ),
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple,
                      AppTheme.secondaryGold,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    message.senderName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              // NEU: Long press zum Löschen (nur eigene Nachrichten)
              onLongPress: isMe ? () => _showDeleteDialog(message) : null,
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isMe
                      ? [
                          AppTheme.primaryPurple,
                          AppTheme.primaryPurple.withOpacity(0.8),
                        ]
                      : [
                          AppTheme.surfaceDark,
                          AppTheme.surfaceDark.withOpacity(0.8),
                        ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe
                    ? null
                    : Border.all(
                        color: AppTheme.primaryPurple.withOpacity(0.3),
                        width: 1,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          color: AppTheme.secondaryGold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.timeFormatted,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // NEU: Dialog zum Löschen von Nachrichten
  void _showDeleteDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Nachricht löschen',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Möchtest du diese Nachricht wirklich löschen?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMessage(message);
            },
            child: const Text(
              'Löschen',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // NEU: Nachricht löschen
  Future<void> _deleteMessage(ChatMessage message) async {
    try {
      await _chatService.deleteMessage(
        chatRoomId: widget.chatRoom.id,
        messageId: message.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Nachricht gelöscht'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryPurple.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nachricht schreiben...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryPurple,
                    AppTheme.secondaryGold,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSending ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.chatRoom.name,
                style: AppTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.chatRoom.description,
                style: AppTheme.bodyMedium.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _buildInfoRow(
                Icons.people,
                '${widget.chatRoom.participants.length} Teilnehmer',
              ),
              _buildInfoRow(
                Icons.access_time,
                'Erstellt: ${widget.chatRoom.createdAt.day}.${widget.chatRoom.createdAt.month}.${widget.chatRoom.createdAt.year}',
              ),
              _buildInfoRow(
                Icons.chat_bubble,
                widget.chatRoom.type == ChatRoomType.community
                    ? 'Community-Chat'
                    : 'Gruppen-Chat',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondaryGold, size: 20),
          const SizedBox(width: 12),
          Text(text, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }
}
