import 'package:easy_wallet/subscription_views/subscription_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'subscription.dart';

class SubscriptionItem extends StatelessWidget {
  final Subscription subscription;
  final bool isAnnual;

  const SubscriptionItem({super.key, required this.subscription, required this.isAnnual});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: subscription.url != null
          ? CachedNetworkImage(
              imageUrl:
                  'https://www.google.com/s2/favicons?sz=64&domain_url=${Uri.parse(subscription.url!).host}',
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              width: 20,
              height: 20,
            )
          : null,
      title: Text(subscription.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _convertedPrice(subscription),
            style: TextStyle(
              fontSize: 12,
              color: subscription.isPaused ? Colors.grey : Colors.black,
            ),
          ),
          Row(
            children: [
              Text(
                _remainingDays(subscription) ?? 'Unknown',
                style: TextStyle(
                  fontSize: 12,
                  color: subscription.isPaused ? Colors.grey : Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Days',
                style: TextStyle(
                  fontSize: 12,
                  color: subscription.isPaused ? Colors.grey : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: subscription.isPinned
          ? const Icon(
              Icons.push_pin,
              color: Colors.yellow,
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SubscriptionDetailView(subscription: subscription),
          ),
        );
      },
      tileColor: subscription.isPaused ? Colors.grey.withOpacity(0.5) : null,
    );
  }

  String? _remainingDays(Subscription subscription) {
    if (subscription.date == null) return null;

    DateTime nextBillDate = subscription.date!;
    DateTime today = DateTime.now();
    Duration interval;

    if (subscription.repeatPattern == 'yearly') {
      interval = const Duration(days: 365);
    } else {
      interval = const Duration(days: 30); // assuming monthly if not yearly
    }

    while (nextBillDate.isBefore(today)) {
      nextBillDate = nextBillDate.add(interval);
    }

    final difference = nextBillDate.difference(today).inDays;
    return difference.toString();
  }

  String _convertedPrice(Subscription subscription) {
    if (subscription.amount == 0) {
      return 'For free';
    }

    double amount = subscription.amount;
    if (isAnnual) {
      if (subscription.repeatPattern == 'monthly') {
        amount *= 12;
      }
    } else {
      if (subscription.repeatPattern == 'yearly') {
        amount /= 12;
      }
    }

    return '${amount.toStringAsFixed(2)} €';
  }
}
