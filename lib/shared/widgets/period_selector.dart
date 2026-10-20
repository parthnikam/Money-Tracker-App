import 'package:flutter/material.dart';

import '../../core/di/providers.dart';
import '../../core/theme/app_colors.dart';
import 'surface_card.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final ReportPeriod value;
  final ValueChanged<ReportPeriod> onChanged;
  final bool compact;

  static const _labels = {
    ReportPeriod.week: 'Week',
    ReportPeriod.month: 'Month',
    ReportPeriod.threeMonths: '3M',
    ReportPeriod.sixMonths: '6M',
    ReportPeriod.year: 'Year',
    ReportPeriod.allTime: 'All',
  };

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    final periods = compact
        ? const [
            ReportPeriod.week,
            ReportPeriod.month,
            ReportPeriod.year,
          ]
        : ReportPeriod.values;

    return SurfaceCard(
      depth: SurfaceDepth.inset,
      padding: const EdgeInsets.all(4),
      borderRadius: BorderRadius.circular(24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.map((p) {
          final selected = p == value;
          return GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _labels[p]!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.onPrimary
                      : palette.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
