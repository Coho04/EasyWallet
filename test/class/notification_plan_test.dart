import 'package:easy_wallet/class/notification_plan.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription sub({
  int id = 1,
  String title = 'Netflix',
  DateTime? date,
  DateTime? endDate,
  DateTime? trialEndDate,
  bool isPaused = false,
  String cycle = 'same_day',
  String repeatPattern = 'monthly',
  double amount = 9.99,
}) {
  return Subscription(
    id: id,
    amount: amount,
    date: date ?? DateTime(2026, 1, 10),
    endDate: endDate,
    trialEndDate: trialEndDate,
    isPaused: isPaused,
    isPinned: false,
    repeating: true,
    repeatPattern: repeatPattern,
    rememberCycle: cycle,
    title: title,
  );
}

void main() {
  final now = DateTime(2026, 1, 1, 8, 0);

  group('NotificationPlan.build', () {
    test('reminds on the billing day at the configured time', () {
      final plan = NotificationPlan.build(
        subscriptions: [sub(date: DateTime(2026, 1, 10))],
        now: now,
        hour: 9,
        minute: 30,
        occurrencesPerSubscription: 1,
      );

      expect(plan.single.at, DateTime(2026, 1, 10, 9, 30));
      expect(plan.single.title, 'Netflix');
    });

    test('moves the reminder ahead by the chosen cycle', () {
      DateTime firstFor(String cycle) => NotificationPlan.build(
            subscriptions: [sub(date: DateTime(2026, 1, 10), cycle: cycle)],
            now: now,
            hour: 9,
            minute: 0,
            occurrencesPerSubscription: 1,
          ).single.at;

      expect(firstFor(RememberCycle.sameDay.value), DateTime(2026, 1, 10, 9));
      expect(firstFor(RememberCycle.dayBefore.value), DateTime(2026, 1, 9, 9));
      expect(
          firstFor(RememberCycle.twoDaysBefore.value), DateTime(2026, 1, 8, 9));
      expect(firstFor(RememberCycle.weekBefore.value), DateTime(2026, 1, 3, 9));
    });

    test('leaves out paused subscriptions', () {
      final plan = NotificationPlan.build(
        subscriptions: [sub(isPaused: true)],
        now: now,
        hour: 9,
        minute: 0,
      );

      expect(plan, isEmpty);
    });

    test('leaves out subscriptions that have run out', () {
      final plan = NotificationPlan.build(
        subscriptions: [
          sub(date: DateTime(2026, 1, 10), endDate: DateTime(2025, 12, 31)),
        ],
        now: now,
        hour: 9,
        minute: 0,
      );

      expect(plan, isEmpty);
    });

    test('leaves out subscriptions without a date', () {
      final undated = Subscription(
        amount: 1,
        date: null,
        isPaused: false,
        isPinned: false,
        repeating: true,
        repeatPattern: 'monthly',
        rememberCycle: 'same_day',
        title: 'Undated',
      );

      expect(
        NotificationPlan.build(
            subscriptions: [undated], now: now, hour: 9, minute: 0),
        isEmpty,
      );
    });

    test('never plans a reminder in the past', () {
      // The billing day is today but the configured time has already passed.
      final plan = NotificationPlan.build(
        subscriptions: [sub(date: DateTime(2026, 1, 1))],
        now: DateTime(2026, 1, 1, 10, 0),
        hour: 9,
        minute: 0,
        occurrencesPerSubscription: 1,
      );

      expect(plan.every((n) => n.at.isAfter(DateTime(2026, 1, 1, 10, 0))),
          isTrue);
    });

    test('plans several occurrences ahead', () {
      final plan = NotificationPlan.build(
        subscriptions: [sub(date: DateTime(2026, 1, 10))],
        now: now,
        hour: 9,
        minute: 0,
        occurrencesPerSubscription: 3,
      );

      expect(plan.map((n) => n.at), [
        DateTime(2026, 1, 10, 9),
        DateTime(2026, 2, 10, 9),
        DateTime(2026, 3, 10, 9),
      ]);
    });

    test('gives every entry its own id', () {
      final plan = NotificationPlan.build(
        subscriptions: [sub(id: 1), sub(id: 2, title: 'Disney+')],
        now: now,
        hour: 9,
        minute: 0,
        occurrencesPerSubscription: 3,
      );

      expect(plan.map((n) => n.id).toSet().length, plan.length);
    });

    test('warns before a free trial turns into a paid subscription', () {
      final plan = NotificationPlan.build(
        subscriptions: [
          sub(date: DateTime(2026, 1, 10), trialEndDate: DateTime(2026, 3, 1),
              cycle: 'day_before'),
        ],
        now: now,
        hour: 9,
        minute: 0,
        occurrencesPerSubscription: 1,
      );

      final trial = plan.where((n) => n.isTrialEnd).toList();
      expect(trial.single.at, DateTime(2026, 2, 28, 9));
    });

    test('the trial warning comes before the first charge', () {
      final plan = NotificationPlan.build(
        subscriptions: [
          sub(date: DateTime(2026, 1, 10), trialEndDate: DateTime(2026, 3, 1)),
        ],
        now: now,
        hour: 9,
        minute: 0,
        occurrencesPerSubscription: 1,
      );

      expect(plan.first.isTrialEnd, isTrue);
      expect(plan.length, 2);
    });

    test('no trial warning without a trial', () {
      final plan = NotificationPlan.build(
        subscriptions: [sub(date: DateTime(2026, 1, 10))],
        now: now,
        hour: 9,
        minute: 0,
        occurrencesPerSubscription: 1,
      );

      expect(plan.every((n) => !n.isTrialEnd), isTrue);
    });

    test('no trial warning once the trial is over', () {
      final plan = NotificationPlan.build(
        subscriptions: [
          sub(date: DateTime(2026, 1, 10), trialEndDate: DateTime(2025, 12, 1)),
        ],
        now: now,
        hour: 9,
        minute: 0,
        occurrencesPerSubscription: 1,
      );

      expect(plan.every((n) => !n.isTrialEnd), isTrue);
    });

    test('keeps the earliest reminders when the platform limit is reached', () {
      final plan = NotificationPlan.build(
        subscriptions: [
          sub(id: 1, date: DateTime(2026, 1, 10)),
          sub(id: 2, title: 'Disney+', date: DateTime(2026, 1, 5)),
        ],
        now: now,
        hour: 9,
        minute: 0,
        occurrencesPerSubscription: 3,
        maxCount: 2,
      );

      expect(plan.length, 2);
      expect(plan.first.at, DateTime(2026, 1, 5, 9));
      expect(plan.last.at, DateTime(2026, 1, 10, 9));
    });
  });
}
