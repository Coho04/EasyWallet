import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('PaymentRate Tests', () {
    setUp(() {
      Intl.defaultLocale = 'en_US';
    });

    test('translate returns correct value', () {
      // Without a loaded locale Intl hands the key back, which is what makes
      // a missing translation visible instead of blank.
      expect(PaymentRate.yearly.translate(), equals("yearly"));
      expect(PaymentRate.monthly.translate(), equals("monthly"));
    });

    test('findByName finds correct PaymentRate or defaults', () {
      expect(PaymentRate.findByName("yearly"), equals(PaymentRate.yearly));
      expect(PaymentRate.findByName("daily"), equals(PaymentRate.monthly));
    });

    test('all returns list of all payment rate values', () {
      List<String> expectedValues = [
        "weekly",
        "biweekly",
        "fourWeekly",
        "monthly",
        "bimonthly",
        "quarterly",
        "fourMonthly",
        "halfYearly",
        "yearly",
        "biennial",
      ];
      expect(PaymentRate.all(), equals(expectedValues));
    });

    test('finds every interval by the name it is stored under', () {
      // These strings sit in the database of every installed copy of the app.
      // Renaming one silently turns existing subscriptions monthly.
      for (final rate in PaymentRate.values) {
        expect(PaymentRate.findByName(rate.value), rate);
      }
    });

    test('is ordered from the shortest interval to the longest', () {
      final perYear = PaymentRate.values.map((r) => r.periodsPerYear).toList();
      for (var i = 1; i < perYear.length; i++) {
        expect(
          perYear[i],
          lessThan(perYear[i - 1]),
          reason: PaymentRate.values[i].value,
        );
      }
    });

    test('gives every interval its own abbreviation', () {
      final keys = PaymentRate.values.map((r) => r.shortLabelKey).toList();
      expect(keys.toSet().length, keys.length);
    });
  });

  group('PaymentRate amounts', () {
    test('spreads an amount over the months of its period', () {
      expect(PaymentRate.monthly.perMonth(10), closeTo(10, 0.001));
      expect(PaymentRate.quarterly.perMonth(30), closeTo(10, 0.001));
      expect(PaymentRate.fourMonthly.perMonth(40), closeTo(10, 0.001));
      expect(PaymentRate.halfYearly.perMonth(60), closeTo(10, 0.001));
      expect(PaymentRate.yearly.perMonth(120), closeTo(10, 0.001));
    });

    test('scales an amount up to a full year', () {
      expect(PaymentRate.monthly.perYear(10), closeTo(120, 0.001));
      expect(PaymentRate.quarterly.perYear(30), closeTo(120, 0.001));
      expect(PaymentRate.fourMonthly.perYear(40), closeTo(120, 0.001));
      expect(PaymentRate.halfYearly.perYear(60), closeTo(120, 0.001));
      expect(PaymentRate.yearly.perYear(120), closeTo(120, 0.001));
      expect(PaymentRate.biennial.perYear(240), closeTo(120, 0.001));
    });

    test('counts week-based intervals by the average year', () {
      // 365.2425 / 7 — a year has 52 weeks plus a day or two, so every few
      // years a 53rd weekly payment falls into it.
      expect(PaymentRate.weekly.perYear(10), closeTo(521.775, 0.001));
      expect(PaymentRate.biweekly.perYear(20), closeTo(521.775, 0.001));
      expect(PaymentRate.fourWeekly.perYear(40), closeTo(521.775, 0.001));
      expect(PaymentRate.weekly.perMonth(10), closeTo(43.481, 0.001));
    });

    test('a four-weekly price is more per year than the same monthly one', () {
      // Gyms bill every four weeks: 13 payments a year, not 12.
      expect(
        PaymentRate.fourWeekly.perYear(30),
        greaterThan(PaymentRate.monthly.perYear(30)),
      );
    });

    test('every interval is either week-based or month-based', () {
      for (final rate in PaymentRate.values) {
        expect(
          (rate.monthsPerPeriod > 0) != (rate.daysPerPeriod > 0),
          isTrue,
          reason: rate.value,
        );
      }
    });

    test('per month and per year stay consistent with each other', () {
      for (final rate in PaymentRate.values) {
        expect(rate.perYear(99), closeTo(rate.perMonth(99) * 12, 0.001));
      }
    });
  });

  group('PaymentRate.shift', () {
    final start = DateTime(2026, 1, 15);

    test('stays put on the very first occurrence', () {
      for (final rate in PaymentRate.values) {
        expect(rate.shift(start, 0), start);
      }
    });

    test('advances by the months of its period', () {
      expect(PaymentRate.monthly.shift(start, 1), DateTime(2026, 2, 15));
      expect(PaymentRate.quarterly.shift(start, 1), DateTime(2026, 4, 15));
      expect(PaymentRate.fourMonthly.shift(start, 1), DateTime(2026, 5, 15));
      expect(PaymentRate.halfYearly.shift(start, 1), DateTime(2026, 7, 15));
      expect(PaymentRate.yearly.shift(start, 1), DateTime(2027, 1, 15));
    });

    test('crosses the turn of the year', () {
      expect(
        PaymentRate.quarterly.shift(DateTime(2026, 11, 10), 1),
        DateTime(2027, 2, 10),
      );
      expect(
        PaymentRate.fourMonthly.shift(DateTime(2026, 10, 10), 2),
        DateTime(2027, 6, 10),
      );
    });

    test('keeps the anchor day instead of drifting through short months', () {
      // The 31st has no equivalent in April, but May must not inherit the
      // shortened day — otherwise a subscription walks backwards through the
      // calendar over the years.
      final endOfMonth = DateTime(2026, 1, 31);

      expect(PaymentRate.monthly.shift(endOfMonth, 1), DateTime(2026, 2, 28));
      expect(PaymentRate.monthly.shift(endOfMonth, 2), DateTime(2026, 3, 31));
      expect(PaymentRate.quarterly.shift(endOfMonth, 1), DateTime(2026, 4, 30));
      expect(PaymentRate.quarterly.shift(endOfMonth, 2), DateTime(2026, 7, 31));
    });

    test('handles the 29th of February in a leap year', () {
      final leapDay = DateTime(2024, 2, 29);

      expect(PaymentRate.yearly.shift(leapDay, 1), DateTime(2025, 2, 28));
      expect(PaymentRate.yearly.shift(leapDay, 4), DateTime(2028, 2, 29));
      expect(PaymentRate.quarterly.shift(leapDay, 4), DateTime(2025, 2, 28));
    });

    test('moves week-based intervals by whole days', () {
      expect(PaymentRate.weekly.shift(start, 1), DateTime(2026, 1, 22));
      expect(PaymentRate.biweekly.shift(start, 1), DateTime(2026, 1, 29));
      expect(PaymentRate.fourWeekly.shift(start, 1), DateTime(2026, 2, 12));
      expect(
        PaymentRate.weekly.shift(DateTime(2026, 12, 28), 1),
        DateTime(2027, 1, 4),
      );
    });

    test('keeps week-based billings at midnight across daylight saving', () {
      // 2026-03-29 is the switch to summer time in Europe.
      final next = PaymentRate.weekly.shift(DateTime(2026, 3, 25), 1);
      expect(next, DateTime(2026, 4, 1));
      expect(next.hour, 0);
    });

    test('moves the new month-based intervals', () {
      expect(PaymentRate.bimonthly.shift(start, 1), DateTime(2026, 3, 15));
      expect(PaymentRate.biennial.shift(start, 1), DateTime(2028, 1, 15));
    });

    test('lands on the same day as repeated single steps', () {
      for (final rate in PaymentRate.values) {
        var stepwise = DateTime(2026, 3, 20);
        for (var i = 0; i < 5; i++) {
          stepwise = rate.shift(stepwise, 1);
        }
        expect(
          rate.shift(DateTime(2026, 3, 20), 5),
          stepwise,
          reason: rate.value,
        );
      }
    });
  });
}
