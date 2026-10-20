import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../transactions/domain/category.dart';
import '../domain/budget.dart';

/// Stats → Budgets: monthly category limits vs spend for the selected month.
class StatsBudgetsTab extends ConsumerWidget {
  const StatsBudgetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppThemeColors.of(context);
    final month = ref.watch(selectedStatsMonthProvider);
    final budgetsAsync = ref.watch(selectedMonthBudgetsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final spentMap =
        ref.watch(statsMonthCategoryExpenseMapProvider).valueOrNull ?? {};

    final monthLabel = MaterialLocalizations.of(context).formatMonthYear(month);

    return budgetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (budgets) {
        final cats = categoriesAsync.valueOrNull ?? <Category>[];
        final budgetByCat = {for (final b in budgets) b.categoryId: b};

        // Budget list: only categories with a set monthly budget.
        final rows = <_BudgetRowData>[];
        for (final cat in cats) {
          final budget = budgetByCat[cat.id];
          if (budget == null) continue;
          rows.add(
            _BudgetRowData(
              category: cat,
              budget: budget,
              spent: spentMap[cat.id] ?? 0,
            ),
          );
        }
        rows.sort((a, b) {
          final cmp = b.spent.compareTo(a.spent);
          if (cmp != 0) return cmp;
          return a.category.name.compareTo(b.category.name);
        });

        // Categories without a budget for this month (can still set one).
        final budgetedIds = rows.map((r) => r.category.id).toSet();
        final unset = cats.where((c) => !budgetedIds.contains(c.id)).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.pagePadding,
            8,
            AppConstants.pagePadding,
            120,
          ),
          children: [
            Text(
              'Monthly budgets · $monthLabel',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Set a limit per category. Progress uses expenses in this month.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textTertiary,
                  ),
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty && unset.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No categories yet',
                    style: TextStyle(color: palette.textTertiary),
                  ),
                ),
              )
            else ...[
              ...rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BudgetProgressCard(
                    data: row,
                    onTap: () => _openBudgetEditor(
                      context,
                      ref,
                      month: month,
                      category: row.category,
                      existing: row.budget,
                    ),
                    onRemove: row.budget == null
                        ? null
                        : () => _removeBudget(
                              context,
                              ref,
                              budget: row.budget!,
                              categoryName: row.category.name,
                            ),
                  ),
                ),
              ),
              if (unset.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Set a budget',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: unset
                      .map(
                        (cat) => ActionChip(
                          avatar: Icon(cat.icon, size: 16, color: AppColors.primary),
                          label: Text(cat.name),
                          onPressed: () => _openBudgetEditor(
                            context,
                            ref,
                            month: month,
                            category: cat,
                            existing: null,
                          ),
                          backgroundColor: palette.glassFill,
                          side: BorderSide.none,
                          labelStyle: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
            const SizedBox(height: 20),
            GlassButton(
              label: 'Add category budget',
              icon: Icons.add,
              onPressed: cats.isEmpty
                  ? null
                  : () => _openBudgetEditor(
                        context,
                        ref,
                        month: month,
                        category: cats.first,
                        existing: null,
                        allowCategoryPick: true,
                        categories: cats,
                      ),
            ),
          ],
        );
      },
    );
  }
}

class _BudgetRowData {
  const _BudgetRowData({
    required this.category,
    required this.budget,
    required this.spent,
  });

  final Category category;
  final Budget? budget;
  final double spent;
}

class _BudgetProgressCard extends StatelessWidget {
  const _BudgetProgressCard({
    required this.data,
    required this.onTap,
    this.onRemove,
  });

  final _BudgetRowData data;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    final limit = data.budget?.limit;
    final hasLimit = limit != null && limit > 0;
    final progress =
        hasLimit ? (data.spent / limit).clamp(0.0, 1.5) : 0.0;
    final over = hasLimit && data.spent > limit;
    final remaining = hasLimit ? (limit - data.spent) : null;

