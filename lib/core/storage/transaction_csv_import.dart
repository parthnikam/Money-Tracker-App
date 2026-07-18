import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../features/cards/domain/card_repository.dart';
import '../../features/cards/domain/wallet_card.dart';
import '../../features/transactions/domain/category.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/transactions/domain/transaction_repository.dart';
import 'transaction_csv_export.dart';

/// Result of parsing a transactions CSV (no storage writes).
class TransactionCsvParseResult {
  const TransactionCsvParseResult({
    required this.transactions,
    this.skippedEmpty = 0,
    this.skippedDuplicates = 0,
    this.rowErrors = const [],
  });

  final List<Transaction> transactions;
  final int skippedEmpty;
  final int skippedDuplicates;
  final List<String> rowErrors;

  int get importedCount => transactions.length;
  bool get hasRows => transactions.isNotEmpty;
}

/// Result after appending parsed transactions to local storage.
class TransactionCsvImportResult {
  const TransactionCsvImportResult({
    required this.importedCount,
    this.skippedDuplicates = 0,
    this.skippedEmpty = 0,
    this.rowErrors = const [],
  });

  final int importedCount;
  final int skippedDuplicates;
  final int skippedEmpty;
  final List<String> rowErrors;
}

/// CSV import for transactions in the app export format.
///
/// Expected columns (header, order flexible):
/// [TransactionCsvExport.csvHeader]
///
/// Behaviour: **append only** — never overwrites existing transactions.
/// Rows whose `id` already exists are skipped.
class TransactionCsvImport {
  TransactionCsvImport._();

  static const _uuid = Uuid();

  /// Parses [csv] into domain [Transaction]s ready to append.
  static TransactionCsvParseResult parse({
    required String csv,
    required List<Category> categories,
    required List<WalletCard> cards,
    required Set<String> existingIds,
  }) {
    final text = csv.replaceFirst(RegExp(r'^\uFEFF'), '');
    final rows = parseCsv(text);
    if (rows.isEmpty) {
      return const TransactionCsvParseResult(transactions: []);
    }

    final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
    final col = _columnIndex(header);
    if (col['amount'] == null || col['date'] == null) {
      throw FormatException(
        'CSV must include at least "date" and "amount" columns. '
        'Expected export format: ${TransactionCsvExport.csvHeader.join(', ')}',
      );
    }

    final catById = {for (final c in categories) c.id: c};
    final catByName = {
      for (final c in categories) c.name.trim().toLowerCase(): c,
    };
    final cardById = {for (final c in cards) c.id: c};
    final cardByName = {
      for (final c in cards) c.name.trim().toLowerCase(): c,
    };
    WalletCard? fallbackCard;
    for (final c in cards) {
      if (c.isPrimary) {
        fallbackCard = c;
        break;
      }
    }
    fallbackCard ??= cards.isNotEmpty ? cards.first : null;
    final fallbackCategory = categories.isNotEmpty
        ? (catById['cat_food'] ?? categories.first)
        : null;

    if (fallbackCard == null) {
      throw StateError(
        'No wallet/card available to attach imported transactions.',
      );
    }
    if (fallbackCategory == null) {
      throw StateError(
        'No categories available to attach imported transactions.',
      );
    }

    final usedIds = Set<String>.from(existingIds);
    final out = <Transaction>[];
    var skippedEmpty = 0;
    var skippedDuplicates = 0;
    final errors = <String>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((c) => c.trim().isEmpty)) {
        skippedEmpty++;
        continue;
      }

