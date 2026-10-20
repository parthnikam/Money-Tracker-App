import 'package:flutter/material.dart';

/// A payment card / wallet the user spends from.
class WalletCard {
  const WalletCard({
    required this.id,
    required this.name,
    required this.lastFour,
    required this.holderName,
    required this.balance,
    required this.gradientStart,
    required this.gradientEnd,
    this.bankName = '',
    this.brand = 'card',
    this.isPrimary = false,
  });

  final String id;
  final String name;

  /// Issuing bank, printed on the card face. Empty until the user sets one.
  final String bankName;
  final String lastFour;
  final String holderName;
  final double balance;
  final int gradientStart;
  final int gradientEnd;
  final String brand;

  /// Text on the card face. A set bank name wins over the stored network brand.
  String get issuerLabel {
    final bank = bankName.trim();
    if (bank.isNotEmpty) return bank;
    final network = brand.trim();
    if (network.isEmpty || network.toLowerCase() == 'card') return '';
    return network;
  }

  /// Default account when adding expenses.
  final bool isPrimary;

  Color get startColor => Color(gradientStart);
  Color get endColor => Color(gradientEnd);

  WalletCard copyWith({
    String? id,
    String? name,
    String? bankName,
    String? lastFour,
    String? holderName,
    double? balance,
    int? gradientStart,
    int? gradientEnd,
    String? brand,
    bool? isPrimary,
  }) {
    return WalletCard(
      id: id ?? this.id,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      lastFour: lastFour ?? this.lastFour,
      holderName: holderName ?? this.holderName,
      balance: balance ?? this.balance,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      brand: brand ?? this.brand,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'bankName': bankName,
    'lastFour': lastFour,
    'holderName': holderName,
    'balance': balance,
    'gradientStart': gradientStart,
    'gradientEnd': gradientEnd,
    'brand': brand,
    'isPrimary': isPrimary,
  };

  factory WalletCard.fromMap(Map<dynamic, dynamic> map) {
    return WalletCard(
      id: map['id'] as String,
      name: map['name'] as String,
      bankName: map['bankName'] as String? ?? '',
      lastFour: map['lastFour'] as String,
      holderName: map['holderName'] as String,
      balance: (map['balance'] as num).toDouble(),
      gradientStart: map['gradientStart'] as int,
      gradientEnd: map['gradientEnd'] as int,
      brand: map['brand'] as String? ?? 'card',
      isPrimary:
          map['isPrimary'] as bool? ??
          // Back-compat: treat seeded main wallet as primary.
          map['id'] == 'card_main',
    );
  }
}

extension WalletCardListX on List<WalletCard> {
  /// Preferred account for new expenses.
  WalletCard? get primaryOrFirst {
    if (isEmpty) return null;
    return where((c) => c.isPrimary).firstOrNull ??
        where((c) => c.id == 'card_main').firstOrNull ??
        first;
  }
}
