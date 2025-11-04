import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/chat_models.dart';

/// Pinned Messages Bar - Zeigt angepinnte Nachrichten oben (Phase 5C)
class PinnedMessagesBar extends StatelessWidget {
  final List<ChatMessage> pinnedMessages;
  final Function(ChatMessage) onTap;
  final Function(ChatMessage) onUnpin;

  const PinnedMessagesBar({
    super.key,
    required this.pinnedMessages,
    required this.onTap,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    if (pinnedMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withValues(alpha: 0.3),
            AppTheme.primaryPurple.withValues(alpha: 0.2),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.secondaryGold.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.push_pin,
                  color: AppTheme.secondaryGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Angepinnte Nachrichten (${pinnedMessages.length})',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Pinned messages list
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: pinnedMessages.length,
              itemBuilder: (context, index) {
                final message = pinnedMessages[index];
                return _buildPinnedMessageCard(context, message);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedMessageCard(BuildContext context, ChatMessage message) {
    return GestureDetector(
      onTap: () => onTap(message),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.secondaryGold.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sender
                  Text(
                    message.senderName,
                    style: TextStyle(
                      color: AppTheme.secondaryGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Text
                  Text(
                    message.type == MessageType.audio
                        ? '🎤 Sprachnachricht'
                        : message.type == MessageType.image
                            ? '📷 Bild'
                            : message.text,
                    style: TextStyle(
                      color: AppTheme.textWhite.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Unpin button
            InkWell(
              onTap: () => onUnpin(message),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.red.shade300,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
