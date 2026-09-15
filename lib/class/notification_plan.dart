import 'package:easy_wallet/class/billing_schedule.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:easy_wallet/model/subscription.dart';

/// What a reminder is about.
enum NotificationKind {
  /// A charge is coming up.
  billing,

  /// A free trial is about to turn into a paid subscription.
  trialEnd,

  /// The last chance to cancel before the subscription renews.
  cancellationDeadline,
}

/// One reminder that should be handed to the operating system.
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.subscriptionId,
    required this.at,
    required this.title,
    required this.amount,
    this.kind = NotificationKind.billing,
  });

  /// Stable within a planning run, so the platform can replace it later.
  final int id;
  final int subscriptionId;
  final DateTime at;
  final String title;
  final double amount;

  final NotificationKind kind;

  /// A warning that a free trial is about to turn into a paid subscription,
  /// rather than a reminder of an upcoming charge.
  bool get isTrialEnd => kind == NotificationKind.trialEnd;

  /// A warning that the window for cancelling is about to close.
  bool get isCancellationDeadline =>
      kind == NotificationKind.cancellationDeadline;
}

/// Works out which reminders are due when, so they can be handed to the system
/// in advance instead of being fired whenever the app happens to wake up.
///
/// Pure arithmetic: no database, no plugin, no clock of its own.
class NotificationPlan {
  const NotificationPlan._();

  /// How many notifications a platform accepts. iOS keeps at most 64 pending
  /// local notifications and silently drops the rest.
  static const int platformLimit = 60;

  /// The reminders for [subscriptions], earliest first.
  ///
  /// [occurrencesPerSubscription] controls how far ahead each subscription is
  /// planned; the result is capped at [maxCount] because the platform limit is
  /// shared by all subscriptions.
  static List<PlannedNotification> build({
    required List<Subscription> subscriptions,
    required DateTime now,
    required int hour,
    required int minute,
    int occurrencesPerSubscription = 6,
    int maxCount = platformLimit,
  }) {
    final planned = <PlannedNotification>[];

    for (final subscription in subscriptions) {
      final id = subscription.id;
      if (id == null || subscription.date == null || subscription.isPaused) {
        continue;
      }

      final offset = _offsetOf(subscription.rememberCycle);
      if (offset == null) {
        continue;
      }

      // A running trial gets its own warning: the point of a trial is to
      // cancel before it starts costing money.
      final trialEnd = subscription.trialEndDate;
      if (trialEnd != null && subscription.isInTrialOn(now)) {
        final warnOn = _daysBefore(trialEnd, offset);
        final at = DateTime(
            warnOn.year, warnOn.month, warnOn.day, hour, minute);
        if (at.isAfter(now)) {
          planned.add(PlannedNotification(
            id: _idFor(id, _trialOccurrence),
            subscriptionId: id,
            at: at,
            title: subscription.title,
            amount: subscription.amount,
            kind: NotificationKind.trialEnd,
          ));
        }
      }

      // The window for cancelling closes before the renewal, and missing it
      // costs another full period. Warned about on its own, because by the
      // time the charge reminder arrives it is already too late.
      final deadline = subscription.cancellationDeadline(asOf: now);
      if (deadline != null) {
        final warnOn = _daysBefore(deadline, offset);
        final at =
            DateTime(warnOn.year, warnOn.month, warnOn.day, hour, minute);
        if (at.isAfter(now)) {
          planned.add(PlannedNotification(
            id: _idFor(id, _cancellationOccurrence),
            subscriptionId: id,
            at: at,
            title: subscription.title,
            amount: subscription.amount,
            kind: NotificationKind.cancellationDeadline,
          ));
        }
      }

      // Look far enough ahead to fill the requested number of occurrences even
      // for a yearly subscription.
      final horizon = DateTime(
        now.year + occurrencesPerSubscription + 1,
        now.month,
        now.day,
      );
      final dates = BillingSchedule.datesFor(subscription, now, horizon);

      var taken = 0;
      for (var i = 0; i < dates.length && taken < occurrencesPerSubscription; i++) {
        final billedOn = _daysBefore(dates[i], offset);
        final at = DateTime(
          billedOn.year,
          billedOn.month,
          billedOn.day,
          hour,
          minute,
        );
        if (!at.isAfter(now)) {
          continue;
        }

        planned.add(PlannedNotification(
          id: _idFor(id, taken),
          subscriptionId: id,
          at: at,
          title: subscription.title,
          amount: subscription.amount,
        ));
        taken++;
      }
    }

    planned.sort((a, b) => a.at.compareTo(b.at));
    return planned.length > maxCount ? planned.sublist(0, maxCount) : planned;
  }

  /// [date] moved back by [offset] in calendar days.
  ///
  /// Subtracting a Duration works in absolute time, so a reminder set a week
  /// before a date across a daylight saving change lands at 23:00 the day
  /// before — and the reminder goes out a day early.
  static DateTime _daysBefore(DateTime date, Duration offset) =>
      DateTime(date.year, date.month, date.day - offset.inDays);

  /// Reserved slots so the special warnings cannot collide with a billing id.
  static const int _trialOccurrence = 99;
  static const int _cancellationOccurrence = 98;

  /// Ids stay inside the 32 bit range the notification plugins expect.
  static int _idFor(int subscriptionId, int occurrence) =>
      (subscriptionId % 1000000) * 100 + occurrence;

  /// Null for a subscription that asks for no reminder at all.
  static Duration? _offsetOf(String? rememberCycle) {
    if (rememberCycle == null) {
      return null;
    }
    for (final cycle in RememberCycle.values) {
      if (cycle.value != rememberCycle) {
        continue;
      }
      switch (cycle) {
        case RememberCycle.sameDay:
          return Duration.zero;
        case RememberCycle.dayBefore:
          return const Duration(days: 1);
        case RememberCycle.twoDaysBefore:
          return const Duration(days: 2);
        case RememberCycle.weekBefore:
          return const Duration(days: 7);
      }
    }
    return null;
  }
}
