import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/telegram_service.dart';
import '../../models/telegram_models.dart';
import 'media_gallery_v4.dart';
import 'thread_view.dart';

/// MessageCardV4 - Erweiterte Nachrichtenkarte mit V4 Features
/// 
/// FEATURES:
/// - Pin-Badge für gepinnte Nachrichten
/// - Favoriten-Stern (Gold wenn aktiv)
/// - Edit/Delete Buttons
/// - Lesebestätigung-Counter
/// - Reply/Thread-Button
/// - Erinnerungen-Button
/// - Medien-Galerie Integration
/// - Smooth Animations
class MessageCardV4 extends StatefulWidget {
  final Map<String, dynamic> message;
  final String currentUserId;
  final VoidCallback? onTap;
  final bool showActions;
  
  const MessageCardV4({
    super.key,
    required this.message,
    required this.currentUserId,
    this.onTap,
    this.showActions = true,
  });

  @override
  State<MessageCardV4> createState() => _MessageCardV4State();
}

class _MessageCardV4State extends State<MessageCardV4> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final telegramService = Provider.of<TelegramService>(context, listen: false);
    
    // Extract message data
    final bool isPinned = widget.message['is_pinned'] ?? false;
    final List<dynamic> readBy = widget.message['read_by'] ?? [];
    final List<dynamic> favoriteBy = widget.message['favorite_by'] ?? [];
    final bool isFavorite = favoriteBy.contains(widget.currentUserId);
    final int? replyTo = widget.message['reply_to'];
    final String? threadId = widget.message['thread_id'];
    final List<dynamic>? mediaFiles = widget.message['media_files'];
    final String textClean = widget.message['text_clean'] ?? '';
    final String action = widget.message['action'] ?? 'Neu';
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: isPinned ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPinned 
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
        ),
        child: InkWell(
          onTap: () {
            _animationController.forward().then((_) {
              _animationController.reverse();
            });
            widget.onTap?.call();
          },
          onLongPress: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Pin Badge + Favoriten + Status
                if (isPinned || isFavorite || action != 'Neu')
                  _buildHeader(context, isPinned, isFavorite, action),
                
                // Reply-To Indicator
                if (replyTo != null)
                  _buildReplyIndicator(context, replyTo),
                
                // Nachrichtentext
                if (textClean.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      textClean,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: _isExpanded ? null : 5,
                      overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    ),
                  ),
                
                // Medien-Galerie
                if (mediaFiles != null && mediaFiles.isNotEmpty)
                  MediaGalleryV4(
                    mediaFiles: mediaFiles,
                    compact: !_isExpanded,
                  ),
                
                const SizedBox(height: 8),
                
                // Footer: Actions + Read Counter
                if (widget.showActions)
                  _buildFooter(context, telegramService, readBy.length, isFavorite),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isPinned, bool isFavorite, String action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Pin Badge
          if (isPinned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.push_pin,
                    size: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Gepinnt',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          if (isPinned) const SizedBox(width: 8),
          
          // Favoriten-Stern
          if (isFavorite)
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 20,
            ),
          
          const Spacer(),
          
          // Action Status
          if (action != 'Neu')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: action == 'Bearbeitet' 
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                action,
                style: TextStyle(
                  fontSize: 11,
                  color: action == 'Bearbeitet' ? Colors.orange : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator(BuildContext context, int replyTo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Colors.blue,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Antwort auf Nachricht #$replyTo',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    TelegramService telegramService,
    int readCount,
    bool isFavorite,
  ) {
    return Row(
      children: [
        // Favoriten-Button
        IconButton(
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite ? Colors.amber : Colors.grey,
          ),
          iconSize: 20,
          onPressed: () async {
            await telegramService.toggleFavorite(
              widget.message['app_id'],
              widget.currentUserId,
              !isFavorite,
            );
            setState(() {});
          },
          tooltip: isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen',
        ),
        
        // Reply-Button
        IconButton(
          icon: const Icon(Icons.reply, color: Colors.blue),
          iconSize: 20,
          onPressed: () {
            _showReplyDialog(context, telegramService);
          },
          tooltip: 'Antworten',
        ),
        
        // Edit-Button
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.orange),
          iconSize: 20,
          onPressed: () {
            _showEditDialog(context, telegramService);
          },
          tooltip: 'Bearbeiten',
        ),
        
        // Delete-Button
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          iconSize: 20,
          onPressed: () {
            _showDeleteConfirmation(context, telegramService);
          },
          tooltip: 'Löschen',
        ),
        
        // Erinnerung-Button
        IconButton(
          icon: const Icon(Icons.alarm, color: Colors.purple),
          iconSize: 20,
          onPressed: () {
            _showReminderPicker(context, telegramService);
          },
          tooltip: 'Erinnerung setzen',
        ),
        
        const Spacer(),
        
        // Read Counter
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '$readCount gelesen',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, TelegramService service) {
    final controller = TextEditingController(
      text: widget.message['text_clean'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nachricht bearbeiten'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Neuer Text...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await service.editMessage(
                widget.message['telegram_chat_id'],
                widget.message['telegram_message_id'],
                controller.text,
              );
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                        ? '✅ Nachricht aktualisiert'
                        : '❌ Fehler beim Aktualisieren',
                    ),
                  ),
                );
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TelegramService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nachricht löschen'),
        content: const Text(
          'Möchtest du diese Nachricht wirklich löschen? '
          'Dies kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              final success = await service.deleteMessage(
                widget.message['telegram_chat_id'],
                widget.message['telegram_message_id'],
              );
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                        ? '✅ Nachricht gelöscht'
                        : '❌ Fehler beim Löschen',
                    ),
                  ),
                );
              }
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context, TelegramService service) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Antworten'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Deine Antwort...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await service.sendMessage(
                widget.message['telegram_chat_id'],
                controller.text,
                replyTo: widget.message['telegram_message_id'],
              );
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                        ? '✅ Antwort gesendet'
                        : '❌ Fehler beim Senden',
                    ),
                  ),
                );
              }
            },
            child: const Text('Senden'),
          ),
        ],
      ),
    );
  }

  void _showReminderPicker(BuildContext context, TelegramService service) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        ).then((time) {
          if (time != null && context.mounted) {
            final reminderTime = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
            
            // TODO: Implement reminder setting in service
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⏰ Erinnerung gesetzt für ${reminderTime.toString()}',
                ),
              ),
            );
          }
        });
      }
    });
  }
}
