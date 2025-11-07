import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';

/// Telegram Message Bubble
/// 
/// Widget für die Darstellung einzelner Telegram-Nachrichten.
/// Features:
/// - Eigene vs. fremde Nachrichten (Links vs. Rechts)
/// - Text-Nachrichten mit Formatierung
/// - Medien-Preview (Bilder, Videos, Dokumente)
/// - Timestamp-Anzeige
/// - Sender-Name bei Gruppen-Chats
class TelegramMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final int? currentUserId;

  const TelegramMessageBubble({
    super.key,
    required this.message,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final senderId = message['sender_id'] as Map<String, dynamic>?;
    final senderUserId = senderId?['user_id'] as int?;
    final isMe = senderUserId == currentUserId;
    
    final content = message['content'] as Map<String, dynamic>?;
    final date = message['date'] as int?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(isMe),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? AppTheme.secondaryGold
                    : AppTheme.surfaceDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                ),
                border: Border.all(
                  color: isMe
                      ? AppTheme.secondaryGold
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? AppTheme.secondaryGold : Colors.black)
                        .withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content
                  _buildMessageContent(content, isMe),
                  
                  const SizedBox(height: 4),
                  
                  // Timestamp
                  Text(
                    _formatTimestamp(date),
                    style: TextStyle(
                      color: isMe ? Colors.black54 : Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(isMe),
          ],
        ],
      ),
    );
  }

  /// Build Avatar
  Widget _buildAvatar(bool isMe) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isMe
            ? AppTheme.secondaryGold.withValues(alpha: 0.3)
            : AppTheme.primaryPurple.withValues(alpha: 0.3),
        border: Border.all(
          color: isMe ? AppTheme.secondaryGold : AppTheme.primaryPurple,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.person,
        size: 16,
        color: isMe ? AppTheme.secondaryGold : AppTheme.primaryPurple,
      ),
    );
  }

  /// Build Message Content based on type
  Widget _buildMessageContent(Map<String, dynamic>? content, bool isMe) {
    if (content == null) {
      return Text(
        'Nachricht',
        style: TextStyle(
          color: isMe ? Colors.black : Colors.white,
        ),
      );
    }

    final type = content['@type'] as String?;

    switch (type) {
      case 'messageText':
        return _buildTextMessage(content, isMe);
      
      case 'messagePhoto':
        return _buildPhotoMessage(content, isMe);
      
      case 'messageVideo':
        return _buildVideoMessage(content, isMe);
      
      case 'messageAudio':
        return _buildAudioMessage(content, isMe);
      
      case 'messageDocument':
        return _buildDocumentMessage(content, isMe);
      
      case 'messageSticker':
        return _buildStickerMessage(content, isMe);
      
      case 'messageVoiceNote':
        return _buildVoiceNoteMessage(content, isMe);
      
      default:
        return Text(
          'Nicht unterstützter Nachrichtentyp: $type',
          style: TextStyle(
            color: isMe ? Colors.black54 : Colors.white54,
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }

  /// Text Message
  Widget _buildTextMessage(Map<String, dynamic> content, bool isMe) {
    final text = content['text'] as Map<String, dynamic>?;
    final textContent = text?['text'] as String? ?? '';

    return Text(
      textContent,
      style: TextStyle(
        color: isMe ? Colors.black : Colors.white,
        fontSize: 15,
      ),
    );
  }

  /// Photo Message
  Widget _buildPhotoMessage(Map<String, dynamic> content, bool isMe) {
    final caption = content['caption'] as Map<String, dynamic>?;
    final captionText = caption?['text'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo, size: 48, color: Colors.white54),
                SizedBox(height: 8),
                Text(
                  '📷 Foto',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
        if (captionText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            captionText,
            style: TextStyle(
              color: isMe ? Colors.black : Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  /// Video Message
  Widget _buildVideoMessage(Map<String, dynamic> content, bool isMe) {
    final caption = content['caption'] as Map<String, dynamic>?;
    final captionText = caption?['text'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_outline, size: 48, color: Colors.white54),
                SizedBox(height: 8),
                Text(
                  '🎥 Video',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
        if (captionText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            captionText,
            style: TextStyle(
              color: isMe ? Colors.black : Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  /// Audio Message
  Widget _buildAudioMessage(Map<String, dynamic> content, bool isMe) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.music_note,
            color: isMe ? Colors.black : AppTheme.secondaryGold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '🎵 Audio-Datei',
              style: TextStyle(
                color: isMe ? Colors.black : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Document Message
  Widget _buildDocumentMessage(Map<String, dynamic> content, bool isMe) {
    final document = content['document'] as Map<String, dynamic>?;
    final fileName = document?['file_name'] as String? ?? 'Dokument';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file,
            color: isMe ? Colors.black : AppTheme.secondaryGold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              style: TextStyle(
                color: isMe ? Colors.black : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Sticker Message
  Widget _buildStickerMessage(Map<String, dynamic> content, bool isMe) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          '🎭',
          style: TextStyle(fontSize: 64),
        ),
      ),
    );
  }

  /// Voice Note Message
  Widget _buildVoiceNoteMessage(Map<String, dynamic> content, bool isMe) {
    final voiceNote = content['voice_note'] as Map<String, dynamic>?;
    final duration = voiceNote?['duration'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.mic,
            color: isMe ? Colors.black : AppTheme.secondaryGold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎤 Sprachnachricht',
                  style: TextStyle(
                    color: isMe ? Colors.black : Colors.white,
                  ),
                ),
                if (duration > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${duration}s',
                    style: TextStyle(
                      color: isMe ? Colors.black54 : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Format Timestamp
  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return '';
    
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('HH:mm').format(date);
  }
}
