import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription sub({DateTime? date, DateTime? endDate, double amount = 10.0}) {
  return Subscription(
    amount: amount,
    date: date,
    endDate: endDate,
    isPaused: false,
    isPinned: false,
    repeating: true,
    repeatPattern: 'monthly',
    title: 'Gym',
  );
}

void main() {
  group('Subscription.isExpiredOn', () {
    test('an open ended subscription never expires', () {
      expect(sub(date: DateTime(2026, 1, 1)).isExpiredOn(DateTime(2030, 1, 1)),
          isFalse);
    });

    test('is not expired on the end date itself', () {
      final gym = sub(date: DateTime(2026, 1, 1), endDate: DateTime(2026, 3, 10));

      expect(gym.isExpiredOn(DateTime(2026, 3, 10)), isFalse);
    });

    test('is expired the day after the end date', () {
      final gym = sub(date: DateTime(2026, 1, 1), endDate: DateTime(2026, 3, 10));

      expect(gym.isExpiredOn(DateTime(2026, 3, 11)), isTrue);
    });

    test('ignores the time of day', () {
      final gym = sub(date: DateTime(2026, 1, 1), endDate: DateTime(2026, 3, 10));

      expect(gym.isExpiredOn(DateTime(2026, 3, 10, 23, 59)), isFalse);
    });
  });

  group('Subscription.countPayment', () {
    test('counts up to the reference day without an end date', () {
      final gym = sub(date: DateTime(2026, 1, 10));

      expect(gym.countPayment(asOf: DateTime(2026, 6, 1)), 5);
    });

    test('stops counting at the end date', () {
      final gym = sub(
        date: DateTime(2026, 1, 10),
        endDate: DateTime(2026, 3, 31),
      );

      expect(gym.countPayment(asOf: DateTime(2026, 6, 1)), 3);
    });

    test('an end date in the future does not cut anything off', () {
      final gym = sub(
        date: DateTime(2026, 1, 10),
        endDate: DateTime(2030, 1, 1),
      );

      expect(gym.countPayment(asOf: DateTime(2026, 6, 1)), 5);
    });
  });

  group('Subscription.sumPayment', () {
    test('stops summing at the end date', () {
      final withEnd = sub(
        date: DateTime(2026, 1, 10),
        endDate: DateTime(2026, 3, 31),
        amount: 10,
      );
      final withoutEnd = sub(date: DateTime(2026, 1, 10), amount: 10);

      final bounded = withEnd.sumPayment(asOf: DateTime(2026, 6, 1));
      final open = withoutEnd.sumPayment(asOf: DateTime(2026, 6, 1));

      expect(bounded, lessThan(open));
      expect(bounded, 30.0);
    });
  });
}
