import 'package:easy_wallet/class/billing_schedule.dart';
import 'package:easy_wallet/model/subscription.dart';

/// One upcoming billing, as a widget row shows it.
class UpcomingPayment {
  const UpcomingPayment({
    required this.subscription,
    required this.date,
    required this.daysUntil,
  });

  final Subscription subscription;
  final DateTime date;

  /// Whole days from today until the billing; zero when it is today.
  final int daysUntil;

  String get title => subscription.title;

  /// The share this user carries, not necessarily the full price.
  double get amount => subscription.shareOfAmount;
}

/// The next billings across all subscriptions, in the order they happen.
class UpcomingPayments {
  const UpcomingPayments._();

  /// Far enough ahead to fill a list even when only yearly subscriptions
  /// exist.
  static const int yearsAhead = 12;

  static List<UpcomingPayment> next(
    List<Subscription> subscriptions, {
    required DateTime now,
    int count = 10,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final horizon = DateTime(now.year + yearsAhead, now.month, now.day);

    final active = subscriptions.where((s) => !s.isPaused).toList();
    final byDay = BillingSchedule.byDay(active, today, horizon);

    final days = byDay.keys.toList()..sort();
    final payments = <UpcomingPayment>[];

    for (final day in days) {
      for (final occurrence in byDay[day]!) {
        payments.add(UpcomingPayment(
          subscription: occurrence.subscription,
          date: day,
          daysUntil: day.difference(today).inDays,
        ));
        if (payments.length == count) {
          return payments;
        }
      }
    }

    return payments;
  }
}
