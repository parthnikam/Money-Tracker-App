import 'budget.dart';

abstract class BudgetRepository {
  Future<List<Budget>> getAll();
  Future<void> add(Budget budget);
  Future<void> update(Budget budget);
  Future<void> delete(String id);
  Stream<List<Budget>> watchAll();
}

abstract class SavingsRepository {
  Future<List<SavingsPlan>> getAll();
  Future<void> add(SavingsPlan plan);
  Future<void> update(SavingsPlan plan);
  Future<void> delete(String id);
  Stream<List<SavingsPlan>> watchAll();
}
