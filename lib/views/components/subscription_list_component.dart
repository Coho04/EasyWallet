import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/views/subscription/show.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SubscriptionListComponent extends StatelessWidget {
  final Subscription subscription;
  final Function(Subscription) onUpdate;
  final Function(Subscription) onDelete;

  const SubscriptionListComponent(
      {super.key,
      required this.subscription,
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
                     Expanded(child:  Text(
                       subscription.title,
                       style: EasyWalletApp.responsiveTextStyle(15, context,
                           color: isDarkMode
                               ? CupertinoColors.white
                               : CupertinoColors.black,
                           bold: true),
                     )),
                      if (subscription.isPinned)
                        const Icon(
                          CupertinoIcons.pin_fill,
                          color: CupertinoColors.systemGrey,
                        ),
                    ],
                  ),
                  Text(
                    '${subscription.amount.toStringAsFixed(2)} €',
                    style: EasyWalletApp.responsiveTextStyle(16, context,
                        color: isDarkMode
                            ? CupertinoColors.systemGrey2
                            : CupertinoColors.systemGrey),
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
                      '${subscription.remainingDays()} ${Intl.message('days')}',
                      style: EasyWalletApp.responsiveTextStyle(15, context,
                          color: isDarkMode
                              ? CupertinoColors.systemGrey2
                              : CupertinoColors.systemGrey),
                    ),
                    Text(
                      '(${_convertPrice(subscription)})',
                      style: EasyWalletApp.responsiveTextStyle(15, context,
                          color: isDarkMode
                              ? CupertinoColors.systemGrey2
                              : CupertinoColors.systemGrey),
                    )
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
        ? '$priceString €/${Intl.message('year')}'
        : '$priceString €/${Intl.message('month')}';
  }
}
