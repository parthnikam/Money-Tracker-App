import 'package:flutter/material.dart';

import '../../core/di/providers.dart';
import '../../core/theme/app_colors.dart';
import 'surface_card.dart';

/// Compact period menu (This week / month / 3M / …) used on Home and Stats.
class PeriodDropdown extends StatelessWidget {
  const PeriodDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ReportPeriod value;
  final ValueChanged<ReportPeriod> onChanged;

  static const labels = {
    ReportPeriod.week: 'This week',
    ReportPeriod.month: 'This month',
    ReportPeriod.threeMonths: '3 months',
    ReportPeriod.sixMonths: '6 months',
    ReportPeriod.year: 'This year',
    ReportPeriod.allTime: 'All time',
  };

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);

    return PopupMenuButton<ReportPeriod>(
      // Empty tooltip avoids the default Material "Show menu" hover label.
      tooltip: '',
      onSelected: onChanged,
      color: palette.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => ReportPeriod.values
          .map(
            (p) => PopupMenuItem(
              value: p,
              child: Text(labels[p]!),
            ),
          )
          .toList(),
      child: SurfaceCard(
        depth: SurfaceDepth.inset,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labels[value]!,
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}
