import 'package:app_v0/core/storage/transaction_csv_export.dart';
import 'package:app_v0/features/cards/domain/wallet_card.dart';
import 'package:app_v0/features/transactions/domain/category.dart';
import 'package:app_v0/features/transactions/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionCsvExport', () {
    test('escapeCsvField quotes commas and doubles quotes', () {
      expect(TransactionCsvExport.escapeCsvField('plain'), 'plain');
      expect(TransactionCsvExport.escapeCsvField('a,b'), '"a,b"');
      expect(TransactionCsvExport.escapeCsvField('say "hi"'), '"say ""hi"""');
      expect(TransactionCsvExport.escapeCsvField('line\nbreak'), '"line\nbreak"');
    });

    test('buildCsv includes header and transaction rows', () {
      final categories = [
        Category(
          id: 'cat_food',
          name: 'Food',
          iconCodePoint: Icons.restaurant.codePoint,
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
      final transactions = [
        Transaction(
          id: 'tx1',
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
          id: 'tx2',
          title: 'Salary',
          amount: 3000,
          type: TransactionType.income,
          categoryId: 'cat_food',
          cardId: 'card_main',
          date: DateTime(2026, 7, 1, 9, 0),
        ),
      ];

      final csv = TransactionCsvExport.buildCsv(
        transactions: transactions,
        categories: categories,
        cards: cards,
      );

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains(TransactionCsvExport.csvHeader.join(',')));
      expect(csv, contains('tx1'));
      expect(csv, contains('tx2'));
      expect(csv, contains('expense'));
      expect(csv, contains('income'));
      expect(csv, contains('Food'));
      expect(csv, contains('Main Wallet'));
      expect(csv, contains('"Coffee, please"'));
      expect(csv, contains('"Morning ""latte"""'));
      // Newest first
      final i1 = csv.indexOf('tx1');
      final i2 = csv.indexOf('tx2');
      expect(i1, lessThan(i2));
    });

    test('buildCsv works with empty lists', () {
      final csv = TransactionCsvExport.buildCsv(
        transactions: const [],
        categories: const [],
        cards: const [],
      );
      expect(csv, contains('id,date,type,title,amount'));
      final lines = csv.trim().split('\n');
      // BOM line + header only
      expect(lines.length, 1);
    });
  });
}
