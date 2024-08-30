import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:easy_wallet/views/subscription/show.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SubscriptionListComponent extends StatelessWidget {
  final Subscription subscription;
  final Currency currency;
  final Function(Subscription) onUpdate;
  final Function(Subscription) onDelete;

  const SubscriptionListComponent(
      {super.key,
      required this.subscription,
      required this.currency,
      required this.onUpdate,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          border: const Border(
            bottom: BorderSide(
              color: CupertinoColors.separator,
            ),
          ),
          color: subscription.isPaused
              ? (isDarkMode
                  ? Colors.grey.withOpacity(0.5)
                  : CupertinoColors.systemGrey5)
              : (isDarkMode ? CupertinoColors.darkBackgroundGray : null),
        ),
        child: Row(
          children: [
            subscription.buildImage(),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AutoText(
                            text: subscription.title,
                            maxLines: 3,
                            softWrap: true,
                            color: isDarkMode
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                            bold: true),
                      ),
                      if (subscription.isPinned)
                        const Icon(
                          CupertinoIcons.pin_fill,
                          color: CupertinoColors.systemGrey,
                        ),
                    ],
                  ),
                  AutoText(
                      text:
                          '${subscription.amount.toStringAsFixed(2)} ${currency.symbol}',
                      maxLines: 1,
                      color: isDarkMode
                          ? CupertinoColors.systemGrey2
                          : CupertinoColors.systemGrey),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            Row(
              children: [
                Column(
                  children: [
                    AutoText(
                        text:
                            '${subscription.remainingDays()} ${Intl.message('D')}',
                        color: isDarkMode
                            ? CupertinoColors.systemGrey2
                            : CupertinoColors.systemGrey),
                    AutoText(
                        text: '(${_convertPrice(subscription)})',
                        color: isDarkMode
                            ? CupertinoColors.systemGrey2
                            : CupertinoColors.systemGrey),
                  ],
                ),
                CupertinoButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => SubscriptionShowView(
                          subscription: subscription,
                          onUpdate: onUpdate,
                          onDelete: onDelete,
                        ),
                      ),
                    ).then((_) => onUpdate(subscription));
                  },
                  child: Icon(
                    CupertinoIcons.right_chevron,
                    color: isDarkMode
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey,
                  ),
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
            builder: (context) => SubscriptionShowView(
              subscription: subscription,
              onUpdate: onUpdate,
              onDelete: onDelete,
            ),
          ),
        ).then((_) => onUpdate(subscription));
      },
    );
  }

  String? _convertPrice(Subscription subscription) {
    String priceString = subscription.convertPrice()?.toStringAsFixed(2) ??
        Intl.message('unknown');
    return subscription.repeatPattern == PaymentRate.monthly.value
        ? '$priceString ${currency.symbol}/${Intl.message('Y')}'
        : '$priceString ${currency.symbol}/${Intl.message('M')}';
  }
}
