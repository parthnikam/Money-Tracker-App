import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/category.dart';
import '../domain/transaction.dart';
import '../domain/transaction_repository.dart';

class HiveTransactionRepository implements TransactionRepository {
  HiveTransactionRepository(this._box);

  final Box _box;
  final _controller = StreamController<List<Transaction>>.broadcast();

  void _notify() => _controller.add(_readAll());

  List<Transaction> _readAll() {
    return _box.values
        .map((e) => Transaction.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<Transaction>> getAll() async => _readAll();

  @override
  Stream<List<Transaction>> watchAll() async* {
    yield _readAll();
    yield* _controller.stream;
  }

  @override
  Future<void> add(Transaction transaction) async {
    await _box.put(transaction.id, transaction.toMap());
    _notify();
  }

  @override
  Future<void> update(Transaction transaction) async {
    await _box.put(transaction.id, transaction.toMap());
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
    _notify();
  }

  void dispose() => _controller.close();
}

class HiveCategoryRepository implements CategoryRepository {
  HiveCategoryRepository(this._box);

  final Box _box;
  final _controller = StreamController<List<Category>>.broadcast();

  void _notify() => _controller.add(_readAll());

  List<Category> _readAll() {
    return _box.values
        .map((e) => Category.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<Category>> getAll() async => _readAll();

  @override
  Stream<List<Category>> watchAll() async* {
    yield _readAll();
    yield* _controller.stream;
  }

  @override
  Future<void> add(Category category) async {
    await _box.put(category.id, category.toMap());
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
    _notify();
  }
}
