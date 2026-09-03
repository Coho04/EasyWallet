import 'package:easy_wallet/class/exchange_rates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Frankfurter answers with a base and the rates relative to it.
  final rates = ExchangeRates(
    base: 'EUR',
    rates: const {'USD': 1.10, 'GBP': 0.85, 'CHF': 0.95},
    fetchedAt: DateTime(2026, 9, 3),
  );

  group('ExchangeRates.convert', () {
    test('returns the amount unchanged for the same currency', () {
      expect(rates.convert(10, from: 'USD', to: 'USD'), 10);
      expect(rates.convert(10, from: 'EUR', to: 'EUR'), 10);
    });

    test('converts from the base into another currency', () {
      expect(rates.convert(10, from: 'EUR', to: 'USD'), closeTo(11.0, 0.001));
    });

    test('converts into the base', () {
      expect(rates.convert(11, from: 'USD', to: 'EUR'), closeTo(10.0, 0.001));
    });

    test('converts between two non base currencies', () {
      // 8.50 GBP -> 10 EUR -> 11 USD
      expect(rates.convert(8.5, from: 'GBP', to: 'USD'), closeTo(11.0, 0.001));
    });

    test('is case insensitive about currency codes', () {
      expect(rates.convert(10, from: 'eur', to: 'usd'), closeTo(11.0, 0.001));
    });

    test('leaves the amount alone when a rate is missing', () {
      expect(rates.convert(10, from: 'EUR', to: 'XYZ'), 10);
      expect(rates.convert(10, from: 'XYZ', to: 'EUR'), 10);
    });

    test('knows when it is too old to be trusted', () {
      expect(rates.isStaleAt(DateTime(2026, 9, 3, 11)), isFalse);
      expect(rates.isStaleAt(DateTime(2026, 9, 4, 1)), isTrue);
    });
  });

  group('ExchangeRates serialisation', () {
    test('survives being stored and read back', () {
      final restored = ExchangeRates.fromJson(rates.toJson());

      expect(restored.base, 'EUR');
      expect(restored.rates['USD'], 1.10);
      expect(restored.fetchedAt, rates.fetchedAt);
    });

    test('reads the shape the API answers with', () {
      final parsed = ExchangeRates.fromApi(
        {
          'base': 'EUR',
          'date': '2026-09-03',
          'rates': {'USD': 1.1, 'GBP': 0.85},
        },
        fetchedAt: DateTime(2026, 9, 3),
      );

      expect(parsed.base, 'EUR');
      expect(parsed.convert(10, from: 'EUR', to: 'USD'), closeTo(11.0, 0.001));
    });
  });
}
