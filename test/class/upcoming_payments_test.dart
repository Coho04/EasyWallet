import 'package:easy_wallet/class/upcoming_payments.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription sub({
  int id = 1,
  String title = 'Netflix',
  double amount = 9.99,
  DateTime? date,
  DateTime? endDate,
  DateTime? trialEndDate,
  int? splitCount,
  bool isPaused = false,
  String repeatPattern = 'monthly',
}) {
  return Subscription(
    id: id,
    amount: amount,
    date: date ?? DateTime(2026, 1, 10),
    endDate: endDate,
    trialEndDate: trialEndDate,
    splitCount: splitCount,
    isPaused: isPaused,
    isPinned: false,
    repeating: true,
    repeatPattern: repeatPattern,
    title: title,
  );
}

void main() {
  final now = DateTime(2026, 1, 1);

  group('UpcomingPayments.next', () {
    test('is empty without subscriptions', () {
      expect(UpcomingPayments.next(const [], now: now), isEmpty);
    });

    test('returns the billings in order, earliest first', () {
      final list = UpcomingPayments.next(
        [
          sub(id: 1, title: 'Netflix', date: DateTime(2026, 1, 20)),
          sub(id: 2, title: 'Disney+', date: DateTime(2026, 1, 5)),
        ],
        now: now,
        count: 4,
      );

      expect(list.map((e) => e.title).take(3),
          ['Disney+', 'Netflix', 'Disney+']);
      expect(list.first.date, DateTime(2026, 1, 5));
    });

    test('counts the days until each billing', () {
      final list = UpcomingPayments.next(
        [sub(date: DateTime(2026, 1, 11))],
        now: DateTime(2026, 1, 1),
        count: 1,
      );

      expect(list.single.daysUntil, 10);
    });

    test('a billing today is zero days away, not negative', () {
      final list = UpcomingPayments.next(
        [sub(date: DateTime(2026, 1, 1))],
        now: DateTime(2026, 1, 1, 18, 0),
        count: 1,
      );

      expect(list.single.daysUntil, 0);
    });

    test('keeps at most the requested number', () {
      final list = UpcomingPayments.next(
        [sub(date: DateTime(2026, 1, 5))],
        now: now,
        count: 3,
      );

      expect(list.length, 3);
    });

    test('reports the share of a shared subscription', () {
      final list = UpcomingPayments.next(
        [sub(amount: 20, splitCount: 4, date: DateTime(2026, 1, 5))],
        now: now,
        count: 1,
      );

      expect(list.single.amount, 5.0);
    });

    test('leaves out paused, expired and still free subscriptions', () {
      final list = UpcomingPayments.next(
        [
          sub(id: 1, title: 'Paused', date: DateTime(2026, 1, 2), isPaused: true),
          sub(
            id: 2,
            title: 'Expired',
            date: DateTime(2026, 1, 3),
            endDate: DateTime(2025, 12, 31),
          ),
          sub(
            id: 3,
            title: 'Trial',
            date: DateTime(2026, 1, 4),
            trialEndDate: DateTime(2026, 6, 1),
          ),
          sub(id: 4, title: 'Netflix', date: DateTime(2026, 1, 20)),
        ],
        now: now,
        count: 5,
      );

      expect(list.map((e) => e.title).toSet(), {'Netflix'});
    });

    test('reaches far enough ahead for yearly subscriptions', () {
      final list = UpcomingPayments.next(
        [sub(date: DateTime(2026, 11, 5), repeatPattern: 'yearly')],
        now: now,
        count: 2,
      );

      expect(list.map((e) => e.date),
          [DateTime(2026, 11, 5), DateTime(2027, 11, 5)]);
    });
  });
}
