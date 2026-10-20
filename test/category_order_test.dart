import 'package:app_v0/features/transactions/domain/category.dart';
import 'package:flutter_test/flutter_test.dart';

Category _cat(String name) => Category(
      id: name,
      name: name,
      iconCodePoint: 0,
      colorValue: 0,
    );

void main() {
  test('main categories stay first, then the rest A–Z', () {
    final ordered = [
      _cat('Baby'),
      _cat('Health'),
      _cat('Zoo'),
      _cat('Food'),
      _cat('Education'),
      _cat('Personal Care'),
      _cat('Transport'),
      _cat('Apple'),
    ].sortedForDisplay();

    expect(
      ordered.map((c) => c.name).toList(),
      [
        'Food',
        'Transport',
        'Personal Care',
        'Education',
        'Health',
        'Apple',
        'Baby',
        'Zoo',
      ],
    );
  });
}
