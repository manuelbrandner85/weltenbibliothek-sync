import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';
import '../services/auth_service.dart';

class CommentSection extends StatefulWidget {
  final String eventId;

  const CommentSection({
    super.key,
    required this.eventId,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final CommentService _commentService = CommentService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await _commentService.addComment(
        eventId: widget.eventId,
        text: _commentController.text.trim(),
      );

      _commentController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kommentar hinzugefügt'),
            backgroundColor: AppTheme.secondaryGold,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.comment, color: AppTheme.secondaryGold, size: 24),
              const SizedBox(width: 8),
              Text(
                'Kommentare',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),
        ),

        // Comment Input
        _buildCommentInput(),

        const SizedBox(height: 16),

        // Comments List
        StreamBuilder<List<Comment>>(
          stream: _commentService.getCommentsForEvent(widget.eventId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    color: AppTheme.secondaryGold,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              // Show detailed error for debugging
              final error = snapshot.error.toString();
              print('🔴 Comment Error: $error');
              
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fehler beim Laden der Kommentare',
                      style: TextStyle(
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: TextStyle(
                        color: AppTheme.textWhite.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {}); // Trigger rebuild to retry
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Erneut versuchen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                      ),
                    ),
                  ],
                ),
              );
            }

            final comments = snapshot.data ?? [];

            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: AppTheme.textWhite.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Noch keine Kommentare',
                        style: TextStyle(
                          color: AppTheme.textWhite.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sei der Erste, der kommentiert!',
                        style: TextStyle(
                          color: AppTheme.textWhite.withValues(alpha: 0.3),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return _buildCommentItem(comments[index], index);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    final currentUser = _authService.currentUser;
    
    if (currentUser == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Text(
              'Melde dich an um zu kommentieren',
              style: TextStyle(
                color: AppTheme.textWhite.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: AppTheme.textWhite),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Schreibe einen Kommentar...',
                hintStyle: TextStyle(
                  color: AppTheme.textWhite.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.secondaryGold,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.secondaryGold, AppTheme.primaryPurple],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _isSubmitting ? null : _submitComment,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment, int index) {
    final currentUserId = _authService.currentUser?.uid;
    final isLiked = currentUserId != null && comment.isLikedBy(currentUserId);
    final isOwnComment = currentUserId == comment.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryPurple.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and time
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryPurple,
                  child: Text(
                    comment.userName.isNotEmpty 
                        ? comment.userName[0].toUpperCase()
                        : '?',
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
                      Text(
                        comment.userName,
                        style: const TextStyle(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        comment.timeAgo,
                        style: TextStyle(
                          color: AppTheme.textWhite.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwnComment)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppTheme.errorRed,
                      size: 20,
                    ),
                    onPressed: () => _deleteComment(comment),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Comment text
            Text(
              comment.text,
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            // Like button
            Row(
              children: [
                InkWell(
                  onTap: currentUserId != null
                      ? () => _toggleLike(comment.id, isLiked)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked 
                              ? AppTheme.errorRed 
                              : AppTheme.textWhite.withValues(alpha: 0.5),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          comment.likeCount.toString(),
                          style: TextStyle(
                            color: isLiked
                                ? AppTheme.errorRed
                                : AppTheme.textWhite.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate(delay: (index * 50).ms)
        .fadeIn()
        .slideX(begin: -0.1, end: 0),
    );
  }

  Future<void> _toggleLike(String commentId, bool isLiked) async {
    try {
      if (isLiked) {
        await _commentService.unlikeComment(commentId);
      } else {
        await _commentService.likeComment(commentId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Kommentar löschen?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: const Text(
          'Möchtest du diesen Kommentar wirklich löschen?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _commentService.deleteComment(comment.id, comment.userId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kommentar gelöscht'),
              backgroundColor: AppTheme.secondaryGold,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }
}
