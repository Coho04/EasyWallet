import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/sort_option.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/model/subscription_item.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:easy_wallet/subscription_views/subscription_create_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  String searchText = "";
  SortOption sortOption = SortOption.remainingDaysAscending;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    await Provider.of<SubscriptionProvider>(context, listen: false).loadSubscriptions();
  }

  List<Subscription> _sortSubscriptions(List<Subscription> subscriptions) {
    List<Subscription> filteredSubscriptions = subscriptions.where((subscription) {
      return subscription.title.toLowerCase().contains(searchText.toLowerCase());
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
          return _remainingDays(a).compareTo(_remainingDays(b));
        case SortOption.remainingDaysDescending:
          return _remainingDays(b).compareTo(_remainingDays(a));
        default:
          return 0;
      }
    });
    return filteredSubscriptions;
  }

  int _remainingDays(Subscription subscription) {
    if (subscription.date == null) return 0;
    DateTime nextBillDate = subscription.date!;
    DateTime today = DateTime.now();
    Duration interval = subscription.repeatPattern == PaymentRate.yearly.value
        ? const Duration(days: 365)
        : const Duration(days: 30);
    while (nextBillDate.isBefore(today)) {
      nextBillDate = nextBillDate.add(interval);
    }
    return nextBillDate.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final subscriptions = Provider.of<SubscriptionProvider>(context).subscriptions;
    double monthlySpent = subscriptions.where((subscription) {
      final now = DateTime.now();
      return subscription.date != null &&
          subscription.date!.year == now.year &&
          subscription.date!.month == now.month;
    }).fold(0, (sum, subscription) => sum + subscription.amount);

    double yearlySpent = subscriptions.where((subscription) {
      final now = DateTime.now();
      return subscription.date != null && subscription.date!.year == now.year;
    }).fold(0, (sum, subscription) => sum + subscription.amount);

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
              _loadSubscriptions();
            });
          },
          child:
          const Icon(CupertinoIcons.add, color: CupertinoColors.activeBlue),
        ),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 100,
            child: Center(
              child: Text(
                Intl.message('subscriptions'),
                style:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Intl.message('expenditureMonth'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    Text(
                      '${monthlySpent.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Intl.message('expenditureYear'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    Text(
                      '${yearlySpent.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: subscriptions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 85.0),
              itemCount: subscriptions.length,
              itemBuilder: (context, index) {
                return SubscriptionItem(
                  subscription: subscriptions[index],
                  onUpdate: (updatedSubscription) {
                    Provider.of<SubscriptionProvider>(context, listen: false)
                        .updateSubscription(updatedSubscription);
                  },
                  onDelete: (deletedSubscription) {
                    Provider.of<SubscriptionProvider>(context, listen: false)
                        .deleteSubscription(deletedSubscription);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Intl.message('noSubscriptionsAvailable'),
            style: const TextStyle(
                fontSize: 18, color: CupertinoColors.systemGrey),
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
                _loadSubscriptions();
              });
            },
            child: Text(Intl.message('addNewSubscription')),
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(Intl.message('sortOptions')),
        actions: <Widget>[
          for (SortOption option in SortOption.values)
            CupertinoActionSheetAction(
              child: Text(option.translate()),
              onPressed: () {
                setState(() {
                  sortOption = option;
                });
                Navigator.pop(context);
              },
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(Intl.message('cancel')),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
