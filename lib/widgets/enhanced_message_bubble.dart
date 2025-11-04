import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../models/chat_models.dart';
import 'simple_voice_recorder.dart';
import 'user_role_badge.dart';

/// Enhanced Message Bubble mit allen Phase 5 Features
class EnhancedMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String? currentUserId;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTap;
  final VoidCallback? onReply;
  final Function(String emoji)? onReactionTap;
  final VoidCallback? onAvatarTap;

  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.currentUserId,
    this.onLongPress,
    this.onDoubleTap,
    this.onTap,
    this.onReply,
    this.onReactionTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar (für andere)
            if (!isMe) ...[
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.3),
                  backgroundImage: message.senderAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(message.senderAvatar)
                      : null,
                  child: message.senderAvatar.isEmpty
                      ? Text(
                          message.senderName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.secondaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Message container
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Sender name (für Gruppen) + Role Badge
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.senderName,
                            style: const TextStyle(
                              color: AppTheme.secondaryGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          UserRoleBadge(
                            userId: message.senderId,
                            fontSize: 9,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          ),
                        ],
                      ),
                    ),

                  // Message bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isMe
                            ? [
                                AppTheme.primaryPurple.withValues(alpha: 0.8),
                                AppTheme.primaryPurple.withValues(alpha: 0.6),
                              ]
                            : [
                                Colors.grey.shade800,
                                Colors.grey.shade700,
                              ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isMe ? AppTheme.primaryPurple : Colors.black)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reply indicator (if replying)
                        if (message.isReply)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: AppTheme.secondaryGold,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.replyToSenderName ?? 'Unknown',
                                  style: TextStyle(
                                    color: AppTheme.secondaryGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  message.replyToText ?? '',
                                  style: TextStyle(
                                    color: AppTheme.textWhite.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                        // Pinned indicator
                        if (message.isPinned)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.push_pin,
                                  color: AppTheme.secondaryGold,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Angepinnt',
                                  style: TextStyle(
                                    color: AppTheme.secondaryGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Content based on type
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: _buildMessageContent(),
                        ),

                        // Metadata (time, edited, read receipts)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Edited indicator
                              if (message.isEdited) ...[
                                Text(
                                  'bearbeitet',
                                  style: TextStyle(
                                    color: AppTheme.textWhite.withValues(alpha: 0.5),
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],

                              // Time
                              Text(
                                message.timeFormatted,
                                style: TextStyle(
                                  color: AppTheme.textWhite.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),

                              // Read receipts (only for own messages)
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                _buildReadReceipts(),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Spacer
            if (isMe) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.audio:
        // Voice message
        if (message.audioUrl != null) {
          return VoiceMessagePlayer(
            audioUrl: message.audioUrl!,
            duration: message.audioDuration ?? 0,
            isMe: isMe,
          );
        }
        return Text(
          '🎤 Sprachnachricht',
          style: const TextStyle(color: AppTheme.textWhite),
        );

      case MessageType.image:
        // Image message
        if (message.imageUrl != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.secondaryGold,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ),
              if (message.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message.text,
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          );
        }
        return const Text('📷 Bild');

      case MessageType.text:
      default:
        // Text message
        return SelectableText(
          message.text,
          style: const TextStyle(
            color: AppTheme.textWhite,
            fontSize: 14,
            height: 1.4,
          ),
        );
    }
  }

  Widget _buildReadReceipts() {
    final readCount = message.readBy.length;
    
    if (readCount == 0) {
      // Not delivered/read
      return Icon(
        Icons.check,
        size: 14,
        color: AppTheme.textWhite.withValues(alpha: 0.4),
      );
    } else if (readCount == 1 && currentUserId != null && message.readBy.contains(currentUserId)) {
      // Delivered but not read by others
      return Icon(
        Icons.done_all,
        size: 14,
        color: AppTheme.textWhite.withValues(alpha: 0.4),
      );
    } else {
      // Read by others
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.done_all,
            size: 14,
            color: AppTheme.secondaryGold,
          ),
          if (readCount > 1) ...[
            const SizedBox(width: 2),
            Text(
              '$readCount',
              style: TextStyle(
                color: AppTheme.secondaryGold,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      );
    }
  }
}
