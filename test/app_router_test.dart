import 'package:app_v0/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('card edit and add routes match', () {
    final router = createAppRouter();

    final edit = router.configuration.findMatch(
      Uri.parse('/cards/edit/card_main'),
    );
    expect(edit.isError, isFalse, reason: edit.error?.message);
    expect(edit.pathParameters['id'], 'card_main');

    final add = router.configuration.findMatch(Uri.parse('/cards/add'));
    expect(add.isError, isFalse, reason: add.error?.message);
  });
}
