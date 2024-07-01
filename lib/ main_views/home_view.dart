import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/model/subscription_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_wallet/persistence_controller.dart';
import 'package:easy_wallet/subscription_views/subscription_create_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  double monthlyLimit = 0.0;
  bool isAnnual = false;
  String searchText = "";
  SortOption sortOption = SortOption.remainingDaysAscending;
  String paymentRate = "Monatlich";

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
        // Handle web version
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
            // Add more subscriptions as needed
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
      return subscription.title.toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    double totalAmount =
    subscriptions.fold(0, (sum, subscription) => sum + subscription.amount);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            // Handle sorting logic
          },
          icon: const Icon(Icons.sort),
        ),
        title: const Text('Abonnements'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SubscriptionCreateView()),
              ).then((value) {
                _loadSubscriptions();
              });
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Suchen',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bezahlungsrate',
                ),
                DropdownButton<String>(
                  value: paymentRate,
                  items: ['Monatlich', 'Jährlich']
                      .map((rate) => DropdownMenuItem<String>(
                    value: rate,
                    child: Text(rate),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      paymentRate = value!;
                    });
                  },
                ),
                Text(
                  '${totalAmount.toStringAsFixed(2)} €',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredSubscriptions.length,
              itemBuilder: (context, index) {
                return SubscriptionItem(
                  subscription: filteredSubscriptions[index],
                  isAnnual: isAnnual,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum SortOption {
  alphabeticalAscending,
  alphabeticalDescending,
  costAscending,
  costDescending,
  remainingDaysAscending,
  remainingDaysDescending,
}
