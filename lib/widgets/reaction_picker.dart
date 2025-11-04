import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Reaction Picker Widget - Zeigt beliebte Emojis (Phase 3)
class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;

  const ReactionPicker({
    super.key,
    required this.onEmojiSelected,
  });

  // Beliebte Reaction Emojis
  static const List<String> popularEmojis = [
    '❤️',  // Herz
    '😂',  // Lachen
    '👍',  // Daumen hoch
    '🔥',  // Feuer
    '😮',  // Überrascht
    '😢',  // Traurig
    '🎉',  // Party
    '👏',  // Klatschen
    '🙏',  // Danke
    '💯',  // 100
    '⚡',  // Blitz
    '🌟',  // Stern
    '👽',  // Alien
    '🔮',  // Kristallkugel
    '✨',  // Glitzer
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: popularEmojis.map((emoji) {
          return InkWell(
            onTap: () => onEmojiSelected(emoji),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Reaction Display Widget - Zeigt Reactions unter Nachricht (Phase 3)
class ReactionDisplay extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final String currentUserId;
  final Function(String emoji) onReactionTap;

  const ReactionDisplay({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: reactions.entries.map((entry) {
        final emoji = entry.key;
        final userIds = entry.value;
        final count = userIds.length;
        final hasReacted = userIds.contains(currentUserId);

        return InkWell(
          onTap: () => onReactionTap(emoji),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasReacted
                  ? AppTheme.primaryPurple.withValues(alpha: 0.3)
                  : AppTheme.backgroundDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasReacted
                    ? AppTheme.primaryPurple
                    : Colors.grey[700]!,
                width: hasReacted ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: hasReacted ? AppTheme.secondaryGold : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
