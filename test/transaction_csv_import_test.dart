import 'package:app_v0/core/storage/transaction_csv_export.dart';
import 'package:app_v0/core/storage/transaction_csv_import.dart';
import 'package:app_v0/features/cards/domain/wallet_card.dart';
import 'package:app_v0/features/transactions/domain/category.dart';
import 'package:app_v0/features/transactions/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final categories = [
    Category(
      id: 'cat_food',
      name: 'Food',
      iconCodePoint: Icons.restaurant.codePoint,
      colorValue: 0xFFEA526F,
    ),
    Category(
      id: 'cat_transport',
      name: 'Transportation',
      iconCodePoint: Icons.directions_bus.codePoint,
      colorValue: 0xFFEA526F,
    ),
  ];
  final cards = [
    const WalletCard(
      id: 'card_main',
      name: 'Main Wallet',
      lastFour: '4821',
      holderName: 'You',
      balance: 1000,
      gradientStart: 0xFFEA526F,
      gradientEnd: 0xFF9E2A40,
      isPrimary: true,
    ),
  ];

  group('TransactionCsvImport.parseCsv', () {
    test('parses quoted fields and escaped quotes', () {
      const raw = 'a,"b,c","say ""hi"""\nx,y,z\n';
      final rows = TransactionCsvImport.parseCsv(raw);
      expect(rows.length, 2);
      expect(rows[0], ['a', 'b,c', 'say "hi"']);
      expect(rows[1], ['x', 'y', 'z']);
    });
  });

  group('TransactionCsvImport.parse', () {
    test('parses export-format CSV into transactions', () {
      final csv = TransactionCsvExport.buildCsv(
        transactions: [
          Transaction(
            id: 'tx_import_1',
            title: 'Coffee, please',
            amount: 4.5,
            type: TransactionType.expense,
            categoryId: 'cat_food',
            cardId: 'card_main',
            date: DateTime(2026, 7, 17, 10, 30),
            note: 'Morning "latte"',
            paymentMethod: 'Card',
          ),
          Transaction(
            id: 'tx_import_2',
            title: 'Salary',
            amount: 3000,
            type: TransactionType.income,
            categoryId: 'cat_food',
            cardId: 'card_main',
            date: DateTime(2026, 7, 1, 9, 0),
          ),
        ],
        categories: categories,
        cards: cards,
      );

      final result = TransactionCsvImport.parse(
        csv: csv,
        categories: categories,
        cards: cards,
        existingIds: {},
      );

      expect(result.importedCount, 2);
      expect(result.skippedDuplicates, 0);
      final byId = {for (final t in result.transactions) t.id: t};
      expect(byId['tx_import_1']!.title, 'Coffee, please');
      expect(byId['tx_import_1']!.amount, 4.5);
      expect(byId['tx_import_1']!.type, TransactionType.expense);
      expect(byId['tx_import_1']!.note, 'Morning "latte"');
      expect(byId['tx_import_2']!.type, TransactionType.income);
      expect(byId['tx_import_2']!.amount, 3000);
    });

    test('skips rows whose id already exists (append-only)', () {
      const csv = '''
id,date,type,title,amount,category,category_id,account,account_id,payment_method,notes
existing,2026-01-01 10:00,expense,Old,10.00,Food,cat_food,Main Wallet,card_main,Card,
new_one,2026-01-02 10:00,expense,New,20.00,Food,cat_food,Main Wallet,card_main,Card,
''';
      final result = TransactionCsvImport.parse(
        csv: csv,
        categories: categories,
        cards: cards,
        existingIds: {'existing'},
      );

      expect(result.importedCount, 1);
      expect(result.skippedDuplicates, 1);
      expect(result.transactions.single.id, 'new_one');
      expect(result.transactions.single.amount, 20);
    });

    test('resolves category by name when id missing', () {
      const csv = '''
id,date,type,title,amount,category,category_id,account,account_id,payment_method,notes
a1,2026-03-01 12:00,expense,Uber,150.00,Transportation,,Main Wallet,,Card,ride
''';
      final result = TransactionCsvImport.parse(
        csv: csv,
        categories: categories,
        cards: cards,
        existingIds: {},
      );

      expect(result.importedCount, 1);
      expect(result.transactions.single.categoryId, 'cat_transport');
      expect(result.transactions.single.cardId, 'card_main');
    });

    test('throws when required columns missing', () {
      expect(
        () => TransactionCsvImport.parse(
          csv: 'foo,bar\n1,2\n',
          categories: categories,
          cards: cards,
          existingIds: {},
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
