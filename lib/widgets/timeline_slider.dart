import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';

class TimelineSlider extends StatefulWidget {
  final int minYear;
  final int maxYear;
  final int currentStartYear;
  final int currentEndYear;
  final Function(int startYear, int endYear) onYearRangeChanged;
  final int eventCount;

  const TimelineSlider({
    super.key,
    required this.minYear,
    required this.maxYear,
    required this.currentStartYear,
    required this.currentEndYear,
    required this.onYearRangeChanged,
    required this.eventCount,
  });

  @override
  State<TimelineSlider> createState() => _TimelineSliderState();
}

class _TimelineSliderState extends State<TimelineSlider> {
  late RangeValues _currentRangeValues;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentRangeValues = RangeValues(
      widget.currentStartYear.toDouble(),
      widget.currentEndYear.toDouble(),
    );
  }

  int _normalizeYear(double value) {
    return value.round();
  }

  String _formatYear(int year) {
    if (year < 0) {
      return '${year.abs()} v.Chr.';
    } else if (year == 0) {
      return '0';
    } else {
      return '$year n.Chr.';
    }
  }

  String _getEpochName(int year) {
    if (year < -5000) return 'Steinzeit';
    if (year < -3000) return 'Kupferzeit';
    if (year < -1200) return 'Bronzezeit';
    if (year < 500) return 'Eisenzeit/Antike';
    if (year < 1500) return 'Mittelalter';
    if (year < 1800) return 'Frühe Neuzeit';
    if (year < 1900) return '19. Jahrhundert';
    if (year < 1950) return 'Frühe Moderne';
    if (year < 2000) return 'Späte Moderne';
    return '21. Jahrhundert';
  }

  @override
  Widget build(BuildContext context) {
    final startYear = _normalizeYear(_currentRangeValues.start);
    final endYear = _normalizeYear(_currentRangeValues.end);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.timeline,
                      color: AppTheme.secondaryGold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zeitleiste',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatYear(startYear)} - ${_formatYear(endYear)}',
                          style: TextStyle(
                            color: AppTheme.secondaryGold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.eventCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textWhite.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable Content
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Epoch Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Epoche',
                                style: TextStyle(
                                  color: AppTheme.textWhite.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getEpochName(startYear),
                                style: TextStyle(
                                  color: AppTheme.secondaryGold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: AppTheme.textWhite.withValues(alpha: 0.3),
                          size: 16,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Epoche',
                                style: TextStyle(
                                  color: AppTheme.textWhite.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getEpochName(endYear),
                                style: TextStyle(
                                  color: AppTheme.secondaryGold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Range Slider
                  RangeSlider(
                    values: _currentRangeValues,
                    min: widget.minYear.toDouble(),
                    max: widget.maxYear.toDouble(),
                    divisions: ((widget.maxYear - widget.minYear) / 100).round(),
                    activeColor: AppTheme.primaryPurple,
                    inactiveColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
                    labels: RangeLabels(
                      _formatYear(startYear),
                      _formatYear(endYear),
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _currentRangeValues = values;
                      });
                    },
                    onChangeEnd: (RangeValues values) {
                      final newStartYear = _normalizeYear(values.start);
                      final newEndYear = _normalizeYear(values.end);
                      widget.onYearRangeChanged(newStartYear, newEndYear);
                    },
                  ),
                  
                  // Quick Select Buttons
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickSelectButton('Alle', widget.minYear, widget.maxYear),
                      _buildQuickSelectButton('Antike', -10000, 500),
                      _buildQuickSelectButton('Mittelalter', 500, 1500),
                      _buildQuickSelectButton('Neuzeit', 1500, 1900),
                      _buildQuickSelectButton('20. Jh.', 1900, 2000),
                      _buildQuickSelectButton('Modern', 2000, widget.maxYear),
                    ],
                  ),
                ],
              ),
            ).animate()
              .fadeIn(duration: 200.ms)
              .slideY(begin: -0.1, end: 0, duration: 200.ms),
        ],
      ),
    );
  }

  Widget _buildQuickSelectButton(String label, int startYear, int endYear) {
    final isSelected = 
        _normalizeYear(_currentRangeValues.start) == startYear &&
        _normalizeYear(_currentRangeValues.end) == endYear;
    
    return InkWell(
      onTap: () {
        setState(() {
          _currentRangeValues = RangeValues(
            startYear.toDouble(),
            endYear.toDouble(),
          );
        });
        widget.onYearRangeChanged(startYear, endYear);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryPurple 
              : AppTheme.primaryPurple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? AppTheme.secondaryGold 
                : AppTheme.primaryPurple.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? AppTheme.textWhite 
                : AppTheme.textWhite.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
