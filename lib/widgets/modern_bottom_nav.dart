// 🎯 WELTENBIBLIOTHEK - MODERNE BOTTOM NAVIGATION BAR
// Neumorphism-Style Navigation mit Animationen

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/modern_design_system.dart';

class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int unreadCount;
  final bool isDark;
  
  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadCount = 0,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ModernColors.darkSurface : ModernColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: ModernColors.deepPurple.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ModernSpacing.sm,
            vertical: ModernSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.map_rounded,
                label: 'Karte',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.telegram,
                label: 'Telegram',
                index: 2,
                badgeCount: unreadCount, // Zeigt ungelesene aus Chat-Tab
              ),
              _buildNavItem(
                icon: Icons.analytics_rounded,
                label: 'Live',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.timeline_rounded,
                label: 'Timeline',
                index: 4,
              ),
              _buildNavItem(
                icon: Icons.more_horiz_rounded,
                label: 'Mehr',
                index: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    int badgeCount = 0,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected 
        ? ModernColors.goldenHoney 
        : (isDark ? ModernColors.textGrey : ModernColors.textMedium);
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ModernSpacing.sm,
          vertical: ModernSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? ModernColors.deepPurple.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ModernRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
                
                // Badge für ungelesene Nachrichten
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: ModernColors.crimsonRed,
                        shape: BoxShape.circle,
                        boxShadow: ModernShadows.glow(ModernColors.crimsonRed),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: ModernTypography.caption.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().scale(delay: 200.ms),
                  ),
              ],
            ),
            const SizedBox(height: ModernSpacing.xs),
            Text(
              label,
              style: ModernTypography.caption.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ).animate(target: isSelected ? 1 : 0)
        .scaleXY(
          begin: 1.0,
          end: 1.05,
          duration: 200.ms,
          curve: Curves.easeOut,
        ),
    );
  }
}
