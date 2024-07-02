import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/model/subscription_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_wallet/persistence_controller.dart';
import 'package:easy_wallet/subscription_views/subscription_create_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String searchText = "";

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
        final loadedSubscriptions =
        await persistenceController.getAllSubscriptions();
        setState(() {
          subscriptions = loadedSubscriptions;
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
        });
      }
    } catch (error) {
      if (kDebugMode) {
        print("Failed to load subscriptions: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredSubscriptions = subscriptions.where((subscription) {
      return subscription.title!
          .toLowerCase()
          .contains(searchText.toLowerCase());
    }).toList();

    double totalAmount = subscriptions.fold(0, (sum, subscription) => sum + subscription.amount);

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
                  });
                },
              ),
            ),
          ],
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            // Handle sorting logic
          },
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
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: filteredSubscriptions.length,
              itemBuilder: (context, index) {
                return SubscriptionItem(
                  subscription: filteredSubscriptions[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
