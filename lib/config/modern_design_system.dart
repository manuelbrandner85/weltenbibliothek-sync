// 🎨 WELTENBIBLIOTHEK - MODERN DESIGN SYSTEM v2.0
// Professionelle, moderne und benutzerfreundliche Designsprache

import 'package:flutter/material.dart';
import 'dart:ui';

/// 🎨 FARBPALETTE - Modern & Intelligent
class ModernColors {
  // === PRIMARY BRAND COLORS ===
  static const deepPurple = Color(0xFF6B2FBB);          // Hauptfarbe - Mystisch & Vertrauenswürdig
  static const electricPurple = Color(0xFF8B3FF5);      // Accent - Energetisch
  static const cosmicBlue = Color(0xFF1E3A8A);          // Dunkel-Akzent
  
  // === SECONDARY COLORS ===
  static const goldenHoney = Color(0xFFFFBB33);         // Warm & Premium
  static const sunsetOrange = Color(0xFFFF7F50);        // Energetisch
  static const emeraldGreen = Color(0xFF10B981);        // Erfolg
  static const crimsonRed = Color(0xFFDC2626);          // Fehler/Warnung
  
  // === GRADIENT COLORS ===
  static const gradientPurpleStart = Color(0xFF6B2FBB);
  static const gradientPurpleEnd = Color(0xFF8B3FF5);
  static const gradientGoldStart = Color(0xFFFFBB33);
  static const gradientGoldEnd = Color(0xFFFF7F50);
  
  // === DARK MODE BACKGROUNDS ===
  static const darkBackground = Color(0xFF0F0F1E);      // Haupthintergrund
  static const darkSurface = Color(0xFF1A1A2E);         // Karten & Oberflächen
  static const darkSurfaceLight = Color(0xFF252542);    // Hover-States
  
  // === LIGHT MODE BACKGROUNDS ===
  static const lightBackground = Color(0xFFF8F9FA);     // Haupthintergrund
  static const lightSurface = Color(0xFFFFFFFF);        // Karten & Oberflächen
  static const lightSurfaceDark = Color(0xFFF0F1F3);    // Hover-States
  
  // === TEXT COLORS (Dark Mode) ===
  static const textWhite = Color(0xFFFFFFFF);
  static const textGrey = Color(0xFFB0B0C8);
  static const textDim = Color(0xFF707085);
  
  // === TEXT COLORS (Light Mode) ===
  static const textDark = Color(0xFF1F2937);
  static const textMedium = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);
  
  // === CATEGORY COLORS (Verbessert) ===
  static const categoryLostCiv = Color(0xFF8B5CF6);     // Verlorene Zivilisationen
  static const categoryUFO = Color(0xFF06B6D4);         // UFOs & UAPs
  static const categoryIlluminati = Color(0xFFFFC107);  // Illuminaten
  static const categoryMatrix = Color(0xFFEF4444);      // Matrix
  static const categoryTesla = Color(0xFF10B981);       // Tesla & Energie
  static const categoryArchaeology = Color(0xFFF59E0B); // Archäologie
  static const categoryHollowEarth = Color(0xFF3B82F6); // Hohle Erde
  static const categoryOccult = Color(0xFF9333EA);      // Okkultismus
  static const categoryCosmos = Color(0xFF6366F1);      // Kosmische Mysterien
  static const categoryMedicine = Color(0xFFEC4899);    // Unterdrückte Medizin
}

