import 'package:app_v0/features/cards/domain/wallet_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const card = WalletCard(
    id: 'c1',
    name: 'Travel',
    bankName: 'HDFC',
    lastFour: '4242',
    holderName: 'You',
    balance: 12.5,
    gradientStart: 0xFFEA526F,
    gradientEnd: 0xFF9E2A40,
  );

  test('bankName round-trips through the hive map', () {
    final restored = WalletCard.fromMap(card.toMap());
    expect(restored.bankName, 'HDFC');
    expect(restored.issuerLabel, 'HDFC');
    expect(restored.name, card.name);
    expect(restored.isPrimary, false);
  });

  test('missing bankName on old rows stays empty', () {
    final map = card.toMap()..remove('bankName');
    final restored = WalletCard.fromMap(map);
    expect(restored.bankName, '');
  });

  test('issuer falls back to a real brand, not the generic card token', () {
    expect(card.copyWith(bankName: '').issuerLabel, '');
    expect(
      card.copyWith(bankName: '', brand: 'mastercard').issuerLabel,
      'mastercard',
    );
    expect(card.copyWith(bankName: '  Chase  ').issuerLabel, 'Chase');
  });
}