      final lineNo = i + 1;
      try {
        final amountRaw = _cell(row, col['amount']).trim();
        if (amountRaw.isEmpty) {
          skippedEmpty++;
          continue;
        }
        final amount = double.tryParse(amountRaw.replaceAll(',', ''));
        if (amount == null || amount <= 0) {
          errors.add('Row $lineNo: invalid amount "$amountRaw"');
          continue;
        }

        final dateRaw = _cell(row, col['date']).trim();
        final date = _parseDate(dateRaw);
        if (date == null) {
          errors.add('Row $lineNo: invalid date "$dateRaw"');
          continue;
        }

        final typeRaw = _cell(row, col['type']).trim().toLowerCase();
        final type = typeRaw.contains('income') || typeRaw == '(+)'
            ? TransactionType.income
            : TransactionType.expense;

        final titleRaw = _cell(row, col['title']).trim();
        final notes = _cell(row, col['notes']).trim();
        final title = titleRaw.isNotEmpty
            ? titleRaw
            : (notes.isNotEmpty
                ? notes
                : (type == TransactionType.income ? 'Income' : 'Expense'));

        final categoryIdRaw = _cell(row, col['category_id']).trim();
        final categoryNameRaw = _cell(row, col['category']).trim();
        final category = catById[categoryIdRaw] ??
            catByName[categoryNameRaw.toLowerCase()] ??
            fallbackCategory;

        final accountIdRaw = _cell(row, col['account_id']).trim();
        final accountNameRaw = _cell(row, col['account']).trim();
        final card = cardById[accountIdRaw] ??
            cardByName[accountNameRaw.toLowerCase()] ??
            fallbackCard;

        final payment = _cell(row, col['payment_method']).trim();
        final idRaw = _cell(row, col['id']).trim();

        String id;
        if (idRaw.isNotEmpty) {
          if (usedIds.contains(idRaw)) {
            skippedDuplicates++;
            continue;
          }
          id = idRaw;
        } else {
          id = _uuid.v4();
        }
        usedIds.add(id);

        out.add(
          Transaction(
            id: id,
            title: title,
            amount: amount,
            type: type,
            categoryId: category.id,
            cardId: card.id,
            date: date,
            note: notes.isEmpty ? null : notes,
            paymentMethod: payment.isEmpty ? null : payment,
          ),
        );
      } catch (e) {
        errors.add('Row $lineNo: $e');
      }
    }

    return TransactionCsvParseResult(
      transactions: out,
      skippedEmpty: skippedEmpty,
      skippedDuplicates: skippedDuplicates,
      rowErrors: errors,
    );
  }

  /// Parses [csv], appends new transactions, and adjusts card balances.
  static Future<TransactionCsvImportResult> importAndAppend({
    required String csv,
    required List<Category> categories,
    required List<WalletCard> cards,
    required TransactionRepository transactionRepository,
    required CardRepository cardRepository,
  }) async {
    final existing = await transactionRepository.getAll();
    final existingIds = existing.map((t) => t.id).toSet();

    final parsed = parse(
      csv: csv,
      categories: categories,
      cards: cards,
      existingIds: existingIds,
    );

    if (parsed.transactions.isEmpty) {
      return TransactionCsvImportResult(
        importedCount: 0,
        skippedDuplicates: parsed.skippedDuplicates,
        skippedEmpty: parsed.skippedEmpty,
        rowErrors: parsed.rowErrors,
      );
    }

    // Working balance map so multi-row imports stay consistent.
    final cardById = {for (final c in cards) c.id: c};
    final balanceByCard = {
      for (final c in cards) c.id: c.balance,
    };

    for (final tx in parsed.transactions) {
      await transactionRepository.add(tx);
      final card = cardById[tx.cardId];
      final current = balanceByCard[tx.cardId];
      if (card == null || current == null) continue;
      final delta = tx.isIncome ? tx.amount : -tx.amount;
      final next = current + delta;
      balanceByCard[tx.cardId] = next;
      await cardRepository.update(card.copyWith(balance: next));
    }

    return TransactionCsvImportResult(
      importedCount: parsed.transactions.length,
      skippedDuplicates: parsed.skippedDuplicates,
      skippedEmpty: parsed.skippedEmpty,
      rowErrors: parsed.rowErrors,
    );
  }

  // ── CSV helpers ─────────────────────────────────────────────

  /// RFC4180-style CSV parse (quoted fields, escaped quotes).
  @visibleForTesting
  static List<List<String>> parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;
    final s = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < s.length && s[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',') {
          row.add(field.toString());
          field.clear();
        } else if (ch == '\n') {
          row.add(field.toString());
          field.clear();
          // Keep trailing empty last line out
          if (row.any((c) => c.isNotEmpty)) {
            rows.add(row);
          }
          row = <String>[];
        } else {
          field.write(ch);
        }
      }
    }
    // last field / row
    row.add(field.toString());
    if (row.any((c) => c.isNotEmpty)) {
      rows.add(row);
    }
    return rows;
  }

  static Map<String, int?> _columnIndex(List<String> header) {
    int? idx(List<String> aliases) {
      for (final a in aliases) {
        final i = header.indexOf(a);
        if (i >= 0) return i;
      }
      return null;
    }

    return {
      'id': idx(['id']),
      'date': idx(['date', 'time', 'datetime']),
      'type': idx(['type']),
      'title': idx(['title', 'item', 'name']),
      'amount': idx(['amount']),
      'category': idx(['category']),
      'category_id': idx(['category_id', 'categoryid']),
      'account': idx(['account']),
      'account_id': idx(['account_id', 'accountid', 'card_id']),
      'payment_method': idx(['payment_method', 'paymentmethod', 'payment']),
      'notes': idx(['notes', 'note', 'description']),
    };
  }

  static String _cell(List<String> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return '';
    return row[index];
  }

  static DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    final trimmed = raw.trim();
    // ISO first
    try {
      return DateTime.parse(trimmed);
    } catch (_) {}

    const formats = [
      'yyyy-MM-dd HH:mm',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd',
      'MMM dd, yyyy h:mm a',
      'MMM d, yyyy h:mm a',
      'dd/MM/yyyy HH:mm',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
    ];
    for (final f in formats) {
      try {
        return DateFormat(f).parse(trimmed);
      } catch (_) {}
    }
    return null;
  }
}
