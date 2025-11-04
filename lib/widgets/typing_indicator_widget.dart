import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Typing Indicator Widget - Animierte "User tippt..." Anzeige
class TypingIndicatorWidget extends StatefulWidget {
  final List<String> typingUsers;

  const TypingIndicatorWidget({
    super.key,
    required this.typingUsers,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar placeholder
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit,
              size: 16,
              color: AppTheme.secondaryGold,
            ),
          ),

          const SizedBox(width: 8),

          // Typing bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade800,
                  Colors.grey.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text
                Text(
                  _formatTypingText(),
                  style: TextStyle(
                    color: AppTheme.textWhite.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(width: 8),

                // Animated dots
                _buildAnimatedDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTypingText() {
    if (widget.typingUsers.length == 1) {
      return '${widget.typingUsers.first} tippt';
    } else if (widget.typingUsers.length == 2) {
      return '${widget.typingUsers[0]} und ${widget.typingUsers[1]} tippen';
    } else {
      return '${widget.typingUsers.length} Personen tippen';
    }
  }

  Widget _buildAnimatedDots() {
    return SizedBox(
      width: 30,
      height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Stagger the animation for each dot
              final delay = index * 0.2;
              final progress = (_controller.value + delay) % 1.0;
              final scale = 0.5 + (0.5 * (1 - (progress - 0.5).abs() * 2));

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryGold.withValues(
                      alpha: 0.5 + (0.5 * scale),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
