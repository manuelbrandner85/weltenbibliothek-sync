import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Ultra-kompakte, innovative Timeline (nur 40px hoch!)
/// Minimalistische Slider-Bar mit präziser Jahreszahl-Anzeige
class CompactTimelineSlider extends StatefulWidget {
  final int minYear;
  final int maxYear;
  final int currentStartYear;
  final int currentEndYear;
  final Function(int startYear, int endYear) onYearRangeChanged;
  final int eventCount;

  const CompactTimelineSlider({
    super.key,
    required this.minYear,
    required this.maxYear,
    required this.currentStartYear,
    required this.currentEndYear,
    required this.onYearRangeChanged,
    required this.eventCount,
  });

  @override
  State<CompactTimelineSlider> createState() => _CompactTimelineSliderState();
}

class _CompactTimelineSliderState extends State<CompactTimelineSlider> {
  late int currentStartYear;
  late int currentEndYear;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    currentStartYear = widget.currentStartYear;
    currentEndYear = widget.currentEndYear;
  }

  String _formatYear(int year) {
    if (year < 0) {
      return '${year.abs()}v';
    } else if (year == 0) {
      return '0';
    } else {
      return '$year';
    }
  }
  
  String _formatYearFull(int year) {
    if (year < 0) {
      return '${year.abs()} v.Chr.';
    } else {
      return '$year n.Chr.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _isExpanded ? 100 : 40,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: _isExpanded ? 12 : 6,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.surfaceDark.withValues(alpha: 0.98),
              AppTheme.surfaceDark.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(_isExpanded ? 16 : 20),
          border: Border.all(
            color: _isExpanded 
                ? AppTheme.secondaryGold.withValues(alpha: 0.5)
                : AppTheme.primaryPurple.withValues(alpha: 0.3),
            width: _isExpanded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isExpanded
                  ? AppTheme.secondaryGold.withValues(alpha: 0.2)
                  : AppTheme.backgroundDark.withValues(alpha: 0.5),
              blurRadius: _isExpanded ? 15 : 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isExpanded ? _buildExpandedView() : _buildCompactView(),
      ),
    );
  }

  /// ULTRA-KOMPAKTE ANSICHT (40px - Standard)
  Widget _buildCompactView() {
    return Row(
      children: [
        // Timeline Icon (24x24)
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.access_time,
            color: AppTheme.secondaryGold,
            size: 14,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Start Jahr (kompakt)
        SizedBox(
          width: 55,
          child: Text(
            _formatYear(currentStartYear),
            style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryGold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Mini Slider (visualisiert Range)
        Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Stack(
              children: [
                // Hintergrund
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Aktiver Bereich
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (currentEndYear - currentStartYear) / 
                               (widget.maxYear - widget.minYear),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryPurple,
                          AppTheme.secondaryGold,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // End Jahr (kompakt)
        SizedBox(
          width: 55,
          child: Text(
            _formatYear(currentEndYear),
            style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryGold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Event Count Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${widget.eventCount}',
            style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
        ),
      ],
    );
  }

  /// ERWEITERTE ANSICHT (100px - bei Tap)
  Widget _buildExpandedView() {
    return Column(
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: AppTheme.secondaryGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Zeitraum Filter',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.eventCount} Events',
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Jahreszahlen-Anzeige
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatYearFull(currentStartYear),
              style: AppTheme.bodySmall.copyWith(
                fontSize: 12,
                color: AppTheme.secondaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.arrow_forward,
              size: 16,
              color: AppTheme.primaryPurple,
            ),
            Text(
              _formatYearFull(currentEndYear),
              style: AppTheme.bodySmall.copyWith(
                fontSize: 12,
                color: AppTheme.secondaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Range Slider
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            activeTrackColor: AppTheme.primaryPurple,
            inactiveTrackColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
            thumbColor: AppTheme.secondaryGold,
            overlayColor: AppTheme.secondaryGold.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
          ),
          child: RangeSlider(
            min: widget.minYear.toDouble(),
            max: widget.maxYear.toDouble(),
            values: RangeValues(
              currentStartYear.toDouble(),
              currentEndYear.toDouble(),
            ),
            onChanged: (values) {
              setState(() {
                currentStartYear = values.start.toInt();
                currentEndYear = values.end.toInt();
              });
              widget.onYearRangeChanged(currentStartYear, currentEndYear);
            },
          ),
        ),
      ],
    );
  }
}
