import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/model/category.dart';
import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:easy_wallet/views/subscription/show.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionListComponent extends StatelessWidget {
  final Subscription subscription;
  final Currency currency;
  final Function(Subscription) onUpdate;
  final Function(Subscription) onDelete;

  const SubscriptionListComponent({
    super.key,
    required this.subscription,
    required this.currency,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
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
              : (CupertinoTheme.of(context).barBackgroundColor),
        ),
        child: Column(
          children: [
            Row(
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
                              bold: true,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AutoText(
                        text:
                            '${subscription.remainingDays()} ${Intl.message('D')}',
                        color: isDarkMode
                            ? CupertinoColors.systemGrey2
                            : CupertinoColors.systemGrey,
                      ),
                      AutoText(
                        text: _convertPrice(subscription),
                        color: isDarkMode
                            ? CupertinoColors.systemGrey2
                            : CupertinoColors.systemGrey,
                      ),
                    ],
                  ),
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
                  child: const Icon(
                    CupertinoIcons.right_chevron,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
            FutureBuilder<Widget?>(
              future: buildCategories(subscription, context),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return const Center(child: CircularProgressIndicator());
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (snapshot.hasData) {
                      return snapshot.data ?? const SizedBox();
                    }
                    return const SizedBox();
                  default:
                    return const SizedBox();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _convertPrice(Subscription subscription) {
    String priceString = subscription.amount.toStringAsFixed(2);
    return subscription.repeatPattern == PaymentRate.yearly.value
        ? '$priceString ${currency.symbol}/${Intl.message('Y')}'
        : '$priceString ${currency.symbol}/${Intl.message('M')}';
  }

  Future<Widget?> buildCategories(Subscription subscription, context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('displayCategories') == false) {
      return null;
    }

    bool has = await subscription.hasCategories();
    if (!has) return null;

    List<Category> categories = await subscription.categories;
    return Material(
      color: CupertinoTheme.of(context).barBackgroundColor,
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8.0,
            children: categories
                .map((category) => Chip(
                      label: Text(category.title,
                          style: const TextStyle(color: CupertinoColors.white, fontSize: 12)),
                      padding: const EdgeInsets.all(2),
                      backgroundColor: category.color,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
