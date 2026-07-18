import 'wallet_card.dart';

abstract class CardRepository {
  Future<List<WalletCard>> getAll();
  Future<void> add(WalletCard card);
  Future<void> update(WalletCard card);
  Future<void> delete(String id);
  Stream<List<WalletCard>> watchAll();
}
