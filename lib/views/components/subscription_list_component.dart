import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/model/category.dart';
import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:easy_wallet/views/subscription/show.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionListComponent extends StatefulWidget {
  final Subscription subscription;
  final Currency currency;

  const SubscriptionListComponent(
      {super.key, required this.subscription, required this.currency});

  @override
  SubscriptionListComponentState createState() =>
      SubscriptionListComponentState();
}

class SubscriptionListComponentState extends State<SubscriptionListComponent> {
  bool? displayCategories;
  List<Category>? categories;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    displayCategories = prefs.getBool('displayCategories') ?? true;

    if (displayCategories!) {
      bool hasCategories = await widget.subscription.hasCategories();
      if (hasCategories) {
        categories = await widget.subscription.categories;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery
            .of(context)
            .platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) =>
                SubscriptionShowView(
                  subscription: widget.subscription,
                ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
            border: const Border(
              bottom: BorderSide(color: CupertinoColors.separator),
            ),
            color: widget.subscription.isPaused
                ? (isDarkMode
                ? Colors.grey.withOpacity(0.5)
                : CupertinoColors.systemGrey5)
                : (CupertinoTheme
                .of(context)
                .barBackgroundColor)),
        child: Column(
          children: [
            Row(
              children: [
                widget.subscription.buildImage(),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AutoText(
                              text: widget.subscription.title,
                              maxLines: 3,
                              softWrap: true,
                              color: isDarkMode
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                              bold: true,
                            ),
                          ),
                          if (widget.subscription.isPinned)
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
                        '${widget.subscription.remainingDays()} ${Intl.message(
                            'D')}',
                        color: isDarkMode
                            ? CupertinoColors.systemGrey2
                            : CupertinoColors.systemGrey,
                      ),
                      AutoText(
                        text: widget.subscription
                            .displayConvertedPrice(widget.currency),
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
                        builder: (context) =>
                            SubscriptionShowView(
                                subscription: widget.subscription
                            ),
                      ),
                    );
                  },
                  child: const Icon(
                    CupertinoIcons.right_chevron,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
            displayCategories ?? false ? buildCategories() : const SizedBox()
          ],
        ),
      ),
    );
  }

  Widget buildCategories() {
    if (categories == null) return const SizedBox();
    return Material(
      color: CupertinoTheme
          .of(context)
          .barBackgroundColor,
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
              spacing: 8.0,
              children: categories!
                  .map((category) =>
                  Chip(
                      label: Text(category.title,
                          style: const TextStyle(
                              color: CupertinoColors.white, fontSize: 12)),
                      padding: const EdgeInsets.all(2),
                backgroundColor: category.color,
              ))
              .toList(),
        ),
      ),
    ),);
  }
}
