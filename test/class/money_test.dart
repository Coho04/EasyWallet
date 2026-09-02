import 'package:easy_wallet/class/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.format', () {
    test('puts the amount before the symbol', () {
      expect(Money.format(17.99, '€', locale: 'en'), '17.99 €');
    });

    test('always shows two decimals', () {
      expect(Money.format(5, '€', locale: 'en'), '5.00 €');
      expect(Money.format(0, '\$', locale: 'en'), '0.00 \$');
    });

    test('rounds to two decimals', () {
      // 1.005 is not representable as a double (it is 1.00499...), so a value
      // that actually rounds up is used here.
      expect(Money.format(1.006, '€', locale: 'en'), '1.01 €');
      expect(Money.format(2.344, '€', locale: 'en'), '2.34 €');
    });

    test('uses the decimal separator of the locale', () {
      expect(Money.format(5.99, '€', locale: 'de'), '5,99 €');
      expect(Money.format(5.99, '€', locale: 'en'), '5.99 €');
    });

    test('groups thousands the way the locale does', () {
      expect(Money.format(1234.5, '€', locale: 'de'), '1.234,50 €');
      expect(Money.format(1234.5, '€', locale: 'en'), '1,234.50 €');
    });

    test('keeps negative amounts readable', () {
      expect(Money.format(-3.5, '€', locale: 'en'), '-3.50 €');
    });
  });
}
