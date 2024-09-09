import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
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
  final ValueChanged<Subscription> onUpdate;
  final ValueChanged<Subscription> onDelete;

  const SubscriptionShowView(
      {super.key,
      required this.subscription,
      required this.onUpdate,
      required this.onDelete});

  @override
  SubscriptionShowViewState createState() => SubscriptionShowViewState();
}

class SubscriptionShowViewState extends State<SubscriptionShowView> {
  late Subscription subscription;

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
                openEditView();
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
                FutureBuilder<Widget?>(
                  future: buildCategories(
                      subscription,
                      CupertinoColors.systemGroupedBackground
                          .resolveFrom(context)),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return const Center(child: CircularProgressIndicator());
                      case ConnectionState.done:
                        if (snapshot.hasError) {
                          return Center(
                              child: Text("Error: ${snapshot.error}"));
                        }
                        return snapshot.data ?? const SizedBox();
                      default:
                        return const SizedBox();
                    }
                  },
                ),
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
                      value: '(${_convertPrice(currency)})',
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
                      onPressed: () => _togglePin(),
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
                      onPressed: () => _togglePause(),
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

  void _togglePin() {
    setState(() {
      subscription.isPinned = !subscription.isPinned;
    });
    _saveItem();
  }

  void _togglePause() {
    setState(() {
      subscription.isPaused = !subscription.isPaused;
    });
    _saveItem();
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
      widget.onDelete(subscription);
      Navigator.of(context).pop();
    }
  }

  void _saveItem() async {
    Provider.of<SubscriptionProvider>(context, listen: false)
        .saveSubscription(subscription);
    widget.onUpdate(subscription);
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

  void openEditView() async {
    var selectedCategories = await subscription.categories;
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => SubscriptionEditView(
          selectedCategories: selectedCategories,
          subscription: subscription,
          onUpdate: (updatedSubscription) {
            setState(() {
              subscription = updatedSubscription;
            });
            widget.onUpdate(updatedSubscription);
          },
        ),
      ),
    );
  }

  Future<Widget?> buildCategories(
      Subscription subscription, Color bgColor) async {
    bool has = await subscription.hasCategories();
    if (has) {
      List<category.Category> categories = await subscription.categories;
      return Material(
        color: bgColor,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 4.0,
            children: categories
                .map((category) => Chip(
                      label: Text(
                        category.title,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 11,
                        ),
                      ),
                      padding: const EdgeInsets.all(0),
                      backgroundColor: category.color,
                    ))
                .toList(),
          ),
        ),
      );
    } else {
      return null;
    }
  }

  String? _convertPrice(Currency currency) {
    String priceString = subscription.convertPrice()?.toStringAsFixed(2) ??
        Intl.message('unknown');
    return subscription.repeatPattern == PaymentRate.monthly.value
        ? '$priceString ${currency.symbol}/${Intl.message('year')}'
        : '$priceString ${currency.symbol}/${Intl.message('month')}';
  }
}
