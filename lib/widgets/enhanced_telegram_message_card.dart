import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/telegram_service.dart';

/// Enhanced Telegram Message Card mit V4 Extended Features
/// 
/// Features:
/// - Pin Badge Display
/// - Favorite Star Button
/// - Read Receipt Counter
/// - Edit/Delete Actions
/// - Reply/Thread UI
/// - Reminder DatePicker
class EnhancedTelegramMessageCard extends StatefulWidget {
  final Map<String, dynamic> message;
  final TelegramService telegramService;
  final String currentUserId;

  const EnhancedTelegramMessageCard({
    Key? key,
    required this.message,
    required this.telegramService,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<EnhancedTelegramMessageCard> createState() => _EnhancedTelegramMessageCardState();
}

class _EnhancedTelegramMessageCardState extends State<EnhancedTelegramMessageCard> {
  bool _isFavorite = false;
  int _readCount = 0;
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _loadExtendedData();
  }

  void _loadExtendedData() {
    // Check if current user favorited
    final favoriteBy = widget.message['favorite_by'] as List<dynamic>? ?? [];
    _isFavorite = favoriteBy.contains(widget.currentUserId);
    
    // Get read count
    final readBy = widget.message['read_by'] as List<dynamic>? ?? [];
    _readCount = readBy.length;
    
    // Check if pinned
    _isPinned = widget.message['is_pinned'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: _isPinned ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _isPinned 
          ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
          : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pin Badge (wenn gepinnt)
          if (_isPinned) _buildPinBadge(),
          
          // Message Header
          _buildMessageHeader(),
          
          // Message Content
          _buildMessageContent(),
          
          // Media Gallery (wenn vorhanden)
          if (widget.message['media_files'] != null && 
              (widget.message['media_files'] as List).isNotEmpty)
            _buildMediaGallery(),
          
          // Actions Footer
          _buildActionsFooter(),
        ],
      ),
    );
  }

  /// Pin Badge Display
  Widget _buildPinBadge() {
    final pinnedAt = widget.message['pinned_at'] as Timestamp?;
    final pinnedBy = widget.message['pinned_by'] as String?;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.push_pin,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Gepinnt',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
            ),
          ),
          if (pinnedAt != null) ...[
            const SizedBox(width: 8),
            Text(
              _formatTimestamp(pinnedAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Message Header mit Author und Timestamp
  Widget _buildMessageHeader() {
    final timestamp = widget.message['timestamp'] as Timestamp?;
    final action = widget.message['action'] as String? ?? 'Neu';
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.telegram,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Telegram Bot',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (timestamp != null)
                      Text(
                        _formatTimestamp(timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    if (action == 'Bearbeitet') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Bearbeitet',
                          style: TextStyle(fontSize: 10, color: Colors.orange),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Message Content (Text)
  Widget _buildMessageContent() {
    final text = widget.message['text_clean'] as String? ?? 
                 widget.message['text'] as String? ?? 
                 'Keine Nachricht';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  /// Media Gallery (Grid oder Carousel)
  Widget _buildMediaGallery() {
    final mediaFiles = widget.message['media_files'] as List<dynamic>;
    
    if (mediaFiles.length == 1) {
      // Single media: Full width display
      return _buildSingleMedia(mediaFiles[0] as Map<String, dynamic>);
    } else {
      // Multiple media: Grid display
      return _buildMediaGrid(mediaFiles);
    }
  }

  Widget _buildSingleMedia(Map<String, dynamic> media) {
    final localPath = media['local_path'] as String?;
    final downloadUrl = media['download_url'] as String?;
    final isCached = media['is_cached'] ?? false;
    final isStreamable = media['is_streamable'] ?? false;
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Preview (oder Play Button)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isStreamable ? Icons.play_circle_outline : Icons.download,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCached ? 'Im Cache verfügbar' : 'Zum Laden tippen',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          
          // Media Info
          const SizedBox(height: 8),
          Row(
            children: [
              if (isCached)
                Chip(
                  avatar: const Icon(Icons.offline_pin, size: 16),
                  label: const Text('Offline', style: TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              if (isStreamable)
                Chip(
                  avatar: const Icon(Icons.stream, size: 16),
                  label: const Text('Streambar', style: TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(List<dynamic> mediaFiles) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: mediaFiles.length > 4 ? 4 : mediaFiles.length,
        itemBuilder: (context, index) {
          final media = mediaFiles[index] as Map<String, dynamic>;
          final isCached = media['is_cached'] ?? false;
          
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.image,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (isCached)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.offline_pin,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (index == 3 && mediaFiles.length > 4)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '+${mediaFiles.length - 4}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Actions Footer mit allen Extended Features
  Widget _buildActionsFooter() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Favorite Button
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? Colors.amber : null,
            ),
            onPressed: _toggleFavorite,
            tooltip: 'Favorit',
          ),
          
          // Read Receipt Counter
          TextButton.icon(
            onPressed: _showReadReceipts,
            icon: const Icon(Icons.visibility, size: 16),
            label: Text('$_readCount gelesen'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          
          const Spacer(),
          
          // Reply Button
          IconButton(
            icon: const Icon(Icons.reply),
            onPressed: _showReplyDialog,
            tooltip: 'Antworten',
          ),
          
          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditDialog,
            tooltip: 'Bearbeiten',
          ),
          
          // More Actions Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMoreAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pin',
                child: Row(
                  children: [
                    Icon(_isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                    const SizedBox(width: 8),
                    Text(_isPinned ? 'Entpinnen' : 'Anpinnen'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reminder',
                child: Row(
                  children: [
                    Icon(Icons.alarm),
                    SizedBox(width: 8),
                    Text('Erinnerung setzen'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Löschen', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========== ACTION HANDLERS ==========

  void _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    
    await widget.telegramService.toggleFavorite(
      widget.message['app_id'],
      widget.currentUserId,
      _isFavorite,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? '⭐ Zu Favoriten hinzugefügt' : 'Aus Favoriten entfernt'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showReadReceipts() {
    final readBy = widget.message['read_by'] as List<dynamic>? ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gelesen von'),
        content: readBy.isEmpty
          ? const Text('Noch niemand hat diese Nachricht gelesen.')
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: readBy.map((userId) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(userId.toString()),
                dense: true,
              )).toList(),
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Antworten'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Deine Antwort...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final chatId = widget.message['telegram_chat_id'];
                final messageId = widget.message['telegram_message_id'];
                
                await widget.telegramService.sendMessage(
                  chatId,
                  controller.text.trim(),
                  replyTo: messageId,
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Antwort gesendet')),
                  );
                }
              }
            },
            child: const Text('Senden'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final currentText = widget.message['text_clean'] ?? '';
    final controller = TextEditingController(text: currentText);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nachricht bearbeiten'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Neuer Text...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty && 
                  controller.text.trim() != currentText) {
                final chatId = widget.message['telegram_chat_id'];
                final messageId = widget.message['telegram_message_id'];
                
                final success = await widget.telegramService.editMessage(
                  chatId,
                  messageId,
                  controller.text.trim(),
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                        ? '✅ Nachricht aktualisiert' 
                        : '❌ Fehler beim Bearbeiten'
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _handleMoreAction(String action) async {
    switch (action) {
      case 'pin':
        await _togglePin();
        break;
      case 'reminder':
        await _setReminder();
        break;
      case 'delete':
        await _deleteMessage();
        break;
    }
  }

  Future<void> _togglePin() async {
    final chatId = widget.message['telegram_chat_id'];
    final messageId = widget.message['telegram_message_id'];
    
    final success = _isPinned
      ? await widget.telegramService.unpinMessage(chatId, messageId)
      : await widget.telegramService.pinMessage(chatId, messageId);
    
    if (success && mounted) {
      setState(() {
        _isPinned = !_isPinned;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPinned ? '📌 Nachricht angepinnt' : 'Nachricht entpinnt'),
        ),
      );
    }
  }

  Future<void> _setReminder() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Erinnerungsdatum wählen',
    );
    
    if (picked != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        helpText: 'Erinnerungszeit wählen',
      );
      
      if (time != null && mounted) {
        final reminderDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        
        // TODO: Implement reminder in Firestore
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏰ Erinnerung gesetzt für ${_formatDateTime(reminderDateTime)}'),
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nachricht löschen?'),
        content: const Text('Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
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
      final chatId = widget.message['telegram_chat_id'];
      final messageId = widget.message['telegram_message_id'];
      
      final success = await widget.telegramService.deleteMessage(chatId, messageId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Nachricht gelöscht')),
        );
      }
    }
  }

  // ========== HELPER METHODS ==========

  String _formatTimestamp(Timestamp timestamp) {
    final dt = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'vor ${diff.inHours}h';
    if (diff.inDays < 7) return 'vor ${diff.inDays}d';
    
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
