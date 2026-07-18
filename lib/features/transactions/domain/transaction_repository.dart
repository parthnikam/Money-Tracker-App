import 'transaction.dart';
import 'category.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getAll();
  Future<void> add(Transaction transaction);
  Future<void> update(Transaction transaction);
  Future<void> delete(String id);
  Stream<List<Transaction>> watchAll();
}

abstract class CategoryRepository {
  Future<List<Category>> getAll();
  Future<void> add(Category category);
  Future<void> delete(String id);
  Stream<List<Category>> watchAll();
}
