import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/historical_event.dart';
import '../widgets/category_icon.dart';

/// Verbesserte Event-Karte mit Animationen und Interaktivität
class EnhancedEventCard extends StatefulWidget {
  final HistoricalEvent event;
  final VoidCallback? onTap;
  final int index;

  const EnhancedEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.index = 0,
  });

  @override
  State<EnhancedEventCard> createState() => _EnhancedEventCardState();
}

class _EnhancedEventCardState extends State<EnhancedEventCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  Color _getCategoryColor() {
    switch (widget.event.category) {
      case EventCategory.lostCivilizations:
        return AppTheme.lostCivilizations;
      case EventCategory.alienContact:
        return AppTheme.alienContact;
      case EventCategory.secretSocieties:
        return AppTheme.secretSocieties;
      case EventCategory.techMysteries:
        return AppTheme.techMysteries;
      case EventCategory.dimensionalAnomalies:
        return AppTheme.dimensionalAnomalies;
      case EventCategory.occultEvents:
        return AppTheme.occultEvents;
      case EventCategory.forbiddenKnowledge:
        return AppTheme.forbiddenKnowledge;
      case EventCategory.ufoFleets:
        return AppTheme.ufoFleets;
      case EventCategory.energyPhenomena:
        return AppTheme.energyPhenomena;
      case EventCategory.globalConspiracies:
        return AppTheme.globalConspiracies;
    }
  }

  String _formatDate(DateTime date) {
    if (date.year < 0) {
      return '${date.year.abs()} v. Chr.';
    }
    try {
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();
    
    return GestureDetector(
      onTap: _toggleExpand,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryColor.withValues(alpha: 0.15),
              categoryColor.withValues(alpha: 0.05),
              AppTheme.surfaceDark.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Timeline-Connector
              Stack(
                children: [
                  // Glow-Effekt
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.5,
                          colors: [
                            categoryColor.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategorie & Datum
                        Row(
                          children: [
                            // Timeline-Punkt
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: categoryColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: categoryColor.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ).animate(onPlay: (controller) => controller.repeat())
                              .shimmer(
                                duration: 2000.ms,
                                color: categoryColor.withValues(alpha: 0.5),
                              ),
                            
                            const SizedBox(width: 12),
                            
                            // Kategorie-Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: categoryColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CategoryIcon(
                                    category: widget.event.category,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.event.category.toString().split('.').last,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: categoryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // Trust-Level Indikator
                            _buildTrustIndicator(),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Titel
                        Text(
                          widget.event.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textWhite,
                            height: 1.3,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Datum & Ort
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppTheme.textWhite.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(widget.event.date),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textWhite.withValues(alpha: 0.7),
                              ),
                            ),
                            if (widget.event.locationName != null) ...[
                              const SizedBox(width: 16),
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: categoryColor.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.event.locationName!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: categoryColor.withValues(alpha: 0.9),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Beschreibung (Preview)
                        Text(
                          widget.event.description,
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded ? null : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textWhite.withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Erweiterte Informationen
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark.withValues(alpha: 0.5),
                    border: Border(
                      top: BorderSide(
                        color: categoryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Perspektiven
                      if (widget.event.perspectives.isNotEmpty) ...[
                        _buildSectionTitle('Perspektiven', Icons.visibility),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.event.perspectives.map((perspective) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: categoryColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                perspective.toString().split('.').last,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: categoryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Quellen
                      if (widget.event.sources.isNotEmpty) ...[
                        _buildSectionTitle('Quellen', Icons.source),
                        const SizedBox(height: 8),
                        ...widget.event.sources.map((source) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: categoryColor.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    source,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textWhite
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                      
                      // Aktionsbuttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionButton(
                            'Auf Karte',
                            Icons.map,
                            categoryColor,
                            () {
                              widget.onTap?.call();
                            },
                          ),
                          _buildActionButton(
                            'Teilen',
                            Icons.share,
                            categoryColor,
                            () {
                              // Teilen-Funktion
                            },
                          ),
                          _buildActionButton(
                            'Merken',
                            Icons.bookmark_border,
                            categoryColor,
                            () {
                              // Merken-Funktion
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Expand/Collapse Button
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  border: Border(
                    top: BorderSide(
                      color: categoryColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isExpanded ? 'Weniger anzeigen' : 'Mehr erfahren',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: categoryColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate()
        .fadeIn(delay: (widget.index * 100).ms, duration: 400.ms)
        .slideX(begin: -0.2, end: 0, delay: (widget.index * 100).ms),
    );
  }

  Widget _buildTrustIndicator() {
    final categoryColor = _getCategoryColor();
    final trustLevel = widget.event.trustLevel;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          return Icon(
            index < trustLevel ? Icons.star : Icons.star_border,
            size: 14,
            color: index < trustLevel
                ? categoryColor
                : categoryColor.withValues(alpha: 0.3),
          );
        }),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final categoryColor = _getCategoryColor();
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: categoryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: categoryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
