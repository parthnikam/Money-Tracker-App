import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/budget.dart';
import '../domain/budget_repository.dart';

class HiveBudgetRepository implements BudgetRepository {
  HiveBudgetRepository(this._box);

  final Box _box;
  final _controller = StreamController<List<Budget>>.broadcast();

  void _notify() => _controller.add(_readAll());

  List<Budget> _readAll() {
    return _box.values
        .map((e) => Budget.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<Budget>> getAll() async => _readAll();

  @override
  Stream<List<Budget>> watchAll() async* {
    yield _readAll();
    yield* _controller.stream;
  }

  @override
  Future<void> add(Budget budget) async {
    await _box.put(budget.id, budget.toMap());
    _notify();
  }

  @override
  Future<void> update(Budget budget) async {
    await _box.put(budget.id, budget.toMap());
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
    _notify();
  }
}

class HiveSavingsRepository implements SavingsRepository {
  HiveSavingsRepository(this._box);

  final Box _box;
  final _controller = StreamController<List<SavingsPlan>>.broadcast();

  void _notify() => _controller.add(_readAll());

  List<SavingsPlan> _readAll() {
    return _box.values
        .map((e) => SavingsPlan.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<SavingsPlan>> getAll() async => _readAll();

  @override
  Stream<List<SavingsPlan>> watchAll() async* {
    yield _readAll();
    yield* _controller.stream;
  }

  @override
  Future<void> add(SavingsPlan plan) async {
    await _box.put(plan.id, plan.toMap());
    _notify();
  }

  @override
  Future<void> update(SavingsPlan plan) async {
    await _box.put(plan.id, plan.toMap());
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
    _notify();
  }
}
