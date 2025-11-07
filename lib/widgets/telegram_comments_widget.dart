import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';

/// Telegram Comments Widget
/// 
/// Ermöglicht Nutzern, Kommentare unter Telegram-Posts zu schreiben,
/// @Erwähnungen zu nutzen und auf Kommentare zu antworten.
class TelegramCommentsWidget extends StatefulWidget {
  final String messageId;
  
  const TelegramCommentsWidget({
    super.key,
    required this.messageId,
  });

  @override
  State<TelegramCommentsWidget> createState() => _TelegramCommentsWidgetState();
}

class _TelegramCommentsWidgetState extends State<TelegramCommentsWidget> {
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _replyingTo;
  Map<String, dynamic>? _replyingToData;
  
  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kommentar-Anzahl Header
        _buildCommentsHeader(),
        
        const SizedBox(height: 16),
        
        // Kommentar-Liste
        _buildCommentsList(),
        
        const SizedBox(height: 16),
        
        // Kommentar-Eingabe
        _buildCommentInput(),
      ],
    );
  }
  
  Widget _buildCommentsHeader() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('telegram_messages')
          .doc(widget.messageId)
          .collection('comments')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        
        return Row(
          children: [
            Icon(Icons.comment, color: AppTheme.secondaryGold, size: 20),
            const SizedBox(width: 8),
            Text(
              count == 0
                  ? 'Noch keine Kommentare'
                  : count == 1
                      ? '1 Kommentar'
                      : '$count Kommentare',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryGold,
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildCommentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('telegram_messages')
          .doc(widget.messageId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 12),
                  Text(
                    'Sei der Erste, der kommentiert!',
                    style: AppTheme.bodyMedium.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        
        final comments = snapshot.data!.docs;
        
        return ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final commentDoc = comments[index];
            final commentData = commentDoc.data() as Map<String, dynamic>;
            final commentId = commentDoc.id;
            
            return _buildCommentItem(commentId, commentData);
          },
        );
      },
    );
  }
  
  Widget _buildCommentItem(String commentId, Map<String, dynamic> data) {
    final userId = data['user_id'] as String?;
    final userName = data['user_name'] as String? ?? 'Unbekannt';
    final text = data['text'] as String? ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final replyTo = data['reply_to'] as String?;
    final isCurrentUser = userId == _authService.currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? AppTheme.primaryPurple.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit User und Datum
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.3),
                child: Text(
                  userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          userName,
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCurrentUser ? AppTheme.primaryPurple : AppTheme.textWhite,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Du',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (timestamp != null)
                      Text(
                        _formatTimestamp(timestamp),
                        style: AppTheme.bodySmall.copyWith(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              if (isCurrentUser)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[400]),
                  color: AppTheme.surfaceDark,
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteComment(commentId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Löschen', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Reply-To Indicator
          if (replyTo != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.secondaryGold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 14, color: AppTheme.secondaryGold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Antwort auf $replyTo',
                      style: AppTheme.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppTheme.secondaryGold,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          
          // Kommentar-Text mit @Erwähnungen
          _buildCommentText(text),
          
          const SizedBox(height: 8),
          
          // Aktionen
          Row(
            children: [
              InkWell(
                onTap: () => _startReply(commentId, userName),
                child: Row(
                  children: [
                    Icon(Icons.reply, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'Antworten',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCommentText(String text) {
    // Erkenne @Erwähnungen
    final parts = <TextSpan>[];
    final regex = RegExp(r'(@\w+)');
    int lastIndex = 0;
    
    for (final match in regex.allMatches(text)) {
      // Text vor der Erwähnung
      if (match.start > lastIndex) {
        parts.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: AppTheme.bodySmall,
        ));
      }
      
      // @Erwähnung
      parts.add(TextSpan(
        text: match.group(0),
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.secondaryGold,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // Rest des Textes
    if (lastIndex < text.length) {
      parts.add(TextSpan(
        text: text.substring(lastIndex),
        style: AppTheme.bodySmall,
      ));
    }
    
    return RichText(
      text: TextSpan(children: parts),
    );
  }
  
  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondaryGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply-Indicator
          if (_replyingTo != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 14, color: AppTheme.secondaryGold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Antwort auf $_replyingTo',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.secondaryGold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _replyingTo = null;
                        _replyingToData = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: AppTheme.bodyMedium,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: _replyingTo != null
                        ? 'Antwort schreiben...'
                        : 'Kommentar schreiben... (nutze @Name für Erwähnungen)',
                    hintStyle: AppTheme.bodySmall.copyWith(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: AppTheme.secondaryGold),
                onPressed: _postComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Gerade eben';
    } else if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes} Min.';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours} Std.';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays} Tag${difference.inDays > 1 ? "en" : ""}';
    } else {
      return DateFormat('dd.MM.yyyy').format(timestamp);
    }
  }
  
  void _startReply(String commentId, String userName) {
    setState(() {
      _replyingTo = userName;
      _replyingToData = {'comment_id': commentId};
    });
    _commentController.text = '@$userName ';
  }
  
  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    final userId = _authService.currentUserId;
    final userName = _authService.currentUserId ?? 'Anonym';
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte anmelden, um zu kommentieren')),
      );
      return;
    }
    
    try {
      await FirebaseFirestore.instance
          .collection('telegram_messages')
          .doc(widget.messageId)
          .collection('comments')
          .add({
        'user_id': userId,
        'user_name': userName,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'reply_to': _replyingTo,
      });
      
      _commentController.clear();
      setState(() {
        _replyingTo = null;
        _replyingToData = null;
      });
      
      // Scroll zum Ende
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }
  
  Future<void> _deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('telegram_messages')
          .doc(widget.messageId)
          .collection('comments')
          .doc(commentId)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kommentar gelöscht')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }
}

/// Kommentar-Zähler für List-Items
class TelegramCommentsCounter extends StatelessWidget {
  final String messageId;
  final VoidCallback? onTap;
  
  const TelegramCommentsCounter({
    super.key,
    required this.messageId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('telegram_messages')
          .doc(messageId)
          .collection('comments')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        
        if (count == 0) {
          return InkWell(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.comment_outlined, size: 18, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  'Kommentieren',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }
        
        return InkWell(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.comment, size: 18, color: AppTheme.secondaryGold),
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.secondaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
