import 'package:easy_wallet/class/billing_schedule.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription sub({
  required String title,
  DateTime? date,
  DateTime? endDate,
  String? repeatPattern = 'monthly',
  bool repeating = true,
  bool isPaused = false,
  double amount = 9.99,
}) {
  return Subscription(
    amount: amount,
    date: date,
    endDate: endDate,
    isPaused: isPaused,
    isPinned: false,
    repeating: repeating,
    repeatPattern: repeatPattern,
    title: title,
  );
}

void main() {
  group('BillingSchedule.datesFor', () {
    test('expands a monthly subscription across the requested range', () {
      final netflix = sub(title: 'Netflix', date: DateTime(2026, 1, 15));

      final dates = BillingSchedule.datesFor(
        netflix,
        DateTime(2026, 3, 1),
        DateTime(2026, 5, 31),
      );

      expect(dates, [
        DateTime(2026, 3, 15),
        DateTime(2026, 4, 15),
        DateTime(2026, 5, 15),
      ]);
    });

    test('expands a yearly subscription across the requested range', () {
      final domain = sub(
        title: 'Domain',
        date: DateTime(2024, 3, 10),
        repeatPattern: PaymentRate.yearly.value,
      );

      final dates = BillingSchedule.datesFor(
        domain,
        DateTime(2026, 1, 1),
        DateTime(2026, 12, 31),
      );

      expect(dates, [DateTime(2026, 3, 10)]);
    });

    test('keeps the original day as anchor instead of drifting', () {
      final rent = sub(title: 'Rent', date: DateTime(2026, 1, 31));

      final dates = BillingSchedule.datesFor(
        rent,
        DateTime(2026, 1, 1),
        DateTime(2026, 4, 30),
      );

      expect(dates, [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
      ]);
    });

    test('clamps to 29 February in a leap year', () {
      final rent = sub(title: 'Rent', date: DateTime(2024, 1, 31));

      final dates = BillingSchedule.datesFor(
        rent,
        DateTime(2024, 2, 1),
        DateTime(2024, 2, 29),
      );

      expect(dates, [DateTime(2024, 2, 29)]);
    });

    test('returns occurrences that lie in the past for the given range', () {
      final gym = sub(title: 'Gym', date: DateTime(2020, 6, 5));

      final dates = BillingSchedule.datesFor(
        gym,
        DateTime(2020, 6, 1),
        DateTime(2020, 8, 31),
      );

      expect(dates, [
        DateTime(2020, 6, 5),
        DateTime(2020, 7, 5),
        DateTime(2020, 8, 5),
      ]);
    });

    test('never returns dates before the subscription started', () {
      final music = sub(title: 'Music', date: DateTime(2026, 6, 10));

      final dates = BillingSchedule.datesFor(
        music,
        DateTime(2026, 1, 1),
        DateTime(2026, 7, 31),
      );

      expect(dates, [DateTime(2026, 6, 10), DateTime(2026, 7, 10)]);
    });

    test('yields a single date for a non-repeating subscription', () {
      final oneOff = sub(
        title: 'One off',
        date: DateTime(2026, 5, 4),
        repeating: false,
        repeatPattern: null,
      );

      expect(
        BillingSchedule.datesFor(
            oneOff, DateTime(2026, 5, 1), DateTime(2026, 5, 31)),
        [DateTime(2026, 5, 4)],
      );
      expect(
        BillingSchedule.datesFor(
            oneOff, DateTime(2026, 6, 1), DateTime(2026, 6, 30)),
        isEmpty,
      );
    });

    test('yields nothing when the subscription has no date', () {
      final undated = sub(title: 'Undated', date: null);

      expect(
        BillingSchedule.datesFor(
            undated, DateTime(2026, 1, 1), DateTime(2026, 12, 31)),
        isEmpty,
      );
    });
  });

  group('BillingSchedule.byDay', () {
    test('groups occurrences of all subscriptions by day', () {
      final netflix = sub(title: 'Netflix', date: DateTime(2026, 9, 11));
      final spotify = sub(title: 'Spotify', date: DateTime(2026, 9, 11));
      final gym = sub(title: 'Gym', date: DateTime(2026, 9, 3));

      final byDay = BillingSchedule.byDay(
        [netflix, spotify, gym],
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 30),
      );

      expect(byDay.keys, containsAll([DateTime(2026, 9, 3), DateTime(2026, 9, 11)]));
      expect(
        byDay[DateTime(2026, 9, 11)]!.map((o) => o.subscription.title),
        ['Netflix', 'Spotify'],
      );
      expect(byDay[DateTime(2026, 9, 3)]!.single.subscription.title, 'Gym');
    });

    test('includes paused subscriptions so the view can grey them out', () {
      final paused = sub(
        title: 'Paused',
        date: DateTime(2026, 9, 8),
        isPaused: true,
      );

      final byDay = BillingSchedule.byDay(
        [paused],
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 30),
      );

      expect(byDay[DateTime(2026, 9, 8)]!.single.subscription.isPaused, isTrue);
    });

    test('omits days without any occurrence', () {
      final netflix = sub(title: 'Netflix', date: DateTime(2026, 9, 11));

      final byDay = BillingSchedule.byDay(
        [netflix],
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 30),
      );

      expect(byDay.length, 1);
      expect(byDay.containsKey(DateTime(2026, 9, 12)), isFalse);
    });
  });

  group('BillingSchedule.datesFor with an end date', () {
    test('stops expanding after the end date', () {
      final gym = sub(
        title: 'Gym',
        date: DateTime(2026, 1, 10),
        endDate: DateTime(2026, 3, 31),
      );

      final dates = BillingSchedule.datesFor(
        gym,
        DateTime(2026, 1, 1),
        DateTime(2026, 6, 30),
      );

      expect(dates, [
        DateTime(2026, 1, 10),
        DateTime(2026, 2, 10),
        DateTime(2026, 3, 10),
      ]);
    });

    test('still bills on the end date itself', () {
      final gym = sub(
        title: 'Gym',
        date: DateTime(2026, 1, 10),
        endDate: DateTime(2026, 3, 10),
      );

      final dates = BillingSchedule.datesFor(
        gym,
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 31),
      );

      expect(dates, [DateTime(2026, 3, 10)]);
    });

    test('yields nothing when the end date precedes the start', () {
      final gym = sub(
        title: 'Gym',
        date: DateTime(2026, 5, 10),
        endDate: DateTime(2026, 1, 1),
      );

      expect(
        BillingSchedule.datesFor(
            gym, DateTime(2026, 1, 1), DateTime(2026, 12, 31)),
        isEmpty,
      );
    });

    test('bounds a non-repeating subscription too', () {
      final oneOff = sub(
        title: 'One off',
        date: DateTime(2026, 5, 4),
        endDate: DateTime(2026, 5, 1),
        repeating: false,
        repeatPattern: null,
      );

      expect(
        BillingSchedule.datesFor(
            oneOff, DateTime(2026, 5, 1), DateTime(2026, 5, 31)),
        isEmpty,
      );
    });

    test('an open end date changes nothing', () {
      final gym = sub(title: 'Gym', date: DateTime(2026, 1, 10));

      final dates = BillingSchedule.datesFor(
        gym,
        DateTime(2026, 1, 1),
        DateTime(2026, 3, 31),
      );

      expect(dates.length, 3);
    });
  });

  group('BillingSchedule.total', () {
    test('sums the amounts of the given occurrences', () {
      final occurrences = BillingSchedule.byDay(
        [
          sub(title: 'Netflix', date: DateTime(2026, 9, 11), amount: 17.99),
          sub(title: 'Spotify', date: DateTime(2026, 9, 11), amount: 10.99),
        ],
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 30),
      );

      expect(BillingSchedule.total(occurrences), closeTo(28.98, 0.001));
    });

    test('counts a subscription once per billing in the range', () {
      final occurrences = BillingSchedule.byDay(
        [sub(title: 'Netflix', date: DateTime(2026, 9, 11), amount: 10.0)],
        DateTime(2026, 9, 1),
        DateTime(2026, 11, 30),
      );

      expect(BillingSchedule.total(occurrences), closeTo(30.0, 0.001));
    });

    test('ignores paused subscriptions', () {
      final occurrences = BillingSchedule.byDay(
        [
          sub(title: 'Netflix', date: DateTime(2026, 9, 11), amount: 17.99),
          sub(
            title: 'Gym',
            date: DateTime(2026, 9, 8),
            amount: 30.0,
            isPaused: true,
          ),
        ],
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 30),
      );

      expect(BillingSchedule.total(occurrences), closeTo(17.99, 0.001));
    });

    test('is zero without occurrences', () {
      expect(BillingSchedule.total(const {}), 0);
    });
  });

}