    final card = Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.category.icon,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasLimit
                              ? (over
                                  ? 'Over by ${CurrencyFormatter.format(data.spent - limit)}'
                                  : '${CurrencyFormatter.format(remaining!)} left')
                              : 'No budget set · tap to add',
                          style: TextStyle(
                            fontSize: 12,
                            color: over
                                ? AppColors.expenseOf(context)
                                : palette.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    hasLimit
                        ? '${CurrencyFormatter.format(data.spent)} / ${CurrencyFormatter.format(limit)}'
                        : CurrencyFormatter.format(data.spent),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: over
                          ? AppColors.expenseOf(context)
                          : palette.textPrimary,
                    ),
                  ),
                  if (onRemove != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Remove budget',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: palette.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
              if (hasLimit) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: palette.glassFillStrong,
                    color: over
                        ? AppColors.expenseOf(context)
                        : AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (onRemove == null) return card;

    return Dismissible(
      key: ValueKey('budget-${data.budget!.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onRemove!();
        // Deletion is confirmed in the dialog; don't auto-dismiss here.
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expenseOf(context).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline,
          color: AppColors.expenseOf(context),
        ),
      ),
      child: card,
    );
  }
}

Future<void> _removeBudget(
  BuildContext context,
  WidgetRef ref, {
  required Budget budget,
  required String categoryName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Remove budget?'),
      content: Text(
        'Remove the monthly budget for “$categoryName”? '
        'Spending is not deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Remove',
            style: TextStyle(color: AppColors.expenseOf(ctx)),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true) return;
  await ref.read(budgetRepositoryProvider).delete(budget.id);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed budget for $categoryName')),
    );
  }
}

Future<void> _openBudgetEditor(
  BuildContext context,
  WidgetRef ref, {
  required DateTime month,
  required Category category,
  required Budget? existing,
  bool allowCategoryPick = false,
  List<Category> categories = const [],
}) async {
  final palette = AppThemeColors.of(context);
  var categoryId = category.id;
  final limitCtrl = TextEditingController(
    text: existing != null
        ? existing.limit.toStringAsFixed(
            existing.limit == existing.limit.roundToDouble() ? 0 : 2,
          )
        : '',
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  existing == null ? 'Set monthly budget' : 'Edit monthly budget',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  MaterialLocalizations.of(ctx).formatMonthYear(month),
                  style: TextStyle(color: palette.textTertiary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (allowCategoryPick && categories.isNotEmpty)
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: categoryId,
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModal(() => categoryId = v);
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                  )
                else
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.16),
                      child: Icon(category.icon, color: AppColors.primary),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Category'),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Monthly limit',
                    prefixText: '${CurrencyFormatter.symbol} ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 20),
                GlassButton(
                  label: 'Save budget',
                  onPressed: () async {
                    final limit = double.tryParse(
                      limitCtrl.text.replaceAll(',', ''),
                    );
                    if (limit == null || limit <= 0) return;

                    final repo = ref.read(budgetRepositoryProvider);
                    final monthBudgets =
                        ref.read(selectedMonthBudgetsProvider).valueOrNull ??
                            [];
                    final match = monthBudgets
                        .where((b) => b.categoryId == categoryId)
                        .firstOrNull;

                    if (match != null) {
                      await repo.update(
                        Budget(
                          id: match.id,
                          categoryId: categoryId,
                          limit: limit,
                          month: DateTime(month.year, month.month),
                        ),
                      );
                    } else if (existing != null &&
                        existing.categoryId == categoryId) {
                      await repo.update(
                        Budget(
                          id: existing.id,
                          categoryId: categoryId,
                          limit: limit,
                          month: DateTime(month.year, month.month),
                        ),
                      );
                    } else {
                      await repo.add(
                        Budget(
                          id: const Uuid().v4(),
                          categoryId: categoryId,
                          limit: limit,
                          month: DateTime(month.year, month.month),
                        ),
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                if (existing != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _removeBudget(
                        context,
                        ref,
                        budget: existing,
                        categoryName: category.name,
                      );
                    },
                    child: Text(
                      'Remove from budget list',
                      style: TextStyle(color: AppColors.expenseOf(ctx)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}
