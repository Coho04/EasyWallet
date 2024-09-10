import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:easy_wallet/views/components/card_section_component.dart';
import 'package:easy_wallet/views/subscription/edit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:provider/provider.dart';
import 'package:easy_wallet/model/category.dart' as category;

class SubscriptionShowView extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionShowView({
    super.key,
    required this.subscription,
  });

  @override
  SubscriptionShowViewState createState() => SubscriptionShowViewState();
}

class SubscriptionShowViewState extends State<SubscriptionShowView> {
  late Subscription subscription;
  List<category.Category>? categories;

  @override
  void initState() {
    super.initState();
    subscription = widget.subscription;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencyProvider>(
        builder: (context, currencyProvider, child) {
      final currency = currencyProvider.currency;
      return Consumer<SubscriptionProvider>(
          builder: (context, subscriptionProvider, child) {
        return CupertinoPageScaffold(
          backgroundColor:
              CupertinoColors.systemGroupedBackground.resolveFrom(context),
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              Intl.message('subscriptions'),
              style: EasyWalletApp.responsiveTextStyle(context),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                openEditView(context);
              },
              child: const Icon(CupertinoIcons.pencil),
            ),
          ),
          child: SafeArea(
            minimum: const EdgeInsets.only(bottom: 20),
            top: true,
            bottom: true,
            child: ListView(
              padding:
                  const EdgeInsets.only(right: 16.0, left: 16.0, bottom: 20),
              children: <Widget>[
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 5),
                buildCategories(),
                const SizedBox(height: 20),
                CardSection(
                  title: Intl.message('generalInformation'),
                  children: [
                    CardDetailRow(
                      label: Intl.message('costs'),
                      value:
                          '${subscription.amount.toStringAsFixed(2)} ${currency.symbol}',
                    ),
                    CardDetailRow(
                      label: Intl.message('repetitionRate'),
                      value: subscription.getRepeatPattern().translate(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CardSection(
                  title: Intl.message('invoiceInformation'),
                  children: [
                    CardDetailRow(
                      label: Intl.message('nextInvoice'),
                      value: _formatDateTime(subscription.getNextBillDate()),
                    ),
                    CardDetailRow(
                      label: Intl.message('previousInvoice'),
                      value: _formatDateTime(
                          subscription.calculatePreviousBillDate()),
                    ),
                    CardDetailRow(
                      label: Intl.message('firstDebit'),
                      value: _formatDateTime(subscription.date),
                    ),
                    CardDetailRow(
                      label: Intl.message('createdOn'),
                      maxLines: 1,
                      value: _formatDateTime(subscription.timestamp,
                          withTime: true),
                      softBreak: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CardSection(
                  title: Intl.message('additionalInformation'),
                  children: [
                    CardDetailRow(
                      label: Intl.message('previousDebits'),
                      value: subscription.countPayment().toString(),
                    ),
                    CardDetailRow(
                      label: Intl.message('convertedCosts'),
                      value:
                          '(${widget.subscription.displayConvertedPrice(currency)})',
                    ),
                    CardDetailRow(
                      label: Intl.message('totalCosts'),
                      value:
                          '${subscription.sumPayment().toStringAsFixed(2)} ${currency.symbol}',
                    ),
                    if (subscription.notes != null &&
                        subscription.notes!.trim().isNotEmpty)
                      CardDetailRow(
                        label: Intl.message('notes'),
                        value: subscription.notes!,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                CardSection(
                  title: Intl.message('actions'),
                  children: [
                    CardActionButton(
                      label: subscription.isPinned
                          ? Intl.message('unpinSubscription')
                          : Intl.message('pinSubscription'),
                      icon: subscription.isPinned
                          ? CupertinoIcons.pin_slash
                          : CupertinoIcons.pin,
                      onPressed: () => _toggleStates(),
                      color: subscription.isPinned
                          ? CupertinoColors.systemBlue
                          : null,
                    ),
                    CardActionButton(
                      label: subscription.isPaused
                          ? Intl.message('continueSubscription')
                          : Intl.message('pauseSubscription'),
                      icon: subscription.isPaused
                          ? CupertinoIcons.play_arrow_solid
                          : CupertinoIcons.pause,
                      onPressed: () => _toggleStates(pause: true),
                    ),
                    CardActionButton(
                      label: Intl.message('deleteSubscription'),
                      icon: CupertinoIcons.delete,
                      onPressed: () => _deleteItem(),
                      color: CupertinoColors.destructiveRed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      });
    });
  }

  Widget _buildHeader() {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Row(
      children: [
        subscription.buildImage(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            subscription.title,
            style: EasyWalletApp.responsiveTextStyle(
              context,
              bold: true,
              color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
        ),
      ],
    );
  }

  void _toggleStates({bool pause = false}) {
    setState(() {
      if (pause) {
        subscription.isPaused = !subscription.isPaused;
      } else {
        subscription.isPinned = !subscription.isPinned;
      }
    });
    Provider.of<SubscriptionProvider>(context, listen: false)
        .saveSubscription(subscription);
  }

  Future<void> _deleteItem() async {
    if (kIsWeb) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(Intl.message('hint'),
              style: EasyWalletApp.responsiveTextStyle(context)),
          content: Text(Intl.message('deletionIsNotSupportedOnTheWeb'),
              style: EasyWalletApp.responsiveTextStyle(context)),
          actions: [
            CupertinoDialogAction(
              child:
                  Text('OK', style: EasyWalletApp.responsiveTextStyle(context)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } else {
      Provider.of<SubscriptionProvider>(context, listen: false)
          .deleteSubscription(subscription);
      Navigator.of(context).pop();
    }
  }

  String _formatDateTime(DateTime? dateTime, {bool withTime = false}) {
    if (dateTime == null) return Intl.message('unknown');
    if (!withTime) return DateFormat.yMMMd().format(dateTime);
    String time = DateFormat.Hm().format(dateTime);
    String date = DateFormat.yMMMd().format(dateTime);
    int maxLength = 18;
    String paddedTime = time.padLeft(maxLength);
    return '$paddedTime\n$date';
  }

  void openEditView(context) async {
    var selectedCategories = await subscription.categories;
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => SubscriptionEditView(
          selectedCategories: selectedCategories,
          subscription: subscription,
        ),
      ),
    );
  }

  Widget buildCategories() {
    final bgColor = CupertinoTheme.of(context).barBackgroundColor;
    if (categories == null || categories!.isEmpty) return const SizedBox();
    return Material(
      color: bgColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          spacing: 4.0,
          children: categories!
              .map((category) => Chip(
                    label: Text(
                      category.title,
                      style: const TextStyle(
                          color: CupertinoColors.white, fontSize: 11),
                    ),
                    padding: const EdgeInsets.all(0),
                    backgroundColor: category.color,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
