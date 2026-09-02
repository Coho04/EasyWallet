import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/model/subscription.dart';

/// A single billing of a subscription on a concrete day.
class BillingOccurrence {
  const BillingOccurrence({
    required this.subscription,
    required this.date,
  });

  final Subscription subscription;
  final DateTime date;
}

/// Expands the recurrence of subscriptions into the concrete days they are
/// billed on. Pure arithmetic: no database access and no dependency on the
/// current date, so it stays predictable and testable.
class BillingSchedule {
  const BillingSchedule._();

  /// All billing dates of [subscription] between [from] and [to], inclusive.
  static List<DateTime> datesFor(
    Subscription subscription,
    DateTime from,
    DateTime to,
  ) {
    final start = subscription.date;
    if (start == null) {
      return [];
    }

    final anchor = _dateOnly(start);
    final rangeStart = _dateOnly(from);
    final rangeEnd = _dateOnly(to);

    if (!subscription.repeating) {
      final withinRange =
          !anchor.isBefore(rangeStart) && !anchor.isAfter(rangeEnd);
      return withinRange ? [anchor] : [];
    }

    final pattern = PaymentRate.findByName(subscription.repeatPattern ?? '');
    final dates = <DateTime>[];

    for (var step = 0;; step++) {
      final occurrence = _shift(anchor, pattern, step);
      if (occurrence.isAfter(rangeEnd)) {
        break;
      }
      if (!occurrence.isBefore(rangeStart)) {
        dates.add(occurrence);
      }
    }

    return dates;
  }

  /// The occurrences of all [subscriptions] between [from] and [to], grouped by
  /// day. Days without a billing are absent. Paused subscriptions are included
  /// so the view can decide how to present them.
  static Map<DateTime, List<BillingOccurrence>> byDay(
    List<Subscription> subscriptions,
    DateTime from,
    DateTime to,
  ) {
    final byDay = <DateTime, List<BillingOccurrence>>{};

    for (final subscription in subscriptions) {
      for (final date in datesFor(subscription, from, to)) {
        byDay.putIfAbsent(date, () => []).add(
              BillingOccurrence(subscription: subscription, date: date),
            );
      }
    }

    return byDay;
  }

  /// What the given occurrences add up to. Paused subscriptions are left out:
  /// they are shown in the calendar, but nothing is billed for them.
  static double total(Map<DateTime, List<BillingOccurrence>> byDay) {
    var total = 0.0;

    for (final occurrences in byDay.values) {
      for (final occurrence in occurrences) {
        if (!occurrence.subscription.isPaused) {
          total += occurrence.subscription.amount;
        }
      }
    }

    return total;
  }

  /// The [step]th occurrence after [anchor]. The day of month of [anchor] stays
  /// the anchor: a subscription starting on the 31st falls on the 28th in
  /// February but returns to the 31st in March instead of drifting.
  static DateTime _shift(DateTime anchor, PaymentRate pattern, int step) {
    final int year;
    final int month;

    if (pattern == PaymentRate.yearly) {
      year = anchor.year + step;
      month = anchor.month;
    } else {
      final months = anchor.month - 1 + step;
      year = anchor.year + months ~/ 12;
      month = months % 12 + 1;
    }

    final day = anchor.day <= _daysInMonth(year, month)
        ? anchor.day
        : _daysInMonth(year, month);

    return DateTime(year, month, day);
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
