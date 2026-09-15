import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription sub({
  required PaymentRate rate,
  DateTime? date,
  DateTime? endDate,
  double amount = 30,
  int? splitCount,
}) {
  return Subscription(
    amount: amount,
    date: date ?? DateTime(2026, 1, 15),
    endDate: endDate,
    splitCount: splitCount,
    isPaused: false,
    isPinned: false,
    repeating: true,
    repeatPattern: rate.value,
    title: 'Test',
  );
}

void main() {
  group('rate', () {
    test('reads the interval a subscription was stored with', () {
      for (final rate in PaymentRate.values) {
        expect(sub(rate: rate).rate, rate);
      }
    });

    test('falls back to monthly when nothing was stored', () {
      final legacy = Subscription(
        amount: 10,
        isPaused: false,
        isPinned: false,
        repeating: true,
        title: 'No interval',
      );

      // getRepeatPattern used to force-unwrap the field and crash here.
      expect(legacy.rate, PaymentRate.monthly);
      expect(legacy.getRepeatPattern(), PaymentRate.monthly);
    });
  });

  group('countPayment', () {
    test('counts one payment per period, not one per month', () {
      // The heart of the bug: a quarterly subscription counted monthly shows
      // three times the payments and three times the total.
      final quarterly = sub(rate: PaymentRate.quarterly);

      expect(
        quarterly.countPayment(asOf: DateTime(2026, 12, 31)),
        4,
      );
    });

    test('counts every interval over the same year', () {
      const expected = {
        PaymentRate.monthly: 12,
        PaymentRate.quarterly: 4,
        PaymentRate.fourMonthly: 3,
        PaymentRate.halfYearly: 2,
        PaymentRate.yearly: 1,
      };

      expected.forEach((rate, payments) {
        expect(
          sub(rate: rate, date: DateTime(2026, 1, 15))
              .countPayment(asOf: DateTime(2027, 1, 15)),
          payments,
          reason: rate.value,
        );
      });
    });

    test('counts nothing before the first billing', () {
      expect(
        sub(rate: PaymentRate.quarterly, date: DateTime(2026, 6, 1))
            .countPayment(asOf: DateTime(2026, 5, 1)),
        0,
      );
    });

    test('stops counting once the subscription has run out', () {
      final ended = sub(
        rate: PaymentRate.quarterly,
        date: DateTime(2026, 1, 15),
        endDate: DateTime(2026, 5, 1),
      );

      expect(ended.countPayment(asOf: DateTime(2026, 12, 31)), 2);
    });
  });

  group('sumPayment', () {
    test('agrees with the number of payments it counted', () {
      // The two used to walk the calendar differently — one in real months,
      // the other in 30-day steps — so a subscription could report a payment
      // count and a total that contradicted each other.
      for (final rate in PaymentRate.values) {
        final s = sub(rate: rate, amount: 25);
        final asOf = DateTime(2028, 6, 1);

        expect(
          s.sumPayment(asOf: asOf),
          closeTo(s.countPayment(asOf: asOf) * 25, 0.001),
          reason: rate.value,
        );
      }
    });

    test('adds up a quarterly year correctly', () {
      expect(
        sub(rate: PaymentRate.quarterly, amount: 30)
            .sumPayment(asOf: DateTime(2027, 1, 15)),
        closeTo(120, 0.001),
      );
    });
  });

  group('monthly and yearly equivalents', () {
    test('spreads a longer interval over its months', () {
      expect(sub(rate: PaymentRate.quarterly, amount: 30)
          .monthlyShareIn(null, null), closeTo(10, 0.001));
      expect(sub(rate: PaymentRate.fourMonthly, amount: 40)
          .monthlyShareIn(null, null), closeTo(10, 0.001));
      expect(sub(rate: PaymentRate.halfYearly, amount: 60)
          .monthlyShareIn(null, null), closeTo(10, 0.001));
    });

    test('scales every interval to the same year', () {
      expect(sub(rate: PaymentRate.quarterly, amount: 30)
          .yearlyShareIn(null, null), closeTo(120, 0.001));
      expect(sub(rate: PaymentRate.fourMonthly, amount: 40)
          .yearlyShareIn(null, null), closeTo(120, 0.001));
      expect(sub(rate: PaymentRate.halfYearly, amount: 60)
          .yearlyShareIn(null, null), closeTo(120, 0.001));
      expect(sub(rate: PaymentRate.yearly, amount: 120)
          .yearlyShareIn(null, null), closeTo(120, 0.001));
    });

    test('splits a shared subscription before spreading it', () {
      final shared =
          sub(rate: PaymentRate.quarterly, amount: 60, splitCount: 2);

      expect(shared.monthlyShareIn(null, null), closeTo(10, 0.001));
      expect(shared.yearlyShareIn(null, null), closeTo(120, 0.001));
    });
  });

  group('next and previous billing', () {
    test('finds the next billing of every interval', () {
      for (final rate in PaymentRate.values) {
        final s = sub(rate: rate, date: DateTime(2020, 3, 11));
        final next = s.getNextBillDate();

        expect(next.isAfter(DateTime.now()), isTrue, reason: rate.value);
        expect(next.day, 11, reason: rate.value);
        // The next billing has to be reachable from the start date in whole
        // periods, otherwise the schedule has drifted.
        final monthsApart =
            (next.year - 2020) * 12 + (next.month - 3);
        expect(monthsApart % rate.monthsPerPeriod, 0, reason: rate.value);
      }
    });

    test('never returns a negative number of remaining days', () {
      // Before, an interval that matched no branch left the next billing at
      // the start date, so this went negative and the list marked every such
      // subscription as overdue.
      for (final rate in PaymentRate.values) {
        expect(
          sub(rate: rate, date: DateTime(2019, 7, 4)).remainingDays(),
          greaterThan(0),
          reason: rate.value,
        );
      }
    });

    test('remaining days never exceed the length of the period', () {
      for (final rate in PaymentRate.values) {
        expect(
          sub(rate: rate, date: DateTime(2019, 7, 4)).remainingDays(),
          lessThanOrEqualTo(rate.monthsPerPeriod * 31),
          reason: rate.value,
        );
      }
    });

    test('the previous billing lies before the next one', () {
      for (final rate in PaymentRate.values) {
        final s = sub(rate: rate, date: DateTime(2019, 7, 4));
        final previous = s.calculatePreviousBillDate();

        expect(previous, isNotNull, reason: rate.value);
        expect(previous!.isBefore(s.getNextBillDate()), isTrue,
            reason: rate.value);
      }
    });

    test('a subscription that has not started reports its start date', () {
      final future =
          sub(rate: PaymentRate.quarterly, date: DateTime(2099, 5, 20));

      expect(future.calculatePreviousBillDate(), DateTime(2099, 5, 20));
    });
  });
}
