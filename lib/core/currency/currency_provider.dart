import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../storage/hive_boxes.dart';
import '../utils/currency_formatter.dart';
import 'app_currency.dart';

const _currencyCodeKey = 'currency_code';

/// Persisted display currency (Hive settings box).
class CurrencyNotifier extends StateNotifier<AppCurrency> {
  CurrencyNotifier() : super(_readInitial()) {
    CurrencyFormatter.apply(state);
  }

  static AppCurrency _readInitial() {
    final box = Hive.box(HiveBoxes.settings);
    return AppCurrency.fromCode(box.get(_currencyCodeKey) as String?);
  }

  Future<void> setCurrency(AppCurrency currency) async {
    if (state == currency) return;
    state = currency;
    CurrencyFormatter.apply(currency);
    await Hive.box(HiveBoxes.settings).put(_currencyCodeKey, currency.code);
  }
}

final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, AppCurrency>((ref) {
  return CurrencyNotifier();
});
