import 'package:easy_wallet/class/next_payment.dart';
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
    repeatPattern: 'monthly',
    title: title,
  );
}

void main() {
  final now = DateTime(2026, 1, 1);

  group('NextPayment.of', () {
    test('is null without subscriptions', () {
      expect(NextPayment.of(const [], now: now), isNull);
    });

    test('finds the closest upcoming billing', () {
      final next = NextPayment.of(
        [
          sub(id: 1, title: 'Netflix', date: DateTime(2026, 1, 20)),
          sub(id: 2, title: 'Disney+', date: DateTime(2026, 1, 5)),
        ],
        now: now,
      );

      expect(next!.title, 'Disney+');
      expect(next.date, DateTime(2026, 1, 5));
    });

    test('reports the share rather than the full amount', () {
      final next = NextPayment.of(
        [sub(amount: 20, splitCount: 4, date: DateTime(2026, 1, 5))],
        now: now,
      );

      expect(next!.amount, 5.0);
    });

    test('skips paused subscriptions', () {
      final next = NextPayment.of(
        [
          sub(id: 1, title: 'Paused', date: DateTime(2026, 1, 5), isPaused: true),
          sub(id: 2, title: 'Netflix', date: DateTime(2026, 1, 20)),
        ],
        now: now,
      );

      expect(next!.title, 'Netflix');
    });

    test('skips what has run out or is still free', () {
      final next = NextPayment.of(
        [
          sub(
            id: 1,
            title: 'Expired',
            date: DateTime(2026, 1, 5),
            endDate: DateTime(2025, 12, 31),
          ),
          sub(
            id: 2,
            title: 'Trial',
            date: DateTime(2026, 1, 6),
            trialEndDate: DateTime(2026, 6, 1),
          ),
          sub(id: 3, title: 'Netflix', date: DateTime(2026, 1, 20)),
        ],
        now: now,
      );

      expect(next!.title, 'Netflix');
    });

    test('looks beyond the coming weeks for a yearly subscription', () {
      final yearly = Subscription(
        id: 1,
        amount: 60,
        date: DateTime(2026, 11, 5),
        isPaused: false,
        isPinned: false,
        repeating: true,
        repeatPattern: 'yearly',
        title: 'Domain',
      );

      expect(NextPayment.of([yearly], now: now)!.date, DateTime(2026, 11, 5));
    });
  });
}
