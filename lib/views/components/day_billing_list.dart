import 'package:easy_wallet/class/money.dart';
import 'package:easy_wallet/class/billing_schedule.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/cupertino.dart';

/// The billings of a single day, one row per subscription. Paused
/// subscriptions stay visible but are greyed out and marked.
class DayBillingList extends StatelessWidget {
  const DayBillingList({
    super.key,
    required this.occurrences,
    required this.currencySymbol,
    required this.emptyLabel,
    required this.onSubscriptionSelected,
  });

  final List<BillingOccurrence> occurrences;
  final String currencySymbol;
  final String emptyLabel;
  final ValueChanged<Subscription> onSubscriptionSelected;

  @override
  Widget build(BuildContext context) {
    if (occurrences.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            emptyLabel,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < occurrences.length; i++)
          _row(context, i, occurrences[i].subscription),
      ],
    );
  }

  Widget _row(BuildContext context, int index, Subscription subscription) {
    final isPaused = subscription.isPaused;
    final labelColor = isPaused
        ? CupertinoColors.secondaryLabel.resolveFrom(context)
        : CupertinoColors.label.resolveFrom(context);

    return GestureDetector(
      key: ValueKey('occurrence-$index'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onSubscriptionSelected(subscription),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            subscription.buildImage(width: 28, height: 28, borderRadius: 7),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                subscription.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, color: labelColor),
              ),
            ),
            if (isPaused)
              Padding(
                key: ValueKey('paused-$index'),
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  CupertinoIcons.pause_circle,
                  size: 16,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            Text(
              Money.format(subscription.amount, currencySymbol),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
