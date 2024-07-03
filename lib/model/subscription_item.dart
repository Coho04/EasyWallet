import 'package:easy_wallet/subscription_views/subscription_detail_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/material.dart';

class SubscriptionItem extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionItem({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator,
            ),
          ),
        ),
        child: Row(
          children: [
            if (subscription.url != null)
              CachedNetworkImage(
                imageUrl:
                    'https://www.google.com/s2/favicons?sz=64&domain_url=${Uri.parse(subscription.url!).host}',
                placeholder: (context, url) =>
                    const CupertinoActivityIndicator(),
                errorWidget: (context, url, error) =>
                    const Icon(CupertinoIcons.exclamationmark_triangle),
                width: 40,
                height: 40,
              ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${subscription.amount.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            Row(
              children: [
                Column(
                  children: [
                    Text(
                      '${_remainingDays(subscription)} Tage',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '(${_convertPrice(subscription)})',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
                CupertinoButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) =>
                            SubscriptionDetailView(subscription: subscription),
                      ),
                    );
                  },
                  child: const Icon(
                    CupertinoIcons.right_chevron,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                if (subscription.isPinned)
                  const Icon(
                    CupertinoIcons.pin_fill,
                    color: CupertinoColors.systemGrey,
                  ),
              ],
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) =>
                SubscriptionDetailView(subscription: subscription),
          ),
        );
      },
    );
  }

  String? _remainingDays(Subscription subscription) {
    if (subscription.date == null) return 'Unknown';

    DateTime nextBillDate = subscription.date!;
    DateTime today = DateTime.now();
    Duration interval;

    if (subscription.repeatPattern == 'yearly') {
      interval = const Duration(days: 365);
    } else {
      interval = const Duration(days: 30);
    }

    while (nextBillDate.isBefore(today)) {
      nextBillDate = nextBillDate.add(interval);
    }

    final difference = nextBillDate.difference(today).inDays;
    return difference.toString();
  }

  String? _convertPrice(Subscription subscription) {
    if (subscription.repeatPattern == 'yearly') {
      return '${(subscription.amount / 12).toStringAsFixed(2)} €/Monat';
    } else if (subscription.repeatPattern == 'monthly') {
      return '${(subscription.amount * 12).toStringAsFixed(2)} €/Jahr';
    }
    return null;
  }
}
