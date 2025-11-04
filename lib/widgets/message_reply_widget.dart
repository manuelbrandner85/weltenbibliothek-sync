import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/chat_models.dart';

/// Widget für Reply-Vorschau in der Nachricht (Phase 5A)
class MessageReplyPreview extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onTap;

  const MessageReplyPreview({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!message.isReply) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withValues(alpha: 0.1),
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
              message.replyToSenderName ?? 'Unbekannt',
              style: const TextStyle(
                color: AppTheme.secondaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
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
    );
  }
}

/// Widget für Reply-Input-Bar (Phase 5A)
class ReplyInputBar extends StatelessWidget {
  final ChatMessage? replyingTo;
  final VoidCallback onCancel;

  const ReplyInputBar({
    super.key,
    required this.replyingTo,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (replyingTo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.reply,
                      size: 16,
                      color: AppTheme.secondaryGold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Antwort an ${replyingTo!.senderName}',
                      style: const TextStyle(
                        color: AppTheme.secondaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  replyingTo!.text,
                  style: TextStyle(
                    color: AppTheme.textWhite.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textWhite),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

/// Widget für Read Receipts Status (Phase 5A)
class ReadReceiptsIndicator extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final int participantsCount;

  const ReadReceiptsIndicator({
    super.key,
    required this.message,
    required this.isMe,
    required this.participantsCount,
  });

  @override
  Widget build(BuildContext context) {
    if (!isMe) return const SizedBox.shrink();

    final readCount = message.readBy.length;
    final allRead = readCount >= (participantsCount - 1); // Minus sender

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          allRead ? Icons.done_all : Icons.done,
          size: 14,
          color: allRead ? Colors.blue : AppTheme.textWhite.withValues(alpha: 0.5),
        ),
        if (message.isEdited) ...[
          const SizedBox(width: 4),
          Text(
            'bearbeitet',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textWhite.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
