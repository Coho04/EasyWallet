import 'package:easy_wallet/class/price_trend.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

PriceChange at(String isoDate, double amount) =>
    PriceChange(amount: amount, changedAt: DateTime.parse(isoDate));

Subscription sub({
  int id = 1,
  PaymentRate rate = PaymentRate.monthly,
  bool isPaused = false,
  DateTime? endDate,
  int? splitCount,
}) =>
    Subscription(
      id: id,
      amount: 10,
      date: DateTime(2024, 1, 1),
      endDate: endDate,
      splitCount: splitCount,
      isPaused: isPaused,
      isPinned: false,
      repeating: true,
      repeatPattern: rate.value,
      title: 'Test',
    );

void main() {
  group('PriceTrend.of', () {
    test('reports a rise from the oldest price to the current one', () {
      final trend = PriceTrend.of([
        at('2024-01-15T10:00:00', 9.99),
        at('2025-03-01T10:00:00', 12.99),
        at('2026-02-01T10:00:00', 14.19),
      ])!;

      expect(trend.first, 9.99);
      expect(trend.current, 14.19);
      expect(trend.since, DateTime.parse('2024-01-15T10:00:00'));
      expect(trend.change, closeTo(4.20, 0.001));
      expect(trend.percent, closeTo(42.04, 0.01));
      expect(trend.hasRisen, isTrue);
    });

    test('reports a drop as a negative change', () {
      final trend = PriceTrend.of([
        at('2024-01-15T10:00:00', 20.00),
        at('2026-01-15T10:00:00', 15.00),
      ])!;

      expect(trend.change, closeTo(-5, 0.001));
      expect(trend.percent, closeTo(-25, 0.01));
      expect(trend.hasRisen, isFalse);
    });

    test('a single recorded price is not a development', () {
      expect(PriceTrend.of([at('2024-01-15T10:00:00', 9.99)]), isNull);
      expect(PriceTrend.of([]), isNull);
    });

    test('ignores a change too small to show as money', () {
      // Floating point noise must not turn into "the price went up".
      expect(
        PriceTrend.of([
          at('2024-01-15T10:00:00', 9.99),
          at('2026-01-15T10:00:00', 9.990001),
        ]),
        isNull,
      );
    });

    test('reports a price that went up and back down again as unchanged', () {
      expect(
        PriceTrend.of([
          at('2024-01-01T10:00:00', 10),
          at('2025-01-01T10:00:00', 15),
          at('2026-01-01T10:00:00', 10),
        ]),
        isNull,
      );
    });

    test('calls a subscription that started free a zero percent change', () {
      final trend = PriceTrend.of([
        at('2024-01-01T10:00:00', 0),
        at('2026-01-01T10:00:00', 5),
      ])!;

      // Everything is an infinite increase over nothing, which is true and
      // useless — the absolute change is what carries meaning here.
      expect(trend.percent, 0);
      expect(trend.change, closeTo(5, 0.001));
    });
  });

  group('PriceTrend.yearlyIncrease', () {
    test('annualises each subscription before adding it up', () {
      // A yearly contract up by 12 and a monthly one up by 2 are not the same
      // thing: the monthly one costs 24 more per year, the yearly one 12.
      final increase = PriceTrend.yearlyIncrease(
        [
          sub(id: 1, rate: PaymentRate.yearly),
          sub(id: 2, rate: PaymentRate.monthly),
        ],
        {
          1: [at('2024-01-01T10:00:00', 100), at('2026-01-01T10:00:00', 112)],
          2: [at('2024-01-01T10:00:00', 8), at('2026-01-01T10:00:00', 10)],
        },
      );

      expect(increase, closeTo(36, 0.001));
    });

    test('annualises a quarterly increase over its four billings', () {
      final increase = PriceTrend.yearlyIncrease(
        [sub(id: 1, rate: PaymentRate.quarterly)],
        {
          1: [at('2024-01-01T10:00:00', 30), at('2026-01-01T10:00:00', 33)],
        },
      );

      expect(increase, closeTo(12, 0.001));
    });

    test('counts only the share a user carries of a split subscription', () {
      final increase = PriceTrend.yearlyIncrease(
        [sub(id: 1, rate: PaymentRate.monthly, splitCount: 4)],
        {
          1: [at('2024-01-01T10:00:00', 20), at('2026-01-01T10:00:00', 24)],
        },
      );

      expect(increase, closeTo(12, 0.001));
    });

    test('leaves out paused and expired subscriptions', () {
      final history = {
        1: [at('2024-01-01T10:00:00', 10), at('2026-01-01T10:00:00', 20)],
        2: [at('2024-01-01T10:00:00', 10), at('2026-01-01T10:00:00', 20)],
      };

      expect(
        PriceTrend.yearlyIncrease([sub(id: 1, isPaused: true)], history),
        0,
      );
      expect(
        PriceTrend.yearlyIncrease(
            [sub(id: 2, endDate: DateTime(2025, 1, 1))], history),
        0,
      );
    });

    test('subtracts a subscription that got cheaper', () {
      final increase = PriceTrend.yearlyIncrease(
        [sub(id: 1, rate: PaymentRate.monthly), sub(id: 2, rate: PaymentRate.monthly)],
        {
          1: [at('2024-01-01T10:00:00', 10), at('2026-01-01T10:00:00', 12)],
          2: [at('2024-01-01T10:00:00', 10), at('2026-01-01T10:00:00', 9)],
        },
      );

      expect(increase, closeTo(12, 0.001));
    });

    test('is zero without any recorded changes', () {
      expect(PriceTrend.yearlyIncrease([sub()], const {}), 0);
      expect(
        PriceTrend.yearlyIncrease([sub()], {
          1: [at('2024-01-01T10:00:00', 10)]
        }),
        0,
      );
    });
  });
}
