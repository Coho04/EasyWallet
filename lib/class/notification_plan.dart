import 'package:easy_wallet/class/billing_schedule.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:easy_wallet/model/subscription.dart';

/// One reminder that should be handed to the operating system.
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.subscriptionId,
    required this.at,
    required this.title,
    required this.amount,
  });

  /// Stable within a planning run, so the platform can replace it later.
  final int id;
  final int subscriptionId;
  final DateTime at;
  final String title;
  final double amount;
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
        final billedOn = dates[i].subtract(offset);
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
