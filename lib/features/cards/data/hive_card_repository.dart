import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/card_repository.dart';
import '../domain/wallet_card.dart';

class HiveCardRepository implements CardRepository {
  HiveCardRepository(this._box);

  final Box _box;
  final _controller = StreamController<List<WalletCard>>.broadcast();

  void _notify() => _controller.add(_readAll());

  List<WalletCard> _readAll() {
    return _box.values
        .map((e) => WalletCard.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<WalletCard>> getAll() async => _readAll();

  @override
  Stream<List<WalletCard>> watchAll() async* {
    yield _readAll();
    yield* _controller.stream;
  }

  @override
  Future<void> add(WalletCard card) async {
    await _box.put(card.id, card.toMap());
    _notify();
  }

  @override
  Future<void> update(WalletCard card) async {
    await _box.put(card.id, card.toMap());
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
    _notify();
  }
}
