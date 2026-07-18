import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/budget/data/hive_budget_repository.dart';
import '../../features/budget/domain/budget.dart';
import '../../features/budget/domain/budget_repository.dart';
import '../../features/cards/data/hive_card_repository.dart';
import '../../features/cards/domain/card_repository.dart';
import '../../features/cards/domain/wallet_card.dart';
import '../../features/transactions/data/hive_transaction_repository.dart';
import '../../features/transactions/domain/category.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/transactions/domain/transaction_repository.dart';
import '../storage/hive_boxes.dart';

// ── Repositories ──────────────────────────────────────────────

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return HiveTransactionRepository(Hive.box(HiveBoxes.transactions));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return HiveCategoryRepository(Hive.box(HiveBoxes.categories));
});

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return HiveCardRepository(Hive.box(HiveBoxes.cards));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return HiveBudgetRepository(Hive.box(HiveBoxes.budgets));
});

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  return HiveSavingsRepository(Hive.box(HiveBoxes.savings));
});

// ── Streams ───────────────────────────────────────────────────

final transactionsProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

final cardsProvider = StreamProvider<List<WalletCard>>((ref) {
  return ref.watch(cardRepositoryProvider).watchAll();
});

final budgetsProvider = StreamProvider<List<Budget>>((ref) {
  return ref.watch(budgetRepositoryProvider).watchAll();
});

final savingsProvider = StreamProvider<List<SavingsPlan>>((ref) {
  return ref.watch(savingsRepositoryProvider).watchAll();
});

// ── Derived finance insights ──────────────────────────────────

enum ReportPeriod { week, month, threeMonths, sixMonths, year, allTime }

final reportPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.month);

/// First day of the month selected on the Stats month strip.
final selectedStatsMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Category filter on Stats (`null` = all categories for the month).
final selectedStatsCategoryIdProvider = StateProvider<String?>((ref) => null);

/// Budgets scoped to the Stats month strip selection.
final selectedMonthBudgetsProvider = Provider<AsyncValue<List<Budget>>>((ref) {
  final month = ref.watch(selectedStatsMonthProvider);
  return ref.watch(budgetsProvider).whenData(
        (list) => list
            .where(
              (b) =>
                  b.month.year == month.year && b.month.month == month.month,
            )
            .toList(),
      );
});

DateTime? _periodStart(ReportPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case ReportPeriod.week:
      return now.subtract(const Duration(days: 7));
    case ReportPeriod.month:
      return DateTime(now.year, now.month);
    case ReportPeriod.threeMonths:
      return DateTime(now.year, now.month - 2);
    case ReportPeriod.sixMonths:
      return DateTime(now.year, now.month - 5);
    case ReportPeriod.year:
      return DateTime(now.year);
    case ReportPeriod.allTime:
      return null;
  }
}

bool _inPeriod(DateTime date, ReportPeriod period) {
  final start = _periodStart(period);
  if (start == null) return true;
  return !date.isBefore(start);
}

bool _inMonth(DateTime date, DateTime month) {
  return date.year == month.year && date.month == month.month;
}

final filteredTransactionsProvider =
    Provider<AsyncValue<List<Transaction>>>((ref) {
  final period = ref.watch(reportPeriodProvider);
  return ref.watch(transactionsProvider).whenData(
        (list) => list.where((t) => _inPeriod(t.date, period)).toList(),
      );
});

/// Transactions in the Stats-selected calendar month.
final statsMonthTransactionsProvider =
    Provider<AsyncValue<List<Transaction>>>((ref) {
  final month = ref.watch(selectedStatsMonthProvider);
  return ref.watch(transactionsProvider).whenData(
        (list) => list.where((t) => _inMonth(t.date, month)).toList(),
      );
});

final totalBalanceProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(cardsProvider).whenData(
        (cards) => cards.fold<double>(0, (sum, c) => sum + c.balance),
      );
});

final periodExpenseTotalProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(filteredTransactionsProvider).whenData(
        (list) => list
            .where((t) => t.isExpense)
            .fold<double>(0, (sum, t) => sum + t.amount),
      );
});

final periodIncomeTotalProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(filteredTransactionsProvider).whenData(
        (list) => list
            .where((t) => t.isIncome)
            .fold<double>(0, (sum, t) => sum + t.amount),
      );
});

final statsMonthExpenseTotalProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(statsMonthTransactionsProvider).whenData(
        (list) => list
            .where((t) => t.isExpense)
            .fold<double>(0, (sum, t) => sum + t.amount),
      );
});

/// Expense totals keyed by category id for the selected period (Home, etc.).
final categoryExpenseMapProvider =
    Provider<AsyncValue<Map<String, double>>>((ref) {
  return ref.watch(filteredTransactionsProvider).whenData((list) {
    final map = <String, double>{};
    for (final t in list.where((t) => t.isExpense)) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  });
});

/// Expense totals by category for the Stats-selected month.
final statsMonthCategoryExpenseMapProvider =
    Provider<AsyncValue<Map<String, double>>>((ref) {
  return ref.watch(statsMonthTransactionsProvider).whenData((list) {
    final map = <String, double>{};
    for (final t in list.where((t) => t.isExpense)) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  });
});
