import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/transactions/domain/category.dart';
import '../../../features/transactions/domain/transaction.dart';
import '../../../shared/widgets/surface_card.dart';
import '../../../shared/widgets/period_dropdown.dart';
import '../../../shared/widgets/transaction_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppThemeColors.of(context);
    final filtered = ref.watch(filteredTransactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final period = ref.watch(reportPeriodProvider);
    final expenseTotal = ref.watch(periodExpenseTotalProvider);
    final incomeTotal = ref.watch(periodIncomeTotalProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
            decelerationRate: ScrollDecelerationRate.fast,
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.pagePadding,
                  16,
                  AppConstants.pagePadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SurfaceCard(
                      depth: SurfaceDepth.outset,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your spending',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: palette.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 6),
                          expenseTotal.when(
                            data: (v) => Text(
                              CurrencyFormatter.format(v),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            loading: () => const SizedBox(
                              height: 36,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            error: (e, _) => Text('$e'),
                          ),
                          const SizedBox(height: 12),
                          filtered.when(
                            data: (list) => _SpendingSparkline(
                              transactions: list,
                              period: period,
                            ),
                            loading: () => const SizedBox(height: 100),
                            error: (_, _) => const SizedBox(height: 100),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              incomeTotal.when(
                                data: (v) => _DeltaChip(
                                  label:
                                      '+${CurrencyFormatter.formatCompact(v)} in',
                                  positive: true,
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, _) => const SizedBox.shrink(),
                              ),
                              const SizedBox(width: 8),
                              expenseTotal.when(
                                data: (v) => _DeltaChip(
                                  label:
                                      '-${CurrencyFormatter.formatCompact(v)} out',
                                  positive: false,
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, _) => const SizedBox.shrink(),
                              ),
                              const Spacer(),
                              PeriodDropdown(
                                value: period,
                                onChanged: (p) => ref
                                    .read(reportPeriodProvider.notifier)
                                    .state = p,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            filtered.when(
              data: (list) {
                final catById = {
                  for (final c in categories.valueOrNull ?? <Category>[]) c.id: c,
                };
                final items = _buildTimelineItems(list);
                if (items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.pagePadding,
                      ),
                      child: SurfaceCard(
                        child: Center(
                          child: Text(
                            'No transactions in ${PeriodDropdown.labels[period]!.toLowerCase()}',
                            style: TextStyle(color: palette.textTertiary),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.pagePadding,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final item = items[i];
                        return switch (item) {
                          _YearHeader(:final year, :final expenseTotal) =>
                            _YearSeparator(
                              year: year,
                              expenseTotal: expenseTotal,
                            ),
                          _MonthHeader(:final month, :final expenseTotal) =>
                            _MonthSeparator(
                              month: month,
                              expenseTotal: expenseTotal,
                            ),
                          _TxRow(:final tx) => TransactionTile(
                                transaction: tx,
                                category: catById[tx.categoryId],
                                onTap: () =>
                                    context.push('/transactions/${tx.id}'),
                              ),
                        };
                      },
                      childCount: items.length,
                      // Long lists: don't keep off-screen state / excess work.
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverToBoxAdapter(child: Text('$e')),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

// ── Timeline grouping: Year → Month → transactions ───────────

sealed class _TimelineItem {
  const _TimelineItem();
}

class _YearHeader extends _TimelineItem {
  const _YearHeader(this.year, this.expenseTotal);
  final int year;
  final double expenseTotal;
}

class _MonthHeader extends _TimelineItem {
  const _MonthHeader(this.month, this.expenseTotal);
  final DateTime month; // first of month
  final double expenseTotal;
}

class _TxRow extends _TimelineItem {
  const _TxRow(this.tx);
  final Transaction tx;
}

List<_TimelineItem> _buildTimelineItems(List<Transaction> list) {
  final sorted = List<Transaction>.from(list)
    ..sort((a, b) => b.date.compareTo(a.date));

  final yearExpense = <int, double>{};
  final monthExpense = <int, double>{};

  for (final tx in sorted) {
    if (!tx.isExpense) continue;
    final y = tx.date.year;
    final key = y * 12 + tx.date.month;
    yearExpense[y] = (yearExpense[y] ?? 0) + tx.amount;
    monthExpense[key] = (monthExpense[key] ?? 0) + tx.amount;
  }

  final items = <_TimelineItem>[];
  int? lastYear;
  int? lastMonthKey;

  for (final tx in sorted) {
    final y = tx.date.year;
    final m = tx.date.month;
    final monthKey = y * 12 + m;

    if (lastYear != y) {
      items.add(_YearHeader(y, yearExpense[y] ?? 0));
      lastYear = y;
      lastMonthKey = null;
    }
    if (lastMonthKey != monthKey) {
      items.add(
        _MonthHeader(DateTime(y, m), monthExpense[monthKey] ?? 0),
      );
      lastMonthKey = monthKey;
    }
    items.add(_TxRow(tx));
  }
  return items;
}

class _YearSeparator extends StatelessWidget {
  const _YearSeparator({
    required this.year,
    required this.expenseTotal,
  });

  final int year;
  final double expenseTotal;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
      child: Row(
        children: [
          Text(
            '$year',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: palette.textPrimary,
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 0.6,
              color: palette.textTertiary.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            CurrencyFormatter.format(expenseTotal),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _MonthSeparator extends StatelessWidget {
  const _MonthSeparator({
    required this.month,
    required this.expenseTotal,
  });

  final DateTime month;
  final double expenseTotal;

  static final _monthFmt = DateFormat('MMMM');

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    final label = _monthFmt.format(month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: palette.textSecondary,
                  ),
            ),
          ),
          Text(
            CurrencyFormatter.format(expenseTotal),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.label, required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color =
        positive ? AppColors.incomeOf(context) : AppColors.expenseOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Sparkline of spending and income per day/bucket over [period].
///
/// The big "Your spending" total above stays period-cumulative; this chart is not.
class _SpendingSparkline extends StatelessWidget {
  const _SpendingSparkline({
    required this.transactions,
    required this.period,
  });

  final List<Transaction> transactions;
  final ReportPeriod period;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    final incomeColor = AppColors.incomeOf(context);
    final series = _buildSpendingSeries(transactions, period);
    final expenseSpots = series.expenseSpots;
    final incomeSpots = series.incomeSpots;
    final lastIndex = expenseSpots.length - 1;

    // Shared scale so the two lines can be compared. Flat zero when both are empty.
    final expenseMax =
        expenseSpots.fold<double>(0, (m, s) => s.y > m ? s.y : m);
    final incomeMax = incomeSpots.fold<double>(0, (m, s) => s.y > m ? s.y : m);
    final showIncome = incomeMax > 0;
    final maxY = expenseMax > incomeMax ? expenseMax : incomeMax;
    final chartMaxY = maxY <= 0 ? 1.0 : maxY * 1.05;

    final expenseBar = LineChartBarData(
      spots: expenseSpots,
      isCurved: expenseSpots.length > 2 && expenseMax > 0,
      color: AppColors.primary,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.35),
            AppColors.primary.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
    // Drawn first so the expense line and its fill sit in front.
    final incomeBar = LineChartBarData(
      spots: incomeSpots,
      isCurved: incomeSpots.length > 2 && incomeMax > 0,
      color: incomeColor,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SeriesLegend(color: AppColors.primary, label: 'Expenses'),
            if (showIncome) ...[
              const SizedBox(width: 14),
              _SeriesLegend(color: incomeColor, label: 'Income'),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: LineChart(
      LineChartData(
        minX: 0,
        maxX: lastIndex < 1 ? 1 : lastIndex.toDouble(),
        minY: 0,
        maxY: chartMaxY,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: lastIndex < 1 ? 1 : lastIndex.toDouble(),
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return Text(
                    DateFormat('d MMM').format(series.bucketStarts.first),
                    style: TextStyle(fontSize: 10, color: palette.textTertiary),
                  );
                }
                if (value == lastIndex.toDouble()) {
                  return Text(
                    DateFormat('d MMM').format(series.bucketStarts.last),
                    style: TextStyle(fontSize: 10, color: palette.textTertiary),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          if (showIncome) incomeBar,
          expenseBar,
        ],
        lineTouchData: LineTouchData(
          enabled: maxY > 0,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => palette.surfaceElevated,
            getTooltipItems: (touched) {
              final ordered = [...touched]..sort((a, b) {
                  final aIncome = showIncome && a.barIndex == 0;
                  final bIncome = showIncome && b.barIndex == 0;
                  if (aIncome == bIncome) return 0;
                  return aIncome ? 1 : -1;
                });
              return [
                for (var k = 0; k < ordered.length; k++)
                  () {
                    final s = ordered[k];
                    final i = s.x
                        .round()
                        .clamp(0, series.bucketStarts.length - 1);
                    final date =
                        DateFormat('d MMM').format(series.bucketStarts[i]);
                    final isIncome = showIncome && s.barIndex == 0;
                    final name = isIncome ? 'Income' : 'Expenses';
                    final prefix = k == 0 ? '$date\n' : '';
                    return LineTooltipItem(
                      '$prefix$name ${CurrencyFormatter.format(s.y)}',
                      TextStyle(
                        color: isIncome ? incomeColor : AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }(),
              ];
            },
          ),
        ),
      ),
        ),
        ),
      ],
    );
  }
}

class _SeriesLegend extends StatelessWidget {
  const _SeriesLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SpendingSeries {
  const _SpendingSeries({
    required this.expenseSpots,
    required this.incomeSpots,
    required this.bucketStarts,
  });

  final List<FlSpot> expenseSpots;
  final List<FlSpot> incomeSpots;
  final List<DateTime> bucketStarts;
}

/// Builds per-bucket expense and income spots for the home sparkline.
_SpendingSeries _buildSpendingSeries(
  List<Transaction> transactions,
  ReportPeriod period,
) {
  final today = DateTime.now();
  final end = DateTime(today.year, today.month, today.day);
  final start = _sparklineStart(period, end);

  // Prefer daily buckets; coarsen for long ranges so the chart stays readable.
  final daySpan = end.difference(start).inDays + 1;
  final Duration step;
  if (daySpan > 180) {
    step = const Duration(days: 7); // weekly for ~6m+
  } else {
    step = const Duration(days: 1);
  }

  final bucketStarts = <DateTime>[];
  for (var d = start; !d.isAfter(end); d = d.add(step)) {
    bucketStarts.add(d);
  }
  if (bucketStarts.isEmpty) {
    bucketStarts.add(end);
  }
  // Ensure the last bucket always covers "today".
  if (bucketStarts.last.isBefore(end)) {
    bucketStarts.add(end);
  }

  final n = bucketStarts.length;
  final spentInBucket = List<double>.filled(n, 0);
  final incomeInBucket = List<double>.filled(n, 0);

  for (final t in transactions) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    if (day.isBefore(start) || day.isAfter(end)) continue;

    // Find rightmost bucket whose start <= day.
    var idx = 0;
    for (var i = 0; i < n; i++) {
      if (!bucketStarts[i].isAfter(day)) {
        idx = i;
      } else {
        break;
      }
    }
    if (t.isExpense) {
      spentInBucket[idx] += t.amount;
    } else if (t.isIncome) {
      incomeInBucket[idx] += t.amount;
    }
  }

  // Each point is that day/week only, not a running total.
  return _SpendingSeries(
    expenseSpots: [
      for (var i = 0; i < n; i++) FlSpot(i.toDouble(), spentInBucket[i]),
    ],
    incomeSpots: [
      for (var i = 0; i < n; i++) FlSpot(i.toDouble(), incomeInBucket[i]),
    ],
    bucketStarts: bucketStarts,
  );
}

DateTime _sparklineStart(ReportPeriod period, DateTime end) {
  switch (period) {
    case ReportPeriod.week:
      return end.subtract(const Duration(days: 6));
    case ReportPeriod.month:
      return DateTime(end.year, end.month);
    case ReportPeriod.threeMonths:
      return DateTime(end.year, end.month - 2);
    case ReportPeriod.sixMonths:
      return DateTime(end.year, end.month - 5);
    case ReportPeriod.year:
      return DateTime(end.year);
    case ReportPeriod.allTime:
      // Cap visual range at 1 year for readability; full history still in list.
      return DateTime(end.year - 1, end.month, end.day);
  }
}
