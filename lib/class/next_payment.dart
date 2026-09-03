import 'package:easy_wallet/class/billing_schedule.dart';
import 'package:easy_wallet/model/subscription.dart';

/// The next payment that is actually due, as shown on a home screen widget.
class NextPayment {
  const NextPayment({
    required this.subscriptionId,
    required this.title,
    required this.amount,
    required this.date,
  });

  final int? subscriptionId;
  final String title;

  /// The share this user carries, not necessarily the full price.
  final double amount;
  final DateTime date;

  /// How far ahead to look. A yearly subscription can be eleven months out
  /// and still be the next thing that is billed.
  static const Duration horizon = Duration(days: 400);

  /// The earliest upcoming billing across [subscriptions], or null when
  /// nothing is due. Paused, expired and still free subscriptions are left out
  /// by the schedule itself.
  static NextPayment? of(List<Subscription> subscriptions,
      {required DateTime now}) {
    final active = subscriptions.where((s) => !s.isPaused).toList();
    final byDay = BillingSchedule.byDay(active, now, now.add(horizon));
    if (byDay.isEmpty) {
      return null;
    }

    final days = byDay.keys.toList()..sort();
    final first = days.first;
    final occurrence = byDay[first]!.first;

    return NextPayment(
      subscriptionId: occurrence.subscription.id,
      title: occurrence.subscription.title,
      amount: occurrence.subscription.shareOfAmount,
      date: first,
    );
  }
}
