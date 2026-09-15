import 'package:easy_wallet/model/subscription.dart';

/// How the price of a subscription has moved since the app started watching it.
///
/// The price history has been recorded since the day the feature was added,
/// but only ever shown as a list of dates and amounts. The number people
/// actually want out of it is the one this class works out: how much more the
/// same subscription costs now than it used to.
class PriceTrend {
  const PriceTrend({
    required this.first,
    required this.current,
    required this.since,
  });

  /// The oldest recorded price.
  final double first;

  /// The price being paid today.
  final double current;

  /// When the oldest price was recorded. Not when the subscription started —
  /// nothing is known about prices from before it was tracked.
  final DateTime since;

  /// What one billing costs more than it used to. Negative when it got cheaper.
  double get change => current - first;

  /// The change as a percentage of the original price.
  ///
  /// Zero for a subscription that started free: everything is an infinite
  /// increase over nothing, which is true and useless.
  double get percent => first == 0 ? 0 : change / first * 100;

  /// Whether the price moved at all, ignoring rounding noise below a cent.
  bool get hasChanged => change.abs() >= 0.005;

  bool get hasRisen => change > 0;

  /// The trend of [history], oldest entry first, or null when there is nothing
  /// to compare — a single recorded price is not a development.
  static PriceTrend? of(List<PriceChange> history) {
    if (history.length < 2) {
      return null;
    }

    final oldest = history.first;
    final newest = history.last;
    final trend = PriceTrend(
      first: oldest.amount,
      current: newest.amount,
      since: oldest.changedAt,
    );

    return trend.hasChanged ? trend : null;
  }

  /// What the recorded increases add up to over a year, across [subscriptions].
  ///
  /// Each subscription is annualised first, so a yearly contract that went up
  /// by 12 does not outweigh a monthly one that went up by 2. Paused and
  /// expired subscriptions are left out, like everywhere else the app totals
  /// things up.
  ///
  /// Amounts are added in the currency they are billed in, the same way the
  /// rest of the app totals mixed currencies.
  static double yearlyIncrease(
    List<Subscription> subscriptions,
    Map<int, List<PriceChange>> historyBySubscription,
  ) {
    var increase = 0.0;

    for (final subscription in subscriptions) {
      final id = subscription.id;
      if (id == null || subscription.isPaused || subscription.isExpired) {
        continue;
      }

      final trend = PriceTrend.of(historyBySubscription[id] ?? const []);
      if (trend == null) {
        continue;
      }

      final share = subscription.splitCount == null || subscription.splitCount! <= 1
          ? trend.change
          : trend.change / subscription.splitCount!;
      increase += subscription.rate.perYear(share);
    }

    return increase;
  }
}
