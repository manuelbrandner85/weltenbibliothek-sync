import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';

/// Telegram Reactions Widget
/// 
/// Zeigt Emoji-Reaktionen für Telegram-Posts und ermöglicht
/// Nutzern, ihre eigenen Reaktionen hinzuzufügen.
/// 
/// Unterstützte Emojis: 👍 ❤️ 🔥 😮 😂 😢
class TelegramReactionsWidget extends StatefulWidget {
  final String messageId;
  final Map<String, dynamic>? initialReactions;
  
  const TelegramReactionsWidget({
    super.key,
    required this.messageId,
    this.initialReactions,
  });

  @override
  State<TelegramReactionsWidget> createState() => _TelegramReactionsWidgetState();
}

class _TelegramReactionsWidgetState extends State<TelegramReactionsWidget> {
  final AuthService _authService = AuthService();
  
  // Verfügbare Emoji-Reaktionen
  final List<Map<String, dynamic>> _availableEmojis = [
    {'emoji': '👍', 'name': 'like', 'color': Colors.blue},
    {'emoji': '❤️', 'name': 'love', 'color': Colors.red},
    {'emoji': '🔥', 'name': 'fire', 'color': Colors.orange},
    {'emoji': '😮', 'name': 'wow', 'color': Colors.yellow},
    {'emoji': '😂', 'name': 'haha', 'color': Colors.green},
    {'emoji': '😢', 'name': 'sad', 'color': Colors.grey},
  ];
  
  bool _showAllEmojis = false;
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('telegram_messages')
          .doc(widget.messageId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final reactions = data?['reactions'] as Map<String, dynamic>? ?? {};
        
        // Gruppiere Reaktionen nach Emoji
        final Map<String, List<String>> groupedReactions = {};
        reactions.forEach((userId, emoji) {
          if (emoji is String) {
            groupedReactions.putIfAbsent(emoji, () => []);
            groupedReactions[emoji]!.add(userId);
          }
        });
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zeige vorhandene Reaktionen
            if (groupedReactions.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: groupedReactions.entries.map((entry) {
                  final emoji = entry.key;
                  final users = entry.value;
                  final hasReacted = users.contains(_authService.currentUserId);
                  
                  return _buildReactionChip(
                    emoji: emoji,
                    count: users.length,
                    hasReacted: hasReacted,
                    onTap: () => _toggleReaction(emoji),
                  );
                }).toList(),
              ),
            
            const SizedBox(height: 8),
            
            // Emoji-Picker
            _buildEmojiPicker(groupedReactions),
          ],
        );
      },
    );
  }
  
  Widget _buildReactionChip({
    required String emoji,
    required int count,
    required bool hasReacted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasReacted
              ? AppTheme.primaryPurple.withValues(alpha: 0.3)
              : AppTheme.backgroundDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasReacted
                ? AppTheme.primaryPurple
                : Colors.grey.withValues(alpha: 0.3),
            width: hasReacted ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 18),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  color: hasReacted ? AppTheme.primaryPurple : AppTheme.textWhite,
                  fontWeight: hasReacted ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmojiPicker(Map<String, List<String>> currentReactions) {
    // Zeige die ersten 3 Emojis immer, Rest auf Klick
    final displayedEmojis = _showAllEmojis
        ? _availableEmojis
        : _availableEmojis.take(3).toList();
    
    return Row(
      children: [
        ...displayedEmojis.map((emojiData) {
          final emoji = emojiData['emoji'] as String;
          final hasReacted = currentReactions[emoji]?.contains(_authService.currentUserId) ?? false;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _toggleReaction(emoji),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasReacted
                      ? AppTheme.primaryPurple.withValues(alpha: 0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasReacted
                        ? AppTheme.primaryPurple
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          );
        }),
        
        // Toggle-Button für mehr Emojis
        if (!_showAllEmojis)
          InkWell(
            onTap: () => setState(() => _showAllEmojis = true),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.add, size: 20, color: Colors.grey),
            ),
          ),
        
        if (_showAllEmojis)
          InkWell(
            onTap: () => setState(() => _showAllEmojis = false),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.remove, size: 20, color: Colors.grey),
            ),
          ),
      ],
    );
  }
  
  Future<void> _toggleReaction(String emoji) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;
    
    try {
      final docRef = FirebaseFirestore.instance
          .collection('telegram_messages')
          .doc(widget.messageId);
      
      final doc = await docRef.get();
      final data = doc.data() as Map<String, dynamic>?;
      final reactions = Map<String, dynamic>.from(data?['reactions'] ?? {});
      
      if (reactions[userId] == emoji) {
        // Remove reaction
        reactions.remove(userId);
      } else {
        // Add or change reaction
        reactions[userId] = emoji;
      }
      
      await docRef.update({'reactions': reactions});
    } catch (e) {
      debugPrint('❌ Fehler beim Hinzufügen der Reaktion: $e');
    }
  }
}

/// Reaktions-Zusammenfassung für List-Items
/// Zeigt kompakte Übersicht der Reaktionen
class TelegramReactionsSummary extends StatelessWidget {
  final Map<String, dynamic>? reactions;
  final VoidCallback? onTap;
  
  const TelegramReactionsSummary({
    super.key,
    this.reactions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions == null || reactions!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Gruppiere Reaktionen
    final Map<String, int> emojiCounts = {};
    reactions!.forEach((userId, emoji) {
      if (emoji is String) {
        emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
      }
    });
    
    if (emojiCounts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Sortiere nach Häufigkeit
    final sortedEmojis = emojiCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Zeige die Top 3 Emojis
    final displayedEmojis = sortedEmojis.take(3).toList();
    final totalCount = emojiCounts.values.fold(0, (sum, count) => sum + count);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...displayedEmojis.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }),
            const SizedBox(width: 4),
            Text(
              totalCount.toString(),
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.secondaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