/// 🎯 GRADIENTS - Moderne Farbverläufe
class ModernGradients {
  // Primary Gradient
  static const primaryGradient = LinearGradient(
    colors: [ModernColors.gradientPurpleStart, ModernColors.gradientPurpleEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Gold Gradient
  static const goldGradient = LinearGradient(
    colors: [ModernColors.gradientGoldStart, ModernColors.gradientGoldEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Cosmic Gradient
  static const cosmicGradient = LinearGradient(
    colors: [ModernColors.cosmicBlue, ModernColors.deepPurple, ModernColors.electricPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // === PREMIUM GRADIENTS ===
  
  // Aurora Gradient (Nordlichter-Effekt)
  static const auroraGradient = LinearGradient(
    colors: [
      Color(0xFF00F5FF),  // Cyan
      Color(0xFF7B42F6),  // Purple
      Color(0xFFFF006E),  // Pink
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Sunset Gradient (Sonnenuntergang)
  static const sunsetGradient = LinearGradient(
    colors: [
      Color(0xFFFF6B6B),  // Coral
      Color(0xFFFFE66D),  // Yellow
      Color(0xFFFF8E53),  // Orange
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Ocean Gradient (Ozean-Tiefe)
  static const oceanGradient = LinearGradient(
    colors: [
      Color(0xFF0077BE),  // Deep Blue
      Color(0xFF00C9FF),  // Cyan
      Color(0xFF92FE9D),  // Mint
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Fire Gradient (Feuer)
  static const fireGradient = LinearGradient(
    colors: [
      Color(0xFFFF0844),  // Red
      Color(0xFFFFB199),  // Peach
      Color(0xFFFFE600),  // Yellow
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Mystery Gradient (Geheimnisvoll)
  static const mysteryGradient = LinearGradient(
    colors: [
      Color(0xFF1A1A2E),  // Dark Navy
      Color(0xFF16213E),  // Navy
      Color(0xFF0F3460),  // Blue
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Glass Overlay
  static LinearGradient glassGradient(Color baseColor) {
    return LinearGradient(
      colors: [
        baseColor.withValues(alpha: 0.2),
        baseColor.withValues(alpha: 0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  // Shimmer Gradient (für Loading)
  static const shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFEBEBF4),
      Color(0xFFF4F4F4),
      Color(0xFFEBEBF4),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );
  
  // Card Shadow Gradient
  static LinearGradient cardShadowGradient(bool isDark) {
    return LinearGradient(
      colors: isDark
          ? [
              const Color(0xFF000000).withValues(alpha: 0.3),
              const Color(0xFF000000).withValues(alpha: 0.0),
            ]
          : [
              const Color(0xFF000000).withValues(alpha: 0.1),
              const Color(0xFF000000).withValues(alpha: 0.0),
            ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}

/// 📐 SPACING SYSTEM - 8pt Grid System
class ModernSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

/// 🔤 TYPOGRAPHY SYSTEM - Moderne Schrift-Hierarchie
class ModernTypography {
  static const String fontFamily = 'Inter'; // Falls Custom Font gewünscht
  
  // === HEADINGS ===
  static const TextStyle h1 = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    height: 1.3,
    letterSpacing: -0.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );
  
  static const TextStyle h4 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // === BODY TEXT ===
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  
  // === LABELS & BUTTONS ===
  static const TextStyle button = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    height: 1.6,
  );
}

/// 🎯 BORDER RADIUS - Konsistente Rundungen
class ModernRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double pill = 999.0;
}

/// 💫 SHADOWS - Moderne Schatten
class ModernShadows {
  static List<BoxShadow> small(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> medium(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.15),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> large(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.2),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.4),
      blurRadius: 24,
      spreadRadius: 4,
    ),
  ];
}

// NOTE: ModernAnimations Klasse ist am Ende der Datei definiert (erweiterte Version)

/// 🏗️ MODERN CARD WIDGET - Neumorphism Style
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final bool isDark;
  
  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
    this.border,
    this.isDark = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? 
        (isDark ? ModernColors.darkSurface : ModernColors.lightSurface);
    
    final effectiveShadow = boxShadow ?? ModernShadows.medium(
      isDark ? ModernColors.deepPurple : Colors.black,
    );
    
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(ModernSpacing.md),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadius ?? ModernRadius.lg),
        boxShadow: effectiveShadow,
        border: border,
      ),
      child: child,
    );
  }
}

/// ✨ GLASS MORPHISM WIDGET - Moderner Glaseffekt
class ModernGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final double blur;
  final double opacity;
  final Border? border;
  
  const ModernGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 10,
    this.opacity = 0.1,
    this.border,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? ModernRadius.lg),
        border: border ?? Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? ModernRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(ModernSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius ?? ModernRadius.lg),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 🎯 MODERN BUTTON WIDGET
class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isOutlined;
  final IconData? icon;
  final bool isLoading;
  
  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isOutlined = false,
    this.icon,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.transparent : 
            (isPrimary ? ModernColors.deepPurple : ModernColors.goldenHoney),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: ModernSpacing.lg,
          vertical: ModernSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernRadius.md),
          side: isOutlined ? const BorderSide(
            color: ModernColors.deepPurple,
            width: 2,
          ) : BorderSide.none,
        ),
        elevation: isOutlined ? 0 : 4,
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: ModernSpacing.sm),
                ],
                Text(text, style: ModernTypography.button),
              ],
            ),
    );
  }
}

/// ⚡ ANIMATIONS & TRANSITIONS - Premium Effekte
class ModernAnimations {
  // === DURATIONS ===
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
  static const verySlow = Duration(milliseconds: 800);
  
