import 'package:flutter/material.dart';
import '../models/historical_event.dart';
import '../config/app_theme.dart';

/// Professional category icon widget with gradient background
/// Replaces emojis with Material Icons for better quality and consistency
class CategoryIcon extends StatelessWidget {
  final EventCategory category;
  final double size;
  final bool showGradient;
  final Color? backgroundColor;
  final Color? iconColor;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 40,
    this.showGradient = true,
    this.backgroundColor,
    this.iconColor,
  });

  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.lostCivilizations:
        return AppTheme.secondaryGold;
      case EventCategory.alienContact:
        return const Color(0xFF00FF41); // Alien Green
      case EventCategory.secretSocieties:
        return AppTheme.primaryPurple;
      case EventCategory.techMysteries:
        return const Color(0xFF00D4FF); // Tech Cyan
      case EventCategory.dimensionalAnomalies:
        return const Color(0xFFFF006E); // Dimensional Pink
      case EventCategory.occultEvents:
        return const Color(0xFF9D4EDD); // Mystic Purple
      case EventCategory.forbiddenKnowledge:
        return const Color(0xFFFFBE0B); // Ancient Gold
      case EventCategory.ufoFleets:
        return const Color(0xFF4CC9F0); // UFO Blue
      case EventCategory.energyPhenomena:
        return AppTheme.energyPhenomena;
      case EventCategory.globalConspiracies:
        return const Color(0xFFFF5400); // Conspiracy Orange
    }
  }

  IconData _getCategoryIcon(EventCategory category) {
    switch (category) {
      case EventCategory.lostCivilizations:
        return Icons.account_balance;
      case EventCategory.alienContact:
        return Icons.space_dashboard;
      case EventCategory.secretSocieties:
        return Icons.security;
      case EventCategory.techMysteries:
        return Icons.radar;
      case EventCategory.dimensionalAnomalies:
        return Icons.grain;
      case EventCategory.occultEvents:
        return Icons.auto_awesome;
      case EventCategory.forbiddenKnowledge:
        return Icons.menu_book;
      case EventCategory.ufoFleets:
        return Icons.flight;
      case EventCategory.energyPhenomena:
        return Icons.flash_on;
      case EventCategory.globalConspiracies:
        return Icons.public;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(category);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: showGradient
            ? RadialGradient(
                colors: [
                  backgroundColor ?? color.withValues(alpha: 0.3),
                  backgroundColor ?? color.withValues(alpha: 0.1),
                ],
              )
            : null,
        color: showGradient ? null : (backgroundColor ?? color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(size / 4),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        _getCategoryIcon(category),
        color: iconColor ?? color,
        size: size * 0.5,
      ),
    );
  }
}

/// Compact version for small displays
class CategoryIconCompact extends StatelessWidget {
  final EventCategory category;
  final double size;

  const CategoryIconCompact({
    super.key,
    required this.category,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CategoryIcon(
      category: category,
      size: size,
      showGradient: false,
    );
  }
}
