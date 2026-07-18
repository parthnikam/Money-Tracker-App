import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/cards/domain/wallet_card.dart';
import '../../features/transactions/domain/category.dart';
import '../../features/transactions/domain/transaction.dart';
import 'csv_export_io.dart'
    if (dart.library.html) 'csv_export_stub.dart' as csv_io;

/// Result of a CSV export.
class TransactionExportResult {
  const TransactionExportResult({
    required this.fileName,
    required this.rowCount,
    this.path,
    this.shared = false,
    this.shareError,
  });

  final String fileName;
  final int rowCount;

  /// Absolute path when a local file was written; null for share-only / web.
  final String? path;

  final bool shared;
  final String? shareError;
}

/// CSV export for all local transactions (Hive).
///
/// Primary path uses in-memory [XFile.fromData] (no path_provider / dart:io).
/// Optional disk write uses a conditional import that is a no-op on web.
class TransactionCsvExport {
  TransactionCsvExport._();

  static const csvHeader = [
    'id',
    'date',
    'type',
    'title',
    'amount',
    'category',
    'category_id',
    'account',
    'account_id',
    'payment_method',
    'notes',
  ];

  /// Builds a full CSV document string (header + rows).
  static String buildCsv({
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<WalletCard> cards,
  }) {
    final catById = {for (final c in categories) c.id: c};
    final cardById = {for (final c in cards) c.id: c};
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final buffer = StringBuffer();
    // UTF-8 BOM helps Excel open UTF-8 CSV correctly on Windows.
    buffer.write('\uFEFF');
    buffer.writeln(csvHeader.map(escapeCsvField).join(','));

    for (final tx in sorted) {
      final cat = catById[tx.categoryId];
      final card = cardById[tx.cardId];
      buffer.writeln(
        [
          tx.id,
          dateFmt.format(tx.date),
          tx.type.name,
          tx.title,
          tx.amount.toStringAsFixed(2),
          cat?.name ?? '',
          tx.categoryId,
          card?.name ?? '',
          tx.cardId,
          tx.paymentMethod ?? '',
          tx.note ?? '',
        ].map((field) => escapeCsvField(field)).join(','),
      );
    }

    return buffer.toString();
  }

  @visibleForTesting
  static String escapeCsvField(String value) {
    final needsQuotes = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  static String _fileName() {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'moneytracker_transactions_$stamp.csv';
  }

  /// Exports CSV via the system share sheet (in-memory).
  static Future<TransactionExportResult> export({
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<WalletCard> cards,
  }) async {
    final csv = buildCsv(
      transactions: transactions,
      categories: categories,
      cards: cards,
    );
    final name = _fileName();
    final bytes = Uint8List.fromList(utf8.encode(csv));

    var shared = false;
    String? shareError;
    String? savedPath;

    // Always try to write a local copy on native platforms (no path_provider).
    if (!kIsWeb) {
      try {
        savedPath = await csv_io.writeCsvBytesToDisk(bytes, name);
      } catch (_) {
        // Non-fatal — share may still work.
      }
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'text/csv',
              name: name,
            ),
          ],
          subject: 'OctoFin transactions',
          text:
              'Exported ${transactions.length} transactions from OctoFin.',
        ),
      );
      shared = true;
    } catch (e) {
      shareError = e.toString();
    }

    // Consider success if we either shared or saved a file.
    if (!shared && savedPath == null) {
      throw StateError(
        shareError ?? 'Could not share or save the CSV export.',
      );
    }

    return TransactionExportResult(
      fileName: name,
      rowCount: transactions.length,
      path: savedPath,
      shared: shared,
      shareError: shareError,
    );
  }
}
