import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/month_strip.dart';
import '../../../shared/widgets/period_dropdown.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../budget/presentation/stats_budgets_tab.dart';
import '../../transactions/domain/category.dart';
import '../../transactions/domain/transaction.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    final selectedMonth = ref.watch(selectedStatsMonthProvider);
    final yearLabel = DateFormat('yyyy').format(selectedMonth);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.pagePadding,
                16,
                AppConstants.pagePadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Your expenses',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        yearLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: palette.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MonthStrip(
                    value: selectedMonth,
                    onChanged: (month) {
                      ref.read(selectedStatsMonthProvider.notifier).state =
                          month;
                      ref.read(reportPeriodProvider.notifier).state =
                          ReportPeriod.month;
                      ref
                          .read(selectedStatsCategoryIdProvider.notifier)
                          .state = null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: palette.textTertiary,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Expenses'),
                      Tab(text: 'Budgets'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _ExpensesTab(),
                  StatsBudgetsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expenses tab: dial + category-grouped transactions.
class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppThemeColors.of(context);
    final selectedCategoryId = ref.watch(selectedStatsCategoryIdProvider);
    final period = ref.watch(reportPeriodProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedMonth = ref.watch(selectedStatsMonthProvider);

    final useMonthOnly = period == ReportPeriod.month;
    final transactions = useMonthOnly
        ? ref.watch(statsMonthTransactionsProvider)
        : ref.watch(filteredTransactionsProvider);
    final expenseTotal = useMonthOnly
        ? ref.watch(statsMonthExpenseTotalProvider)
        : ref.watch(periodExpenseTotalProvider);
    final categoryMap = useMonthOnly
        ? ref.watch(statsMonthCategoryExpenseMapProvider)
        : ref.watch(categoryExpenseMapProvider);

    final cats = categories.valueOrNull ?? [];
    final map = categoryMap.valueOrNull ?? {};

    final emptyLabel = selectedCategoryId != null
        ? 'No expenses in this category'
        : useMonthOnly
            ? 'No expenses in ${DateFormat('MMMM').format(selectedMonth)}'
            : 'No expenses in ${PeriodDropdown.labels[period]!.toLowerCase()}';

    return CustomScrollView(
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
              children: [
                expenseTotal.when(
                  data: (total) => _DialWithLegend(
                    total: total,
                    categoryMap: map,
                    categories: cats,
                  ),
                  loading: () => const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('$e'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: PeriodDropdown(
                    value: period,
                    onChanged: (p) {
                      ref.read(reportPeriodProvider.notifier).state = p;
                      ref
                          .read(selectedStatsCategoryIdProvider.notifier)
                          .state = null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        transactions.when(
          data: (list) {
            final expenses = list.where((t) => t.isExpense).toList();
            final groups = _groupByCategory(
              expenses: expenses,
              categories: cats,
              categoryMap: map,
              onlyCategoryId: selectedCategoryId,
            );

            if (groups.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.pagePadding,
                  ),
                  child: Center(
                    child: Text(
                      emptyLabel,
                      style: TextStyle(color: palette.textTertiary),
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
                  (context, index) {
                    final group = groups[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == groups.length - 1 ? 0 : 14,
                      ),
                      child: _CategoryPaymentBlock(
                        group: group,
                        onTxTap: (tx) =>
                            context.push('/transactions/${tx.id}'),
                        onTxDismiss: (tx) {
                          ref
                              .read(transactionRepositoryProvider)
                              .delete(tx.id);
                        },
                      ),
                    );
                  },
                  childCount: groups.length,
                  addAutomaticKeepAlives: false,
                ),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          error: (e, _) => SliverToBoxAdapter(child: Text('$e')),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

// ── Grouped payments ──────────────────────────────────────────

class _CategoryGroup {
  const _CategoryGroup({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.total,
    required this.transactions,
    this.category,
  });

  final String categoryId;
  final String name;
  final Color color;
  final double total;
  final List<Transaction> transactions;
  final Category? category;
}

List<_CategoryGroup> _groupByCategory({
  required List<Transaction> expenses,
  required List<Category> categories,
  required Map<String, double> categoryMap,
  String? onlyCategoryId,
}) {
  final filtered = onlyCategoryId == null
      ? expenses
      : expenses.where((t) => t.categoryId == onlyCategoryId).toList();

  final byId = <String, List<Transaction>>{};
  for (final tx in filtered) {
    byId.putIfAbsent(tx.categoryId, () => []).add(tx);
  }

  final groups = <_CategoryGroup>[];
  for (final entry in byId.entries) {
    final txs = List<Transaction>.from(entry.value)
      ..sort((a, b) => b.date.compareTo(a.date));
    final cat = categories.where((c) => c.id == entry.key).firstOrNull;
    final total = categoryMap[entry.key] ??
        txs.fold<double>(0, (s, t) => s + t.amount);
    groups.add(
      _CategoryGroup(
        categoryId: entry.key,
        name: cat?.name ?? 'Unknown',
        color: cat?.color ?? AppColors.primary,
        total: total,
        transactions: txs,
        category: cat,
      ),
    );
  }

  groups.sort((a, b) => b.total.compareTo(a.total));
  return groups;
}

class _CategoryPaymentBlock extends StatelessWidget {
  const _CategoryPaymentBlock({
    required this.group,
    required this.onTxTap,
    required this.onTxDismiss,
  });

  final _CategoryGroup group;
  final ValueChanged<Transaction> onTxTap;
  final ValueChanged<Transaction> onTxDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 2, right: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: palette.textPrimary,
                      ),
                ),
              ),
              Text(
                CurrencyFormatter.format(group.total),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.2,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ...group.transactions.map(
          (tx) => TransactionTile(
            transaction: tx,
            category: group.category,
            showCategoryIcon: true,
            onTap: () => onTxTap(tx),
            onDismiss: () => onTxDismiss(tx),
          ),
        ),
      ],
    );
  }
}

// ── Dial + legend ─────────────────────────────────────────────

class _DialWithLegend extends StatelessWidget {
  const _DialWithLegend({
    required this.total,
    required this.categoryMap,
    required this.categories,
  });

  final double total;
  final Map<String, double> categoryMap;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final segments = _buildSegments(
      total: total,
      categoryMap: categoryMap,
      categories: categories,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 360;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: _ExpenseDial(
                  total: total,
                  segments: segments,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: _CategoryLegend(segments: segments),
              ),
            ],
          );
        }

        return Column(
          children: [
            _ExpenseDial(total: total, segments: segments),
            const SizedBox(height: 12),
            _CategoryLegend(segments: segments),
          ],
        );
      },
    );
  }
}

/// Color swatch legend for dial segments (name + amount).
class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({required this.segments});

  final List<_ArcSegment> segments;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);

    if (segments.isEmpty) {
      return Text(
        'No expenses yet',
        style: TextStyle(color: palette.textTertiary, fontSize: 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in segments)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: s.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                Text(
                  CurrencyFormatter.format(s.amount),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Dial with hover tooltips (no tap-to-filter).
class _ExpenseDial extends StatefulWidget {
  const _ExpenseDial({
    required this.total,
    required this.segments,
  });

  final double total;
  final List<_ArcSegment> segments;

  @override
  State<_ExpenseDial> createState() => _ExpenseDialState();
}

class _ExpenseDialState extends State<_ExpenseDial> {
  String? _hoveredId;
  Offset? _hoverLocal;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    final hovered = _hoveredId == null
        ? null
        : widget.segments.where((s) => s.categoryId == _hoveredId).firstOrNull;

    return SizedBox(
      height: 220,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, 220);
          final geometry = _DialGeometry.fromSize(size);

          return MouseRegion(
            onHover: (event) {
              final id = _hitTestSegment(
                event.localPosition,
                geometry,
                widget.segments,
              );
              // Only track position while over a real segment (avoids false hits).
              final nextPos = id != null ? event.localPosition : null;
              if (id != _hoveredId || nextPos != _hoverLocal) {
                setState(() {
                  _hoveredId = id;
                  _hoverLocal = nextPos;
                });
              }
            },
            onExit: (_) {
              if (_hoveredId != null || _hoverLocal != null) {
                setState(() {
                  _hoveredId = null;
                  _hoverLocal = null;
                });
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Explicit size so hover coords match the painted dial.
                SizedBox(
                  width: size.width,
                  height: size.height,
                  child: CustomPaint(
                    painter: _ArcPainter(
                      total: widget.total,
                      segments: widget.segments,
                      hoveredCategoryId: _hoveredId,
                      trackColor: palette.glassFillStrong,
                      geometry: geometry,
                    ),
                    child: Center(
                      child: IgnorePointer(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 24),
                            Text(
                              hovered?.name ?? 'Monthly expenses',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: hovered != null
                                        ? hovered.color
                                        : palette.textSecondary,
                                    fontWeight: hovered != null
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(
                                hovered?.amount ?? widget.total,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: hovered?.color,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (hovered != null && _hoverLocal != null)
                  Positioned(
                    left: (_hoverLocal!.dx + 14)
                        .clamp(0.0, math.max(0.0, size.width - 160)),
                    top: (_hoverLocal!.dy - 36)
                        .clamp(0.0, math.max(0.0, size.height - 40)),
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            '${hovered.name} ${CurrencyFormatter.format(hovered.amount)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ArcSegment {
  const _ArcSegment({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.startAngle,
    required this.sweep,
    required this.amount,
  });

  final String categoryId;
  final String name;
  final Color color;
  final double startAngle;
  final double sweep;
  final double amount;
}

class _DialGeometry {
  const _DialGeometry({
    required this.center,
    required this.radius,
    required this.startAngle,
    required this.sweepTotal,
    required this.strokeWidth,
  });

  final Offset center;
  final double radius;
  final double startAngle;
  final double sweepTotal;
  final double strokeWidth;

  factory _DialGeometry.fromSize(Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final radius = math.min(size.width, size.height) / 2 - 14;
    return _DialGeometry(
      center: center,
      radius: radius,
      startAngle: math.pi * 0.85,
      sweepTotal: math.pi * 1.3,
      strokeWidth: 18,
    );
  }
}

List<_ArcSegment> _buildSegments({
  required double total,
  required Map<String, double> categoryMap,
  required List<Category> categories,
}) {
  if (total <= 0 || categoryMap.isEmpty) return const [];

  final catById = {for (final c in categories) c.id: c};
  final entries = categoryMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  const startAngle = math.pi * 0.85;
  const sweepTotal = math.pi * 1.3;
  const gap = 0.035;

  final segments = <_ArcSegment>[];
  var angle = startAngle;

  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    final fraction = e.value / total;
    final sweep = math.max(0.0, sweepTotal * fraction - (i == 0 ? 0 : gap));
    final color = AppColors.accentHueAt(i, total: entries.length);
    final name = catById[e.key]?.name ?? 'Unknown';

    segments.add(
      _ArcSegment(
        categoryId: e.key,
        name: name,
        color: color,
        startAngle: angle + (i == 0 ? 0 : gap),
        sweep: sweep,
        amount: e.value,
      ),
    );
    angle += sweepTotal * fraction;
  }

  return segments;
}

/// Hit-test a point against the dial ring segments.
///
/// Flutter [Canvas.drawArc] measures angles **clockwise from +X**. With
/// Flutter's y-down coordinates that matches [math.atan2](dy, dx) directly
/// (do **not** negate).
String? _hitTestSegment(
  Offset local,
  _DialGeometry g,
  List<_ArcSegment> segments,
) {
  if (segments.isEmpty) return null;

  final dx = local.dx - g.center.dx;
  final dy = local.dy - g.center.dy;
  final dist = math.sqrt(dx * dx + dy * dy);

  // Strict ring band: only the painted stroke (+ small finger padding).
  final halfStroke = g.strokeWidth * 0.5 + 2.0;
  if (dist < g.radius - halfStroke || dist > g.radius + halfStroke) {
    return null;
  }

  // Clockwise from +X, in [0, 2π).
  var angle = math.atan2(dy, dx);
  if (angle < 0) angle += 2 * math.pi;

  // Reject the open gap of the gauge (outside startAngle..start+sweep).
  final arcStart = _normAngle(g.startAngle);
  final arcEnd = _normAngle(g.startAngle + g.sweepTotal);
  if (!_angleInArc(angle, arcStart, arcEnd)) return null;

  for (final s in segments) {
    if (s.sweep <= 0) continue;
    final start = _normAngle(s.startAngle);
    final end = _normAngle(s.startAngle + s.sweep);
    if (_angleInArc(angle, start, end)) return s.categoryId;
  }
  return null;
}

double _normAngle(double a) {
  var x = a % (2 * math.pi);
  if (x < 0) x += 2 * math.pi;
  return x;
}

/// Whether [angle] lies on the clockwise arc from [start] to [end]
/// (both already normalized to [0, 2π)).
bool _angleInArc(double angle, double start, double end) {
  const eps = 0.002; // tiny tolerance at segment edges only
  if ((end - start).abs() < 1e-9) return false;

  if (start <= end) {
    // Normal case: no wrap past 2π.
    return angle + eps >= start && angle - eps <= end;
  }
  // Wraps past 2π (e.g. 5.5 → 0.4).
  return angle + eps >= start || angle - eps <= end;
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.total,
    required this.segments,
    required this.hoveredCategoryId,
    required this.trackColor,
    required this.geometry,
  });

  final double total;
  final List<_ArcSegment> segments;
  final String? hoveredCategoryId;
  final Color trackColor;
  final _DialGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;

    final bgPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = g.strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      Rect.fromCircle(center: g.center, radius: g.radius),
      g.startAngle,
      g.sweepTotal,
      false,
      bgPaint,
    );

    if (total <= 0 || segments.isEmpty) {
      final paint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: g.center, radius: g.radius),
        g.startAngle,
        g.sweepTotal * 0.15,
        false,
        paint,
      );
      return;
    }

    for (final s in segments) {
      final hovered = s.categoryId == hoveredCategoryId;
      final muted = hoveredCategoryId != null && !hovered;

      final paint = Paint()
        ..color = muted ? s.color.withValues(alpha: 0.28) : s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = hovered ? g.strokeWidth + 4 : g.strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: g.center, radius: g.radius),
        s.startAngle,
        math.max(0.01, s.sweep),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.hoveredCategoryId != hoveredCategoryId ||
        oldDelegate.segments != segments ||
        oldDelegate.trackColor != trackColor;
  }
}
