import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';

/// Horizontal month picker: selected month is centered with strong text;
/// neighbors are muted. Snaps as the user scrolls; [onChanged] fires on snap.
class MonthStrip extends StatefulWidget {
  const MonthStrip({
    super.key,
    required this.value,
    required this.onChanged,
    this.monthsBefore = 18,
    this.monthsAfter = 0,
  });

  /// First day of the selected month.
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  /// How many months before "now" are available.
  final int monthsBefore;

  /// How many months after "now" are available.
  final int monthsAfter;

  @override
  State<MonthStrip> createState() => _MonthStripState();
}

class _MonthStripState extends State<MonthStrip> {
  late final List<DateTime> _months;
  late final PageController _controller;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _months = _buildMonths();
    _selectedIndex = _indexOf(widget.value).clamp(0, _months.length - 1);
    _controller = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 0.28,
    );
  }

  @override
  void didUpdateWidget(covariant MonthStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameMonth(oldWidget.value, widget.value)) {
      final index = _indexOf(widget.value).clamp(0, _months.length - 1);
      if (index != _selectedIndex) {
        _selectedIndex = index;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_controller.hasClients) {
            _controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<DateTime> _buildMonths() {
    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month);
    final list = <DateTime>[];
    for (var i = -widget.monthsBefore; i <= widget.monthsAfter; i++) {
      list.add(DateTime(anchor.year, anchor.month + i));
    }
    return list;
  }

  int _indexOf(DateTime month) {
    final target = DateTime(month.year, month.month);
    final i = _months.indexWhere((m) => _sameMonth(m, target));
    if (i >= 0) return i;
    var best = 0;
    var bestDelta = 1 << 30;
    for (var i = 0; i < _months.length; i++) {
      final delta = (_months[i].year * 12 +
              _months[i].month -
              target.year * 12 -
              target.month)
          .abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        best = i;
      }
    }
    return best;
  }

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  void _onPageChanged(int index) {
    if (index < 0 || index >= _months.length) return;
    setState(() => _selectedIndex = index);
    final month = _months[index];
    if (!_sameMonth(month, widget.value)) {
      widget.onChanged(month);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    final monthFmt = DateFormat('MMMM');
    final shortFmt = DateFormat('MMM');

    return SizedBox(
      height: 40,
      child: PageView.builder(
        controller: _controller,
        itemCount: _months.length,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(
          parent: PageScrollPhysics(),
        ),
        itemBuilder: (context, index) {
          final month = _months[index];
          final selected = index == _selectedIndex;
          final distance = (index - _selectedIndex).abs();

          final mutedStrength = switch (distance) {
            0 => 1.0,
            1 => 0.65,
            2 => 0.45,
            _ => 0.3,
          };

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _controller.animateToPage(
                index,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
              );
            },
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: selected ? 18 : 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? palette.textPrimary
                      : palette.textTertiary.withValues(alpha: mutedStrength),
                  height: 1.1,
                ),
                child: Text(
                  selected ? monthFmt.format(month) : shortFmt.format(month),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
