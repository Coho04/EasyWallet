import 'package:easy_wallet/class/notification_plan.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription sub({
  int? id = 1,
  PaymentRate rate = PaymentRate.yearly,
  DateTime? date,
  DateTime? endDate,
  int? noticePeriodDays,
  bool repeating = true,
  bool isPaused = false,
  String? rememberCycle = 'same_day',
}) =>
    Subscription(
      id: id,
      amount: 120,
      date: date ?? DateTime(2024, 6, 1),
      endDate: endDate,
      noticePeriodDays: noticePeriodDays,
      isPaused: isPaused,
      isPinned: false,
      repeating: repeating,
      repeatPattern: rate.value,
      rememberCycle: rememberCycle,
      title: 'Gym',
    );

void main() {
  group('cancellationDeadline', () {
    test('counts back from the renewal, not from today', () {
      // Three months notice on a contract renewing on 1 June means the first
      // of March, whatever today happens to be.
      final deadline = sub(noticePeriodDays: 92)
          .cancellationDeadline(asOf: DateTime(2026, 1, 10));

      expect(deadline, DateTime(2026, 3, 1));
    });

    test('skips a deadline that has already passed', () {
      // Asked on 15 March, the window for the June renewal closed two weeks
      // ago. Reporting it would be useless; the next one the user can still
      // act on is a year later.
      final deadline = sub(noticePeriodDays: 92)
          .cancellationDeadline(asOf: DateTime(2026, 3, 15));

      expect(deadline, DateTime(2027, 3, 1));
    });

    test('works for an interval of a few months', () {
      final deadline = sub(
        rate: PaymentRate.quarterly,
        date: DateTime(2026, 1, 15),
        noticePeriodDays: 14,
      ).cancellationDeadline(asOf: DateTime(2026, 2, 1));

      expect(deadline, DateTime(2026, 4, 1));
    });

    test('is silent without a notice period', () {
      expect(sub().cancellationDeadline(asOf: DateTime(2026, 1, 1)), isNull);
      expect(
        sub(noticePeriodDays: 0).cancellationDeadline(asOf: DateTime(2026, 1, 1)),
        isNull,
      );
    });

    test('is silent once the subscription already ends on its own', () {
      // Nothing left to cancel: an end date means it stops by itself.
      expect(
        sub(noticePeriodDays: 30, endDate: DateTime(2027, 6, 1))
            .cancellationDeadline(asOf: DateTime(2026, 1, 1)),
        isNull,
      );
    });

    test('is silent for a one-off payment', () {
      expect(
        sub(noticePeriodDays: 30, repeating: false)
            .cancellationDeadline(asOf: DateTime(2026, 1, 1)),
        isNull,
      );
    });

    test('survives a notice period longer than the billing period', () {
      // Six weeks notice on a monthly subscription: the window for the next
      // renewal is always already shut, so the answer is a later one.
      final deadline = sub(
        rate: PaymentRate.monthly,
        date: DateTime(2026, 1, 10),
        noticePeriodDays: 42,
      ).cancellationDeadline(asOf: DateTime(2026, 2, 1));

      expect(deadline, isNotNull);
      expect(deadline!.isAfter(DateTime(2026, 2, 1)), isTrue);
    });

    test('round trips through the database representation', () {
      final restored = Subscription.fromJson(
          sub(noticePeriodDays: 92).toJson()..['repeatPattern'] = 'yearly');

      expect(restored.noticePeriodDays, 92);
    });
  });

  group('the reminder', () {
    test('warns before the window for cancelling closes', () {
      final plan = NotificationPlan.build(
        subscriptions: [
          sub(noticePeriodDays: 92, rememberCycle: RememberCycle.weekBefore.value)
        ],
        now: DateTime(2026, 1, 10),
        hour: 9,
        minute: 0,
      );

      final warning = plan.where((n) => n.isCancellationDeadline).toList();
      expect(warning, hasLength(1));
      // A week before the first of March.
      expect(warning.single.at, DateTime(2026, 2, 22, 9, 0));
      expect(warning.single.isTrialEnd, isFalse);
    });

    test('does not warn about a subscription with no notice period', () {
      final plan = NotificationPlan.build(
        subscriptions: [sub()],
        now: DateTime(2026, 1, 10),
        hour: 9,
        minute: 0,
      );

      expect(plan.every((n) => !n.isCancellationDeadline), isTrue);
    });

    test('keeps the charge reminders alongside it', () {
      final plan = NotificationPlan.build(
        subscriptions: [sub(noticePeriodDays: 92)],
        now: DateTime(2026, 1, 10),
        hour: 9,
        minute: 0,
      );

      expect(plan.any((n) => n.isCancellationDeadline), isTrue);
      expect(plan.any((n) => n.kind == NotificationKind.billing), isTrue);
    });

    test('gives the warning an id of its own', () {
      // Colliding with a billing id would make one reminder replace the other.
      final plan = NotificationPlan.build(
        subscriptions: [sub(noticePeriodDays: 92)],
        now: DateTime(2026, 1, 10),
        hour: 9,
        minute: 0,
      );

      final ids = plan.map((n) => n.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('says nothing for a paused subscription', () {
      final plan = NotificationPlan.build(
        subscriptions: [sub(noticePeriodDays: 92, isPaused: true)],
        now: DateTime(2026, 1, 10),
        hour: 9,
        minute: 0,
      );

      expect(plan, isEmpty);
    });
  });
}
