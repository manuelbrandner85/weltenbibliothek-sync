import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';

/// Mystischer schwebender Action-Button mit Glüh-Effekt
class MysticalFloatingButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final bool showLabel;

  const MysticalFloatingButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.showLabel = true,
  });

  @override
  State<MysticalFloatingButton> createState() => _MysticalFloatingButtonState();
}

class _MysticalFloatingButtonState extends State<MysticalFloatingButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
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
    final color = widget.color ?? AppTheme.secondaryGold;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) {
        setState(() => _isHovered = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 0.95 : 1.0),
        child: Container(
          padding: widget.showLabel
              ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
              : const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(widget.showLabel ? 30 : 60),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: _isHovered ? 25 : 20,
                spreadRadius: _isHovered ? 4 : 2,
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: _isHovered ? 40 : 30,
                spreadRadius: _isHovered ? 8 : 5,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: Colors.white,
                size: 24,
              ),
              if (widget.showLabel) ...[
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ).animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 2000.ms,
            color: Colors.white.withValues(alpha: 0.3),
          ),
      ),
    );
  }
}

/// Speed Dial Menu für mehrere Aktionen
class MysticalSpeedDial extends StatefulWidget {
  final List<SpeedDialAction> actions;
  final IconData mainIcon;
  final Color? color;

  const MysticalSpeedDial({
    super.key,
    required this.actions,
    this.mainIcon = Icons.add,
    this.color,
  });

  @override
  State<MysticalSpeedDial> createState() => _MysticalSpeedDialState();
}

class _MysticalSpeedDialState extends State<MysticalSpeedDial> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primaryPurple;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Action Items
        ...List.generate(widget.actions.length, (index) {
          final action = widget.actions[index];
          final delay = index * 50;
          
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  0.0,
                  1.0,
                  curve: Curves.elasticOut,
                ),
              ),
            ),
            child: FadeTransition(
              opacity: _controller,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Label
                    if (_isOpen)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: action.color.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          action.label,
                          style: TextStyle(
                            color: action.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).animate(delay: delay.ms)
                        .fadeIn(duration: 200.ms)
                        .slideX(begin: 0.3, end: 0),
                    
                    // Button
                    GestureDetector(
                      onTap: () {
                        _toggle();
                        action.onPressed();
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              action.color,
                              action.color.withValues(alpha: 0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: action.color.withValues(alpha: 0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          action.icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        
        // Main Button
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 35,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: AnimatedRotation(
              turns: _isOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                widget.mainIcon,
                color: Colors.white,
                size: 28,
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .shimmer(
              duration: 2000.ms,
              color: Colors.white.withValues(alpha: 0.3),
            ),
        ),
      ],
    );
  }
}

class SpeedDialAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const SpeedDialAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });
}
