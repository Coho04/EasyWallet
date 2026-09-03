import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription sub({
  double amount = 20.0,
  int? splitCount,
  DateTime? trialEndDate,
}) {
  return Subscription(
    amount: amount,
    date: DateTime(2026, 1, 10),
    splitCount: splitCount,
    trialEndDate: trialEndDate,
    isPaused: false,
    isPinned: false,
    repeating: true,
    repeatPattern: 'monthly',
    title: 'Netflix',
  );
}

void main() {
  group('Subscription.shareOfAmount', () {
    test('is the full amount when nobody shares', () {
      expect(sub().shareOfAmount, 20.0);
    });

    test('splits the amount across the given number of people', () {
      expect(sub(amount: 20, splitCount: 4).shareOfAmount, 5.0);
    });

    test('treats a split of one like paying alone', () {
      expect(sub(amount: 20, splitCount: 1).shareOfAmount, 20.0);
    });

    test('ignores a nonsensical split instead of dividing by zero', () {
      expect(sub(amount: 20, splitCount: 0).shareOfAmount, 20.0);
      expect(sub(amount: 20, splitCount: -3).shareOfAmount, 20.0);
    });
  });

  group('Subscription.isInTrialOn', () {
    test('is false without a trial', () {
      expect(sub().isInTrialOn(DateTime(2026, 1, 1)), isFalse);
    });

    test('is true before the trial ends', () {
      final s = sub(trialEndDate: DateTime(2026, 2, 1));

      expect(s.isInTrialOn(DateTime(2026, 1, 20)), isTrue);
    });

    test('still counts the last day of the trial', () {
      final s = sub(trialEndDate: DateTime(2026, 2, 1));

      expect(s.isInTrialOn(DateTime(2026, 2, 1)), isTrue);
      expect(s.isInTrialOn(DateTime(2026, 2, 1, 23, 59)), isTrue);
    });

    test('is over the day after', () {
      final s = sub(trialEndDate: DateTime(2026, 2, 1));

      expect(s.isInTrialOn(DateTime(2026, 2, 2)), isFalse);
    });
  });
}
