import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_theme.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../services/typing_indicator_service.dart';
import '../services/voice_message_service.dart';
import '../services/admin_service.dart';
import '../widgets/enhanced_message_bubble.dart';
import '../widgets/typing_indicator_widget.dart';
import '../widgets/pinned_messages_bar.dart';
import '../widgets/message_search_bar.dart';
import '../widgets/message_action_sheet.dart';
import '../widgets/simple_voice_recorder.dart';
import 'user_profile_screen.dart';

/// Complete Chat Room Screen mit ALLEN Phase 5 Features
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
  final TypingIndicatorService _typingService = TypingIndicatorService();
  final VoiceMessageService _voiceService = VoiceMessageService();
  final AdminService _adminService = AdminService();
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isSending = false;
  bool _showScrollToBottom = false;
  bool _isSearching = false;
  bool _isRecordingVoice = false;
  ChatMessage? _replyingTo;
  ChatMessage? _editingMessage;
  
  @override
  void initState() {
    super.initState();
    _joinChatRoom();
    _markMessagesAsRead();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingService.setTyping(widget.chatRoom.id, false);
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 300;
      if (shouldShow != _showScrollToBottom) {
        setState(() => _showScrollToBottom = shouldShow);
      }
    });
  }

  Future<void> _joinChatRoom() async {
    try {
      await _chatService.joinChatRoom(widget.chatRoom.id);
    } catch (e) {
      // Ignore if already member
    }
  }

  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(widget.chatRoom.id);
  }

  void _onTextChanged(String text) {
    // Set typing indicator
    if (text.isNotEmpty) {
      _typingService.setTyping(widget.chatRoom.id, true);
    } else {
      _typingService.setTyping(widget.chatRoom.id, false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      if (_editingMessage != null) {
        // Edit existing message
        await _chatService.editMessage(
          chatRoomId: widget.chatRoom.id,
          messageId: _editingMessage!.id,
          newText: text,
        );
        setState(() => _editingMessage = null);
      } else if (_replyingTo != null) {
        // Send reply
        await _chatService.sendReply(
          chatRoomId: widget.chatRoom.id,
          text: text,
          replyToMessageId: _replyingTo!.id,
          replyToText: _replyingTo!.text,
          replyToSenderName: _replyingTo!.senderName,
        );
        setState(() => _replyingTo = null);
      } else {
        // Normal message
        await _chatService.sendMessage(
          chatRoomId: widget.chatRoom.id,
          text: text,
        );
      }

      _messageController.clear();
      _typingService.setTyping(widget.chatRoom.id, false);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
      if (animated) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(0);
      }
    }
  }

  // ========== IMAGE HANDLING ==========
  
  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      final imageUrl = await _chatService.uploadImage(
        image.path,
        widget.chatRoom.id,
      );

      await _chatService.sendImageMessage(
        chatRoomId: widget.chatRoom.id,
        imageUrl: imageUrl,
        text: '📸 Bild',
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Bild gesendet'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bild auswählen', style: AppTheme.headlineMedium),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.secondaryGold),
                title: const Text('Kamera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.secondaryGold),
                title: const Text('Galerie', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== VOICE MESSAGE HANDLING ==========
  
  Future<void> _handleVoiceMessageSent(String audioPath, int duration) async {
    try {
      // Upload audio
      final audioUrl = await _voiceService.uploadAudio(audioPath, widget.chatRoom.id);
      
      // Send voice message
      await _voiceService.sendVoiceMessage(
        chatRoomId: widget.chatRoom.id,
        audioUrl: audioUrl,
        duration: duration,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Sprachnachricht gesendet'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ========== MESSAGE ACTIONS ==========
  
  void _handleMessageLongPress(ChatMessage message) async {
    final isMe = message.senderId == _chatService.currentUserId;
    final currentUserId = _chatService.currentUserId ?? '';
    
    // Check Moderator/Admin Rights
    final hasModerationRights = await _adminService.hasModeratorRights(currentUserId);
    final isSuperAdmin = await _adminService.isSuperAdmin(currentUserId);
    
    if (!mounted) return;
    
    MessageActionSheet.show(
      context: context,
      message: message,
      isOwnMessage: isMe,
      isModerator: hasModerationRights,
      isSuperAdmin: isSuperAdmin,
      onReply: () => setState(() => _replyingTo = message),
      onEdit: () => _startEdit(message),
      onPin: () => _togglePin(message),
      onForward: () => _forwardMessage(message),
      onReport: () => _reportMessage(message),
      onDelete: () => _deleteMessageAsModerator(message, hasModerationRights),
      onMuteUser: hasModerationRights && !isMe ? () => _muteUser(message.senderId) : null,
      onBlockUser: isSuperAdmin && !isMe ? () => _blockUser(message.senderId) : null,
    );
  }

  void _startEdit(ChatMessage message) {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.text;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
      _messageController.clear();
    });
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  Future<void> _togglePin(ChatMessage message) async {
    try {
      await _chatService.togglePinMessage(
        chatRoomId: widget.chatRoom.id,
        messageId: message.id,
        isPinned: !message.isPinned,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isPinned ? '✓ Nachricht entfernt' : '✓ Nachricht angepinnt'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _forwardMessage(ChatMessage message) async {
    // Show chat selection dialog
    final chatRooms = await _chatService.getChatRoomsOnce();
    
    if (!mounted) return;
    
    final selectedChatRoom = await showDialog<ChatRoom>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Weiterleiten an', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final room = chatRooms[index];
              if (room.id == widget.chatRoom.id) return const SizedBox();
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryPurple,
                  child: Text(
                    room.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(room.name, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, room),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
    
    if (selectedChatRoom == null) return;
    
    try {
      await _chatService.forwardMessage(
        targetChatRoomId: selectedChatRoom.id,
        originalMessage: message,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Nachricht weitergeleitet'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reportMessage(ChatMessage message) async {
    final reasons = [
      'Spam oder Werbung',
      'Belästigung',
      'Hassrede',
      'Gewaltdarstellung',
      'Falschinformationen',
      'Sonstiges',
    ];
    
    final selectedReason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Nachricht melden', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons.map((reason) => ListTile(
            title: Text(reason, style: const TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context, reason),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
    
    if (selectedReason == null) return;
    
    try {
      await _chatService.reportMessage(
        chatRoomId: widget.chatRoom.id,
        messageId: message.id,
        reason: selectedReason,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Nachricht gemeldet'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Nachricht löschen', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Möchtest du diese Nachricht wirklich löschen?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ========== MODERATOR ACTIONS ==========
  
  Future<void> _deleteMessageAsModerator(ChatMessage message, bool isModerator) async {
    final isOwnMessage = message.senderId == _chatService.currentUserId;
    
    if (isOwnMessage) {
      // Eigene Nachricht - normale Löschung
      return _deleteMessage(message);
    }
    
    if (!isModerator) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Keine Berechtigung'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Moderator löscht fremde Nachricht
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.shield, color: AppTheme.accentBlue),
            SizedBox(width: 8),
            Text('Als Moderator löschen', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Diese Aktion wird als Moderator-Log gespeichert.\n\nMöchtest du diese Nachricht löschen?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminService.deleteMessageAsModerator(
        chatRoomId: widget.chatRoom.id,
        messageId: message.id,
        moderatorId: _chatService.currentUserId!,
        reason: 'Unangebrachter Inhalt',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Nachricht als Moderator gelöscht'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _muteUser(String targetUserId) async {
    // Show duration selection
    final durations = [
      {'label': '15 Minuten', 'minutes': 15},
      {'label': '1 Stunde', 'minutes': 60},
      {'label': '4 Stunden', 'minutes': 240},
      {'label': '24 Stunden', 'minutes': 1440},
    ];
    
    final selectedDuration = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.volume_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('User Stummschalten', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: durations.map((duration) => ListTile(
            title: Text(
              duration['label'] as String,
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () => Navigator.pop(context, duration['minutes'] as int),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
    
    if (selectedDuration == null) return;
    
    try {
      // ✨ NEU: Verwende muteUserWithNotification für Benachrichtigung
      await _adminService.muteUserWithNotification(
        targetUserId: targetUserId,
        moderatorId: _chatService.currentUserId!,
        reason: 'Stummgeschaltet durch Moderator',
        durationMinutes: selectedDuration,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ User für $selectedDuration Minuten stummgeschaltet'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _blockUser(String targetUserId) async {
    final reasonController = TextEditingController();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('User Blockieren', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ACHTUNG: Diese Aktion blockiert den User dauerhaft!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Grund',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: 'z.B. Spam, Belästigung, etc.',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Blockieren', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    
    final reason = reasonController.text.trim().isEmpty 
        ? 'Kein Grund angegeben' 
        : reasonController.text.trim();
    
    try {
      // ✨ NEU: Verwende blockUserWithNotification für Benachrichtigung
      await _adminService.blockUserWithNotification(
        targetUserId: targetUserId,
        adminUserId: _chatService.currentUserId!,
        reason: reason,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ User blockiert'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleReaction(String messageId, String emoji) async {
    try {
      await _chatService.toggleReaction(
        chatRoomId: widget.chatRoom.id,
        messageId: messageId,
        emoji: emoji,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleMessageTap(ChatMessage message) {
    // Mark as read when tapped
    if (message.senderId != _chatService.currentUserId) {
      _chatService.markMessageAsRead(
        chatRoomId: widget.chatRoom.id,
        messageId: message.id,
      );
    }
  }

  // ========== UI BUILDING ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Pinned Messages Bar
          StreamBuilder<List<ChatMessage>>(
            stream: _chatService.getPinnedMessages(widget.chatRoom.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox();
              }
              
              return PinnedMessagesBar(
                pinnedMessages: snapshot.data!,
                onTap: (message) {
                  // Scroll to message (simplified - just scroll to bottom for now)
                  _scrollToBottom();
                },
                onUnpin: (message) => _togglePin(message),
              );
            },
          ),
          
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
                      'Fehler beim Laden',
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
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text('Noch keine Nachrichten', style: AppTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Starte die Unterhaltung!',
                          style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + 1, // +1 for typing indicator
                      itemBuilder: (context, index) {
                        // Typing indicator at bottom
                        if (index == 0) {
                          return StreamBuilder<List<String>>(
                            stream: _typingService.getTypingUsers(widget.chatRoom.id),
                            builder: (context, snapshot) {
                              final typingUsers = snapshot.data ?? [];
                              if (typingUsers.isEmpty) return const SizedBox();
                              
                              return TypingIndicatorWidget(
                                typingUsers: typingUsers,
                              );
                            },
                          );
                        }
                        
                        final message = messages[index - 1];
                        final isMe = message.senderId == _chatService.currentUserId;
                        
                        return EnhancedMessageBubble(
                          message: message,
                          isMe: isMe,
                          onLongPress: () => _handleMessageLongPress(message),
                          onTap: () => _handleMessageTap(message),
                          onReactionTap: (emoji) => _toggleReaction(message.id, emoji),
                          onAvatarTap: () {
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
                        );
                      },
                    ),
                    
                    // Scroll to bottom button
                    if (_showScrollToBottom)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton.small(
                          onPressed: () => _scrollToBottom(),
                          backgroundColor: AppTheme.primaryPurple,
                          child: const Icon(Icons.arrow_downward, color: Colors.white),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          
          // Reply/Edit Bar
          if (_replyingTo != null || _editingMessage != null)
            _buildReplyEditBar(),
          
          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          _buildAvatar(),
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
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: AppTheme.secondaryGold,
          ),
          onPressed: () => setState(() => _isSearching = !_isSearching),
        ),
      ],
      bottom: _isSearching
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: MessageSearchBar(
                chatRoomId: widget.chatRoom.id,
                onMessageSelected: (message) {
                  setState(() => _isSearching = false);
                  _scrollToBottom(); // Simplified - scroll to bottom
                },
              ),
            )
          : null,
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryPurple, AppTheme.secondaryGold],
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
    );
  }

  Widget _buildReplyEditBar() {
    final message = _replyingTo ?? _editingMessage;
    final isEdit = _editingMessage != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isEdit ? AppTheme.secondaryGold : AppTheme.primaryPurple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEdit ? 'Bearbeiten' : 'Antworten an ${message!.senderName}',
                  style: TextStyle(
                    color: isEdit ? AppTheme.secondaryGold : AppTheme.primaryPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message!.text,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            onPressed: isEdit ? _cancelEdit : _cancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.primaryPurple.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: SafeArea(
        child: _isRecordingVoice
            ? SimpleVoiceRecorder(
                onRecordComplete: _handleVoiceMessageSent,
                onCancel: () => setState(() => _isRecordingVoice = false),
              )
            : Row(
                children: [
                  // Image Button
                  IconButton(
                    onPressed: _showImageSourcePicker,
                    icon: const Icon(Icons.image, color: AppTheme.secondaryGold),
                  ),
                  const SizedBox(width: 8),
                  
                  // Text Input
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      onChanged: _onTextChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Voice / Send Button
                  if (_messageController.text.trim().isEmpty)
                    IconButton(
                      onPressed: () => setState(() => _isRecordingVoice = true),
                      icon: const Icon(Icons.mic, color: AppTheme.secondaryGold),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryPurple, AppTheme.secondaryGold],
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
                                : const Icon(Icons.send, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
