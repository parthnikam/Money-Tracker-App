import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/surface_card.dart';
import '../domain/budget.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider);
    final categories = ref.watch(categoriesProvider);
    final categoryMap = ref.watch(categoryExpenseMapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBudget(context, ref),
          ),
        ],
      ),
      body: budgets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          final cats = categories.valueOrNull ?? [];
          final spentMap = categoryMap.valueOrNull ?? {};

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No budgets yet'),
                  const SizedBox(height: 12),
                  GlassButton(
                    expand: false,
                    label: 'Set a budget',
                    onPressed: () => _showAddBudget(context, ref),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final b = list[i];
              final cat = cats.where((c) => c.id == b.categoryId);
              final name = cat.isEmpty ? 'Unknown' : cat.first.name;
              final color = cat.isEmpty ? AppColors.primary : cat.first.color;
              final spent = spentMap[b.categoryId] ?? 0;
              final progress = b.limit <= 0 ? 0.0 : (spent / b.limit).clamp(0.0, 1.5);
              final over = spent > b.limit;

              return SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.format(spent)} / ${CurrencyFormatter.format(b.limit)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: over
                                ? AppColors.expenseOf(context)
                                : AppThemeColors.of(context).textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppThemeColors.of(context).glassFill,
                        color: over ? AppColors.expenseOf(context) : color,
                      ),
                    ),
                    if (over) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Over by ${CurrencyFormatter.format(spent - b.limit)}',
                        style: TextStyle(
                          color: AppColors.expenseOf(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddBudget(BuildContext context, WidgetRef ref) async {
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    if (cats.isEmpty) return;

    var categoryId = cats.first.id;
    final limitCtrl = TextEditingController(text: '500');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppThemeColors.of(context).surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Set monthly budget',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: categoryId,
                    items: cats
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModal(() => categoryId = v!),
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: limitCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Limit',
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  GlassButton(
                    label: 'Save budget',
                    onPressed: () async {
                      final limit = double.tryParse(limitCtrl.text);
                      if (limit == null || limit <= 0) return;
                      final now = DateTime.now();
                      final budget = Budget(
                        id: const Uuid().v4(),
                        categoryId: categoryId,
                        limit: limit,
                        month: DateTime(now.year, now.month),
                      );
                      await ref.read(budgetRepositoryProvider).add(budget);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
