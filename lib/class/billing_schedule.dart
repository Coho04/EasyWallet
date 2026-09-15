import 'package:easy_wallet/class/exchange_rates.dart';
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
    var rangeStart = _dateOnly(from);

    // Nothing is billed while a free trial runs, including on its last day.
    final trialEnd = subscription.trialEndDate;
    if (trialEnd != null) {
      final firstBillable = _dateOnly(trialEnd).add(const Duration(days: 1));
      if (firstBillable.isAfter(rangeStart)) {
        rangeStart = firstBillable;
      }
    }

    // The end date is inclusive: the subscription is still billed on that day,
    // never after it.
    final end = subscription.endDate;
    var rangeEnd = _dateOnly(to);
    if (end != null && _dateOnly(end).isBefore(rangeEnd)) {
      rangeEnd = _dateOnly(end);
    }
    if (rangeEnd.isBefore(rangeStart)) {
      return [];
    }

    if (!subscription.repeating) {
      final withinRange =
          !anchor.isBefore(rangeStart) && !anchor.isAfter(rangeEnd);
      return withinRange ? [anchor] : [];
    }

    final pattern = PaymentRate.findByName(subscription.repeatPattern ?? '');
    final dates = <DateTime>[];

    for (var step = 0;; step++) {
      final occurrence = pattern.shift(anchor, step);
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

  /// What the given occurrences cost this user. Paused subscriptions are left
  /// out - they are shown in the calendar, but nothing is billed for them -
  /// and a shared subscription only counts with the share the user carries.
  ///
  /// With [rates] and [targetCurrency] given, subscriptions billed in another
  /// currency are converted before they are added up.
  static double total(
    Map<DateTime, List<BillingOccurrence>> byDay, {
    String? targetCurrency,
    ExchangeRates? rates,
  }) {
    var total = 0.0;

    for (final occurrences in byDay.values) {
      for (final occurrence in occurrences) {
        if (!occurrence.subscription.isPaused) {
          total += occurrence.subscription.shareIn(targetCurrency, rates);
        }
      }
    }

    return total;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
