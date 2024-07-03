import 'package:easy_wallet/enum/sort_option.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/model/subscription_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_wallet/persistence_controller.dart';
import 'package:easy_wallet/subscription_views/subscription_create_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  String searchText = "";
  SortOption sortOption = SortOption.remainingDaysAscending;

  List<Subscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    try {
      if (!kIsWeb) {
        final persistenceController = PersistenceController.instance;
        final loadedSubscriptions = await persistenceController.getAllSubscriptions();
        setState(() {
          subscriptions = _sortSubscriptions(loadedSubscriptions);
        });
      } else {
        setState(() {
          subscriptions = [
            Subscription(
              id: 1,
              amount: 10.0,
              date: DateTime.now().subtract(const Duration(days: 10)),
              isPaused: false,
              isPinned: true,
              repeating: true,
              repeatPattern: 'monthly',
              title: 'Netflix',
              url: 'https://www.netflix.com',
            ),
          ];
          subscriptions = _sortSubscriptions(subscriptions);
        });
      }
    } catch (error) {
      if (kDebugMode) {
        print("Failed to load subscriptions: $error");
      }
    }
  }

  void _updateSubscription(Subscription updatedSubscription) {
    setState(() {
      int index = subscriptions.indexWhere((sub) => sub.id == updatedSubscription.id);
      if (index != -1) {
        subscriptions[index] = updatedSubscription;
      }
      subscriptions = _sortSubscriptions(subscriptions);
    });
  }

  void _updateAllSubscription(Subscription subscription) {
    _loadSubscriptions();
  }

  List<Subscription> _sortSubscriptions(List<Subscription> subscriptions) {
    List<Subscription> filteredSubscriptions = subscriptions.where((subscription) {
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
    Duration interval = subscription.repeatPattern == 'yearly'
        ? const Duration(days: 365)
        : const Duration(days: 30);
    while (nextBillDate.isBefore(today)) {
      nextBillDate = nextBillDate.add(interval);
    }
    return nextBillDate.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
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
                placeholder: 'Suchen',
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                    subscriptions = _sortSubscriptions(subscriptions);
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
          const SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'Abonnements',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ausgaben diesen Monat',
                      style: TextStyle(
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
                    const Text(
                      'Ausgaben dieses Jahr',
                      style: TextStyle(
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
                  onUpdate: _updateSubscription,
                  onDelete: _updateAllSubscription,
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
          const Text(
            'Keine Abonnements vorhanden',
            style: TextStyle(fontSize: 18, color: CupertinoColors.systemGrey),
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
            child: const Text('Neues Abonnement hinzufügen'),
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Sortieroptionen'),
        actions: <Widget>[
          CupertinoActionSheetAction(
            child: const Text('Alphabetisch aufsteigend'),
            onPressed: () {
              setState(() {
                sortOption = SortOption.alphabeticalAscending;
                subscriptions = _sortSubscriptions(subscriptions);
              });
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Alphabetisch absteigend'),
            onPressed: () {
              setState(() {
                sortOption = SortOption.alphabeticalDescending;
                subscriptions = _sortSubscriptions(subscriptions);
              });
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Kosten aufsteigend'),
            onPressed: () {
              setState(() {
                sortOption = SortOption.costAscending;
                subscriptions = _sortSubscriptions(subscriptions);
              });
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Kosten absteigend'),
            onPressed: () {
              setState(() {
                sortOption = SortOption.costDescending;
                subscriptions = _sortSubscriptions(subscriptions);
              });
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Tage aufsteigend'),
            onPressed: () {
              setState(() {
                sortOption = SortOption.remainingDaysAscending;
                subscriptions = _sortSubscriptions(subscriptions);
              });
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Tage absteigend'),
            onPressed: () {
              setState(() {
                sortOption = SortOption.remainingDaysDescending;
                subscriptions = _sortSubscriptions(subscriptions);
              });
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Abbrechen'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
