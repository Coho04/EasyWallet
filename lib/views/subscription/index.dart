import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/sort_option.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/provider/category_provider.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:easy_wallet/views/components/subscription_list_component.dart';
import 'package:easy_wallet/views/subscription/create.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../persistence_controller.dart';

class SubscriptionIndexView extends StatefulWidget {
  const SubscriptionIndexView({super.key});

  @override
  SubscriptionIndexViewState createState() => SubscriptionIndexViewState();
}

class SubscriptionIndexViewState extends State<SubscriptionIndexView> {
  String searchText = "";
  SortOption sortOption = SortOption.remainingDaysAscending;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndSortSubscriptions(context);
  }

  Future<void> _loadAndSortSubscriptions(context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('syncWithGoogleDrive') ?? false) {
      var cloud = await PersistenceController.instance.googleDrive;
      await cloud.syncFrom();
    }
    try {
      await Provider.of<SubscriptionProvider>(context, listen: false)
          .loadSubscriptions();
      await Provider.of<CurrencyProvider>(context, listen: false)
          .loadCurrency();
      await Provider.of<CategoryProvider>(context, listen: false)
          .loadCategories();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Subscription> _sortSubscriptions(List<Subscription> subscriptions) {
    List<Subscription> filteredSubscriptions =
        subscriptions.where((subscription) {
      return subscription.title
          .toLowerCase()
          .contains(searchText.toLowerCase());
    }).toList();

    filteredSubscriptions.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      if (a.isPaused && !b.isPaused) return 1;
      if (!a.isPaused && b.isPaused) return -1;

      switch (sortOption) {
        case SortOption.alphabeticalAscending:
          return a.title.compareTo(b.title);
        case SortOption.alphabeticalDescending:
          return b.title.compareTo(a.title);
        case SortOption.costAscending:
          return a.amount.compareTo(b.amount);
        case SortOption.costDescending:
          return b.amount.compareTo(a.amount);
        case SortOption.remainingDaysAscending:
          return a.remainingDays().compareTo(b.remainingDays());
        case SortOption.remainingDaysDescending:
          return b.remainingDays().compareTo(a.remainingDays());
        default:
          return 0;
      }
    });

    return filteredSubscriptions;
  }

  double calculateYearlySpent(List<Subscription> subscriptions) {
    final now = DateTime.now();
    final lastDayOfYear = DateTime(now.year, 12, 31);
    double yearlySpent = 0.0;

    for (var subscription in subscriptions) {
      if (subscription.isPaused) continue;
      DateTime nextBillDate = subscription.getNextBillDate();
      if (subscription.repeatPattern == PaymentRate.yearly.value) {
        if (nextBillDate.isBefore(lastDayOfYear.add(const Duration(days: 1))) &&
            nextBillDate.year == now.year) {
          yearlySpent += subscription.amount;
        }
      } else if (subscription.repeatPattern == PaymentRate.monthly.value) {
        while (
            nextBillDate.isBefore(lastDayOfYear.add(const Duration(days: 1)))) {
          yearlySpent += subscription.amount;
          nextBillDate = DateTime(
              nextBillDate.year, nextBillDate.month + 1, nextBillDate.day);
        }
      }
    }
    return yearlySpent;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        final subscriptions = subscriptionProvider.subscriptions;
        final sortedSubscriptions = _sortSubscriptions(subscriptions);
        double monthlySpent = sortedSubscriptions.where((subscription) {
          if (subscription.isPaused) return false;
          final now = DateTime.now();
          DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
          DateTime nextBillDate = subscription.getNextBillDate();
          return nextBillDate.isBefore(lastDayOfMonth) &&
              nextBillDate.month == now.month;
        }).fold(0, (sum, subscription) => sum + subscription.amount);

        return Consumer<CurrencyProvider>(
            builder: (context, currencyProvider, child) {
          final currency = currencyProvider.currency;
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Column(
                children: [
                  SizedBox(
                    height: 36,
                    child: CupertinoSearchTextField(
                      placeholder: Intl.message('search'),
                      onChanged: (value) {
                        setState(() {
                          searchText = value;
                          _sortSubscriptions(subscriptions);
                        });
                      },
                    ),
                  ),
                ],
              ),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showSortOptions(context),
                child: const Icon(CupertinoIcons.arrow_up_arrow_down,
                    color: CupertinoColors.activeBlue),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const SubscriptionCreateView(),
                    ),
                  ).then((value) {
                    _loadAndSortSubscriptions(context);
                  });
                },
                child: const Icon(CupertinoIcons.add,
                    color: CupertinoColors.activeBlue),
              ),
            ),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 100,
                  child: Center(
                    child: AutoText(
                      text: Intl.message('subscriptions'),
                      bold: true,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoText(
                              text: Intl.message('outstandingExpenditureMonth'),
                              color: CupertinoColors.systemGrey,
                              maxLines: 2,
                            ),
                            AutoText(
                              text:
                                  '${monthlySpent.toStringAsFixed(2)} ${currency.symbol}',
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AutoText(
                              text: Intl.message('openExpenditureYear'),
                              color: CupertinoColors.systemGrey,
                              maxLines: 2,
                            ),
                            AutoText(
                                text:
                                    '${calculateYearlySpent(sortedSubscriptions).toStringAsFixed(2)} ${currency.symbol}',
                                bold: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : sortedSubscriptions.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 85.0),
                              itemCount: sortedSubscriptions.length,
                              itemBuilder: (context, index) {
                                return SubscriptionListComponent(
                                  currency: currency,
                                  subscription: sortedSubscriptions[index],
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AutoText(
            text: Intl.message('noSubscriptionsAvailable'),
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const SubscriptionCreateView(),
                ),
              ).then((value) {
                _loadAndSortSubscriptions(context);
              });
            },
            child: AutoText(
              text: Intl.message('addNewSubscription'),
              bold: true,
              color: CupertinoColors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          Intl.message('sortOptions'),
          style: EasyWalletApp.responsiveTextStyle(context,
              color: CupertinoColors.systemGrey),
        ),
        actions: <Widget>[
          for (SortOption option in SortOption.values)
            CupertinoActionSheetAction(
              child: Text(
                option.translate(),
                style: EasyWalletApp.responsiveTextStyle(context,
                    color: CupertinoColors.activeBlue),
              ),
              onPressed: () {
                setState(() {
                  sortOption = option;
                  _sortSubscriptions(
                      Provider.of<SubscriptionProvider>(context, listen: false)
                          .subscriptions);
                });
                Navigator.pop(context);
              },
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(Intl.message('cancel'),
              style: EasyWalletApp.responsiveTextStyle(context,
                  color: CupertinoColors.systemGrey)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
