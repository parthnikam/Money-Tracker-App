import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/cards/domain/wallet_card.dart';
import '../../features/transactions/domain/category.dart';
import '../theme/app_colors.dart';
import 'hive_boxes.dart';

/// First-launch setup: empty finances only.
///
/// Seeds the default category catalog and a single zero-balance primary wallet
/// so the user can add or import transactions immediately. Does **not** preload
/// demo transactions, budgets, or savings.
Future<void> seedIfEmpty() async {
  final catBox = Hive.box(HiveBoxes.categories);
  if (catBox.isNotEmpty) {
    await migrateCategoryColorsToAccent();
    return;
  }

  final categories = defaultCategories();
  for (final c in categories) {
    await catBox.put(c.id, c.toMap());
  }

  final cardBox = Hive.box(HiveBoxes.cards);
  if (cardBox.isEmpty) {
    for (final c in _defaultCards()) {
      await cardBox.put(c.id, c.toMap());
    }
  }

  // Intentionally empty: transactions, budgets, savings.
}

/// One-time-ish: recolor category icons that still use non-accent / purple hues.
Future<void> migrateCategoryColorsToAccent() async {
  final catBox = Hive.box(HiveBoxes.categories);
  if (catBox.isEmpty) return;

  final settings = Hive.box(HiveBoxes.settings);
  // v2: every category icon uses the same solid accent (no dark/dim variants).
  if (settings.get('accent_cat_colors_v2') == true) return;

  final entries = catBox.values.toList();
  final uniform = AppColors.categoryDefaultColorValue;
  for (final entry in entries) {
    final raw = Map<dynamic, dynamic>.from(entry as Map);
    final cat = Category.fromMap(raw);
    if (cat.colorValue != uniform) {
      await catBox.put(
        cat.id,
        cat.copyWith(colorValue: uniform).toMap(),
      );
    }
  }

  await settings.put('accent_cat_colors_v2', true);
  await settings.put('accent_cat_colors_v1', true);
}

/// Icon grid matching `ui_design/categories.jpg`.
/// Circle colors use the accent scale (no purple / rainbow).
List<Category> defaultCategories() {
  const items = <(String id, String name, IconData icon)>[
    ('cat_baby', 'Baby', Icons.child_care),
    ('cat_beauty', 'Beauty', Icons.spa),
    ('cat_bills', 'Bills', Icons.receipt_long),
    ('cat_car', 'Car', Icons.directions_car),
    ('cat_clothing', 'Clothing', Icons.checkroom),
    ('cat_education', 'Education', Icons.school),
    ('cat_electronics', 'Electronics', Icons.devices),
    ('cat_ent', 'Entertainment', Icons.movie),
    ('cat_food', 'Food', Icons.restaurant),
    ('cat_health', 'Health', Icons.favorite),
    ('cat_home', 'Home', Icons.home),
    ('cat_insurance', 'Insurance', Icons.verified_user),
    ('cat_personal', 'Personal Care', Icons.account_balance_wallet),
    ('cat_shopping', 'Shopping', Icons.shopping_cart),
    ('cat_social', 'Social', Icons.groups),
    ('cat_sport', 'Sport', Icons.sports_tennis),
    ('cat_subs', 'Subscriptions', Icons.autorenew),
    ('cat_tax', 'Tax', Icons.request_quote),
    ('cat_phone', 'Telephone', Icons.phone_iphone),
    ('cat_transport', 'Transportation', Icons.directions_bus),
    ('cat_salary', 'Salary', Icons.payments),
  ];

  // Same accent for every category icon (consistent, not dimmed).
  final colorValue = AppColors.categoryDefaultColorValue;

  return [
    for (final item in items)
      Category(
        id: item.$1,
        name: item.$2,
        iconCodePoint: item.$3.codePoint,
        colorValue: colorValue,
        isDefault: true,
      ),
  ];
}

List<WalletCard> _defaultCards() {
  return [
    const WalletCard(
      id: 'card_main',
      name: 'Main Wallet',
      lastFour: '0000',
      holderName: 'You',
      balance: 0,
      gradientStart: 0xFFEA526F,
      gradientEnd: 0xFF9E2A40,
      brand: 'mastercard',
      isPrimary: true,
    ),
  ];
}