  // === CURVES ===
  static const bounceIn = Curves.elasticOut;
  static const smooth = Curves.easeInOutCubic;
  static const snappy = Curves.easeOutExpo;
  
  // === FADE TRANSITION ===
  static Widget fadeIn({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? normal,
      curve: curve ?? smooth,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }
  
  // === SCALE TRANSITION ===
  static Widget scaleIn({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: duration ?? normal,
      curve: curve ?? bounceIn,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }
  
  // === SLIDE TRANSITION ===
  static Widget slideUp({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0, 0.3), end: Offset.zero),
      duration: duration ?? normal,
      curve: curve ?? smooth,
      builder: (context, value, child) {
        return Transform.translate(offset: value, child: child);
      },
      child: child,
    );
  }
}

/// 🎭 SHIMMER LOADING EFFECT
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  
  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });
  
  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFFEBEBF4),
                Color(0xFFF4F4F4),
                Color(0xFFEBEBF4),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// 🌊 PARALLAX EFFECT
class ParallaxEffect extends StatelessWidget {
  final Widget child;
  final double strength;
  
  const ParallaxEffect({
    super.key,
    required this.child,
    this.strength = 0.05,
  });
  
  @override
  Widget build(BuildContext context) {
    return child; // Einfache Version - könnte mit Scroll-Controller erweitert werden
  }
}

/// ✨ FLOATING ACTION BUTTON (Premium)
class PremiumFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  
  const PremiumFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
  });
  
  @override
  State<PremiumFAB> createState() => _PremiumFABState();
}

class _PremiumFABState extends State<PremiumFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
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
  
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: ModernGradients.primaryGradient,
          borderRadius: BorderRadius.circular(widget.label != null ? 24 : 28),
          boxShadow: [
            BoxShadow(
              color: ModernColors.deepPurple.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _controller.forward().then((_) => _controller.reverse());
              widget.onPressed();
            },
            borderRadius: BorderRadius.circular(widget.label != null ? 24 : 28),
            child: Padding(
              padding: EdgeInsets.all(widget.label != null ? 16 : 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 24),
                  if (widget.label != null) ...[
                    const SizedBox(width: ModernSpacing.sm),
                    Text(
                      widget.label!,
                      style: ModernTypography.button.copyWith(color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 🎴 PREMIUM 3D CARD
class Premium3DCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  
  const Premium3DCard({
    super.key,
    required this.child,
    this.onTap,
  });
  
  @override
  State<Premium3DCard> createState() => _Premium3DCardState();
}

class _Premium3DCardState extends State<Premium3DCard> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_isHovered ? -0.05 : 0.0)
          ..rotateY(_isHovered ? 0.05 : 0.0),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ModernRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isHovered ? 0.3 : 0.1),
                  blurRadius: _isHovered ? 30 : 20,
                  offset: Offset(0, _isHovered ? 15 : 10),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
