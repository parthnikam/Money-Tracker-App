import 'package:intl/intl.dart';

import '../currency/app_currency.dart';

/// Formats amounts using the active [AppCurrency] from settings.
abstract final class CurrencyFormatter {
  static AppCurrency _currency = AppCurrency.usd;
  static NumberFormat _full = _buildFull(AppCurrency.usd);
  static NumberFormat _compact = _buildCompact(AppCurrency.usd);

  static AppCurrency get currency => _currency;
  static String get symbol => _currency.symbol;

  /// Call when the user changes currency (also applied on app start).
  static void apply(AppCurrency currency) {
    _currency = currency;
    _full = _buildFull(currency);
    _compact = _buildCompact(currency);
  }

  static NumberFormat _buildFull(AppCurrency c) {
    return NumberFormat.currency(
      locale: c.locale,
      symbol: c.symbol,
      decimalDigits: c.decimalDigits,
    );
  }

  static NumberFormat _buildCompact(AppCurrency c) {
    return NumberFormat.compactCurrency(
      locale: c.locale,
      symbol: c.symbol,
      decimalDigits: c.decimalDigits == 0 ? 0 : 1,
    );
  }

  static String format(double amount) => _full.format(amount);

  static String formatCompact(double amount) => _compact.format(amount);

  /// Signed amount: expenses negative, income positive.
  static String formatSigned(double amount, {bool isExpense = false}) {
    final value = isExpense ? -amount.abs() : amount;
    final prefix = value < 0 ? '-' : (value > 0 ? '+' : '');
    return '$prefix${_full.format(value.abs())}';
  }
}
