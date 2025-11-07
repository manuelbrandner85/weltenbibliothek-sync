import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';

/// Interaktive Daten-Karte mit Animationen und Touch-Feedback
class InteractiveDataCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String value;
  final String? subtitle;
  final Color accentColor;
  final VoidCallback? onTap;
  final IconData? actionIcon;
  final bool showPulse;
  final Widget? trailing;

  const InteractiveDataCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.value,
    this.subtitle,
    required this.accentColor,
    this.onTap,
    this.actionIcon,
    this.showPulse = false,
    this.trailing,
  });

  @override
  State<InteractiveDataCard> createState() => _InteractiveDataCardState();
}

class _InteractiveDataCardState extends State<InteractiveDataCard> 
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _handleTapDown : null,
      onTapUp: widget.onTap != null ? _handleTapUp : null,
      onTapCancel: widget.onTap != null ? _handleTapCancel : null,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.accentColor.withValues(alpha: 0.15),
                widget.accentColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed
                  ? widget.accentColor.withValues(alpha: 0.6)
                  : widget.accentColor.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: _isPressed ? 0.4 : 0.2),
                blurRadius: _isPressed ? 25 : 20,
                spreadRadius: _isPressed ? 3 : 2,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Hintergrund-Animation
                if (widget.showPulse)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.5,
                          colors: [
                            widget.accentColor.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat())
                      .shimmer(
                        duration: 2000.ms,
                        color: widget.accentColor.withValues(alpha: 0.3),
                      ),
                  ),
                
                // Inhalt
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Emoji mit Rotation bei Interaktion
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        transform: Matrix4.identity()
                          ..rotateZ(_isPressed ? 0.1 : 0),
                        child: Text(
                          widget.emoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Titel
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textWhite,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Wert mit Glow-Effekt
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.accentColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          widget.value,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.accentColor,
                            shadows: [
                              Shadow(
                                color: widget.accentColor.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Untertitel
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textWhite.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                      
                      // Trailing Widget
                      if (widget.trailing != null) ...[
                        const SizedBox(height: 8),
                        widget.trailing!,
                      ],
                      
                      // Action Icon
                      if (widget.actionIcon != null) ...[
                        const SizedBox(height: 8),
                        Icon(
                          widget.actionIcon,
                          size: 20,
                          color: widget.accentColor.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Ripple-Effekt bei Tap
                if (widget.onTap != null)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onTap,
                        borderRadius: BorderRadius.circular(20),
                        splashColor: widget.accentColor.withValues(alpha: 0.3),
                        highlightColor: widget.accentColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ).animate()
          .fadeIn(duration: 400.ms)
          .scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
      ),
    );
  }
}

/// Große interaktive Hero-Card für wichtige Daten
class HeroDataCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String mainValue;
  final String subtitle;
  final Color accentColor;
  final List<Widget> children;
  final VoidCallback? onTap;

  const HeroDataCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.mainValue,
    required this.subtitle,
    required this.accentColor,
    this.children = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.2),
              accentColor.withValues(alpha: 0.1),
              AppTheme.surfaceDark.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Animierter Hintergrund
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 2.0,
                      colors: [
                        accentColor.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 3000.ms,
                    color: accentColor.withValues(alpha: 0.2),
                  ),
              ),
              
              // Inhalt
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textWhite.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onTap != null)
                          Icon(
                            Icons.arrow_forward_ios,
                            color: accentColor,
                            size: 20,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Hauptwert
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mainValue,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                              shadows: [
                                Shadow(
                                  color: accentColor.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Zusätzliche Kinder
                    if (children.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ...children,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.3, end: 0, duration: 500.ms),
    );
  }
}
