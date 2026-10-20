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
    final existing = _readAll();
    final target = existing.where((c) => c.id == id).firstOrNull;
    await _box.delete(id);
    // Keep a primary spend account when the deleted card was the primary one.
    if (target != null && target.isPrimary) {
      final rest = _readAll();
      if (rest.isNotEmpty && !rest.any((c) => c.isPrimary)) {
        final next = rest.first;
        await _box.put(next.id, next.copyWith(isPrimary: true).toMap());
      }
    }
    _notify();
  }
}
